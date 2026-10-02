import {FieldValue} from "firebase-admin/firestore";
import type {DocumentReference, QuerySnapshot, Transaction} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {db} from "./firebaseAdmin";
import {
  AnelPublico,
  Coisa,
  REGIOES_VALIDAS,
  Regra,
  avaliaRegra,
  escolherPistasIniciais,
  regiaoDe,
} from "./aneisAvaliador";

const region = "southamerica-east1";
const MIN_JOGADORES = 2;
const MAX_JOGADORES = 6;
const CARTAS_POR_MAO = 5;
const PISTAS_INICIAIS = 3;
const CARTAS_SETUP_KNOWER = 5;
const DIFICULDADES = new Set(["facil", "medio", "dificil"]);
const KNOWER_MODES = new Set(["jogador", "app"]);

type Banco = {
  aneis: AnelPublico[];
  regras: Regra[];
  coisas: Coisa[];
};

type PlayerSeat = {uid: string; seat: number};

type CartaPublica = {id: string; texto: string};

type CartaTabuleiro = {coisaId: string; texto: string; regiao: string};

let bancoCache: Banco | undefined;

function carregarBanco(): Banco {
  if (!bancoCache) {
    bancoCache = require("./data/aneis_banco.json") as Banco;
  }
  return bancoCache;
}

function requireUid(uid: string | undefined): string {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Faça login para continuar");
  }
  return uid;
}

function normalizeDisplayName(value: unknown): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Nome inválido");
  }
  const name = value.trim();
  if (name.length < 1 || name.length > 24) {
    throw new HttpsError("invalid-argument", "Nome deve ter 1 a 24 caracteres");
  }
  return name;
}

function normalizeCode(value: unknown): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Código inválido");
  }
  const code = value.trim().toUpperCase();
  if (!/^[A-Z0-9]{4,6}$/.test(code)) {
    throw new HttpsError("invalid-argument", "Código inválido");
  }
  return code;
}

function requireRoomId(value: unknown): string {
  if (typeof value !== "string" || value.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }
  return value.trim();
}

function createRoomCode(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 4; i++) {
    code += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return code;
}

function shuffle<T>(items: T[]): T[] {
  const list = [...items];
  for (let i = list.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [list[j], list[i]] = [list[i], list[j]];
  }
  return list;
}

function orderedSeats(players: QuerySnapshot): PlayerSeat[] {
  return players.docs
    .map((doc) => ({uid: doc.id, seat: doc.get("seat") as number | null}))
    .filter((player): player is PlayerSeat => typeof player.seat === "number")
    .sort((a, b) => a.seat - b.seat);
}

function finderSeats(players: PlayerSeat[], knowerUid: string | null): PlayerSeat[] {
  if (!knowerUid) return players;
  return players.filter((player) => player.uid !== knowerUid);
}

function nextFinderUid(
  players: PlayerSeat[],
  currentUid: string,
  knowerUid: string | null,
): string {
  const finders = finderSeats(players, knowerUid);
  if (finders.length === 0) {
    throw new HttpsError("failed-precondition", "Não há Finders na partida");
  }
  const currentIndex = finders.findIndex((player) => player.uid === currentUid);
  if (currentIndex < 0) return finders[0].uid;
  return finders[(currentIndex + 1) % finders.length].uid;
}

function assinaturaRegra(regra: Regra): string {
  const av = regra.avaliacao ?? {tipo: ""};
  const extras = [
    av.letra ?? "",
    av.valor ?? "",
    av.op ?? "",
    ...(av.qualquer ?? []),
    ...(av.todas ?? []),
    ...(av.nenhuma ?? []),
  ].map(String).join(",");
  return `${regra.anel}|${av.tipo}|${extras}`;
}

function tipoRegra(regra: Regra): string {
  return `${regra.anel}|${regra.avaliacao?.tipo ?? ""}`;
}

function escolherRegra(
  regras: Regra[],
  anel: Regra["anel"],
  dificuldade: string,
  excluidos: Set<string> = new Set(),
  excluidasAssinaturas: Set<string> = new Set(),
): Regra {
  const daDificuldade = regras.filter(
    (regra) => regra.anel === anel && regra.dificuldade === dificuldade,
  );
  const base = daDificuldade.length > 0 ?
    daDificuldade :
    regras.filter((regra) => regra.anel === anel);
  if (base.length === 0) {
    throw new HttpsError("internal", `Não há regras para o anel ${anel}`);
  }
  const frescas = base.filter((regra) => !excluidos.has(regra.id));
  const pool = frescas.length > 0 ? frescas : base;
  const semAssinatura = pool.filter((regra) => !excluidasAssinaturas.has(assinaturaRegra(regra)));
  const candidatos = semAssinatura.length > 0 ? semAssinatura : pool;
  const tiposUsados = new Set(
    [...excluidasAssinaturas].map((item) => item.split("|").slice(0, 2).join("|")),
  );
  const tipoNovo = candidatos.filter((regra) => !tiposUsados.has(tipoRegra(regra)));
  return shuffle(tipoNovo.length > 0 ? tipoNovo : candidatos)[0];
}

function bateAlgumaDica(coisa: Coisa, regras: Regra[]): boolean {
  return regras.some((regra) => avaliaRegra(coisa, regra));
}

function retirarCoisas(lista: Coisa[], n: number, excluidos: Set<string>): Coisa[] {
  if (n <= 0 || lista.length === 0) return [];
  const novas = shuffle(lista.filter((coisa) => !excluidos.has(coisa.id)));
  if (novas.length >= n) return novas.slice(0, n);
  const ja = new Set(novas.map((coisa) => coisa.id));
  const velhas = shuffle(lista.filter((coisa) => !ja.has(coisa.id)));
  return [...novas, ...velhas].slice(0, n);
}

function montarBaralhoPartida(
  coisas: Coisa[],
  regras: Regra[],
  excluidos: Set<string>,
  tamanho: number,
): Coisa[] {
  const alvo = Math.min(Math.max(tamanho, 1), coisas.length);
  const dentro: Coisa[] = [];
  const fora: Coisa[] = [];
  for (const coisa of coisas) {
    if (bateAlgumaDica(coisa, regras)) dentro.push(coisa);
    else fora.push(coisa);
  }

  const alvoFora = Math.min(fora.length, Math.max(1, Math.round(alvo * 0.1)));
  const alvoDentro = alvo - alvoFora;
  const escolhidasDentro = retirarCoisas(dentro, alvoDentro, excluidos);
  const idsDentro = new Set(escolhidasDentro.map((coisa) => coisa.id));
  const escolhidasFora = retirarCoisas(
    fora.filter((coisa) => !idsDentro.has(coisa.id)),
    alvoFora,
    excluidos,
  );
  const escolhidas = [...escolhidasDentro, ...escolhidasFora];
  if (escolhidas.length >= alvo) return shuffle(escolhidas.slice(0, alvo));

  const ids = new Set(escolhidas.map((coisa) => coisa.id));
  const resto = coisas.filter((coisa) => !ids.has(coisa.id));
  return shuffle([...escolhidas, ...retirarCoisas(resto, alvo - escolhidas.length, excluidos)]);
}

function cartaPublica(coisa: Coisa): CartaPublica {
  return {id: coisa.id, texto: coisa.texto};
}

function revelarRegras(regras: Regra[], aneis: AnelPublico[]) {
  return regras.map((regra) => {
    const anel = aneis.find((item) => item.id === regra.anel);
    return {
      anel: regra.anel,
      nome: anel?.nome ?? regra.anel,
      texto: regra.texto,
      cor: anel?.cor ?? "#64748B",
    };
  });
}

export const aneisCreateRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const displayName = normalizeDisplayName(req.data?.displayName);

  for (let attempt = 0; attempt < 8; attempt++) {
    const code = createRoomCode();
    const codeRef = db.doc(`aneisRoomCodes/${code}`);
    const roomRef = db.collection("aneisRooms").doc();
    const playerRef = roomRef.collection("players").doc(uid);

    try {
      await db.runTransaction(async (tx) => {
        const codeDoc = await tx.get(codeRef);
        if (codeDoc.exists) {
          throw new HttpsError("already-exists", "Código já existe");
        }

        tx.set(roomRef, {
          code,
          hostUid: uid,
          status: "lobby",
          playerCount: 1,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.set(playerRef, {
          displayName,
          seat: null,
          maoCount: 0,
          joinedAt: FieldValue.serverTimestamp(),
        });
        tx.set(codeRef, {
          roomId: roomRef.id,
          createdAt: FieldValue.serverTimestamp(),
        });
      });

      return {roomId: roomRef.id, code};
    } catch (error) {
      if (error instanceof HttpsError && error.code === "already-exists") {
        continue;
      }
      throw error;
    }
  }

  throw new HttpsError("resource-exhausted", "Não foi possível gerar código");
});

export const aneisJoinRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const displayName = normalizeDisplayName(req.data?.displayName);
  const code = normalizeCode(req.data?.code);

  let roomId = "";

  await db.runTransaction(async (tx) => {
    const codeDoc = await tx.get(db.doc(`aneisRoomCodes/${code}`));
    if (!codeDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }

    roomId = codeDoc.get("roomId") as string;
    const roomRef = db.doc(`aneisRooms/${roomId}`);
    const playerRef = db.doc(`aneisRooms/${roomId}/players/${uid}`);
    const roomDoc = await tx.get(roomRef);
    const playerDoc = await tx.get(playerRef);

    if (!roomDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }
    if (roomDoc.get("status") !== "lobby") {
      throw new HttpsError("failed-precondition", "Partida já iniciada");
    }
    if (!playerDoc.exists && (roomDoc.get("playerCount") as number) >= MAX_JOGADORES) {
      throw new HttpsError("failed-precondition", "Sala cheia");
    }

    tx.set(playerRef, {
      displayName,
      seat: null,
      maoCount: 0,
      joinedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    if (!playerDoc.exists) {
      tx.update(roomRef, {
        playerCount: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });

  return {roomId};
});

export const aneisLeaveRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = requireRoomId(req.data?.roomId);

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`aneisRooms/${roomId}`);
    const playerRef = db.doc(`aneisRooms/${roomId}/players/${uid}`);
    const playersRef = db.collection(`aneisRooms/${roomId}/players`);
    const roomDoc = await tx.get(roomRef);
    const playerDoc = await tx.get(playerRef);
    const playersSnap = await tx.get(playersRef);

    if (!roomDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }
    if (!playerDoc.exists) {
      throw new HttpsError("permission-denied", "Você não está na sala");
    }
    if (roomDoc.get("status") !== "lobby") {
      throw new HttpsError("failed-precondition", "Só é possível sair no lobby");
    }

    const remaining = playersSnap.docs.filter((doc) => doc.id !== uid);
    tx.delete(playerRef);

    if (remaining.length === 0) {
      tx.update(roomRef, {
        playerCount: 0,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const hostUid = roomDoc.get("hostUid") as string;
    tx.update(roomRef, {
      hostUid: hostUid === uid ? remaining[0].id : hostUid,
      playerCount: remaining.length,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const aneisRemovePlayer = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = requireRoomId(req.data?.roomId);
  const targetUid = req.data?.targetUid;
  if (typeof targetUid !== "string" || targetUid.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Jogador inválido");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`aneisRooms/${roomId}`);
    const playerRef = db.doc(`aneisRooms/${roomId}/players/${targetUid}`);
    const playersRef = db.collection(`aneisRooms/${roomId}/players`);
    const roomDoc = await tx.get(roomRef);
    const playerDoc = await tx.get(playerRef);
    const playersSnap = await tx.get(playersRef);

    if (!roomDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }
    if (roomDoc.get("hostUid") !== uid) {
      throw new HttpsError("permission-denied", "Só o host pode remover");
    }
    if (roomDoc.get("status") !== "lobby") {
      throw new HttpsError("failed-precondition", "Só é possível remover no lobby");
    }
    if (targetUid === uid) {
      throw new HttpsError("invalid-argument", "Host não pode remover a si mesmo");
    }
    if (!playerDoc.exists) {
      throw new HttpsError("not-found", "Jogador não encontrado");
    }

    tx.delete(playerRef);
    tx.update(roomRef, {
      playerCount: Math.max(0, playersSnap.size - 1),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const aneisStartGame = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = requireRoomId(req.data?.roomId);
  const dificuldadeRaw = req.data?.dificuldade;
  const dificuldade = typeof dificuldadeRaw === "string" && DIFICULDADES.has(dificuldadeRaw) ?
    dificuldadeRaw :
    "facil";
  const knowerMode = typeof req.data?.knowerMode === "string" && KNOWER_MODES.has(req.data.knowerMode) ?
    req.data.knowerMode as "jogador" | "app" :
    "jogador";
  const knowerUidPedido = typeof req.data?.knowerUid === "string" ? req.data.knowerUid.trim() : "";
  const banco = carregarBanco();
  const knowerHumano = knowerMode === "jogador";

  if (!Array.isArray(banco.coisas) || banco.coisas.length < CARTAS_POR_MAO + PISTAS_INICIAIS) {
    throw new HttpsError("internal", "Banco de cartas insuficiente");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`aneisRooms/${roomId}`);
    const playersRef = db.collection(`aneisRooms/${roomId}/players`);
    const roomDoc = await tx.get(roomRef);
    const playersSnap = await tx.get(playersRef);

    if (!roomDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }
    if (roomDoc.get("hostUid") !== uid) {
      throw new HttpsError("permission-denied", "Só o host pode iniciar");
    }
    if (roomDoc.get("status") !== "lobby") {
      throw new HttpsError("failed-precondition", "Partida já iniciada");
    }

    const uids = playersSnap.docs.map((doc) => doc.id);
    if (uids.length < MIN_JOGADORES || uids.length > MAX_JOGADORES) {
      throw new HttpsError(
        "failed-precondition",
        `Nos Anéis precisa de ${MIN_JOGADORES} a ${MAX_JOGADORES} jogadores`,
      );
    }

    const seated = shuffle(uids);
    let knowerUid: string | null = null;
    if (knowerHumano) {
      if (knowerUidPedido.length > 0) {
        if (!uids.includes(knowerUidPedido)) {
          throw new HttpsError("invalid-argument", "Knower escolhido não está na sala");
        }
        knowerUid = knowerUidPedido;
      } else {
        knowerUid = seated[0];
      }
    }
    const knowerNome = knowerUid ?
      (playersSnap.docs.find((doc) => doc.id === knowerUid)?.get("displayName") as string | undefined) ??
        "Knower" :
      null;
    const finders = knowerUid ? seated.filter((id) => id !== knowerUid) : seated;
    if (knowerHumano && finders.length < 1) {
      throw new HttpsError("failed-precondition", "É preciso ao menos um Finder");
    }

    const necessarias = knowerHumano ?
      CARTAS_POR_MAO * finders.length + CARTAS_SETUP_KNOWER :
      CARTAS_POR_MAO * seated.length + PISTAS_INICIAIS;
    if (banco.coisas.length < necessarias) {
      throw new HttpsError("internal", "Banco de cartas insuficiente para esta sala");
    }

    const historico = (roomDoc.get("historico") as {
      regraIds?: string[];
      regraAssinaturas?: string[];
      coisaIds?: string[];
    } | undefined) ?? {};
    const regrasUsadas = new Set(historico.regraIds ?? []);
    const assinaturasUsadas = new Set(historico.regraAssinaturas ?? []);
    const coisasUsadas = new Set(historico.coisaIds ?? []);
    const regras: Regra[] = [];
    for (const anel of ["palavra", "atributo", "contexto"] as const) {
      const regra = escolherRegra(
        banco.regras,
        anel,
        dificuldade,
        regrasUsadas,
        assinaturasUsadas,
      );
      regras.push(regra);
      regrasUsadas.add(regra.id);
      assinaturasUsadas.add(assinaturaRegra(regra));
    }
    const reservaBaralho = Math.max(16, finders.length * 6);
    const baralhoCheio = montarBaralhoPartida(
      banco.coisas,
      regras,
      coisasUsadas,
      necessarias + reservaBaralho,
    );
    const maos: Record<string, Coisa[]> = {};
    let cursor = 0;
    for (const playerUid of finders) {
      maos[playerUid] = baralhoCheio.slice(cursor, cursor + CARTAS_POR_MAO);
      cursor += CARTAS_POR_MAO;
    }
    if (knowerUid) {
      maos[knowerUid] = baralhoCheio.slice(cursor, cursor + CARTAS_SETUP_KNOWER);
      cursor += CARTAS_SETUP_KNOWER;
    }
    const resto = baralhoCheio.slice(cursor);
    const porId: Record<string, Coisa> = {};
    for (const coisa of baralhoCheio) {
      porId[coisa.id] = coisa;
    }

    let tabuleiro: CartaTabuleiro[] = [];
    let compra = resto;
    if (!knowerHumano) {
      const pistas = escolherPistasIniciais(resto, regras, PISTAS_INICIAIS);
      const pistaIds = new Set(pistas.map((item) => item.id));
      compra = resto.filter((item) => !pistaIds.has(item.id));
      tabuleiro = pistas.map((coisa) => ({
        coisaId: coisa.id,
        texto: coisa.texto,
        regiao: regiaoDe(coisa, regras),
      }));
    }

    for (let i = 0; i < seated.length; i++) {
      const playerUid = seated[i];
      const mao = maos[playerUid] ?? [];
      tx.update(db.doc(`aneisRooms/${roomId}/players/${playerUid}`), {
        seat: i,
        maoCount: mao.length,
      });
      tx.set(db.doc(`aneisRooms/${roomId}/hands/${playerUid}`), {
        coisas: mao.map(cartaPublica),
      });
    }

    tx.set(db.doc(`aneisRooms/${roomId}/secret/current`), {
      regras,
      porId,
      baralho: compra.map((item) => item.id),
    });

    if (knowerUid) {
      tx.set(db.doc(`aneisRooms/${roomId}/knower/view`), {
        knowerUid,
        regras: revelarRegras(regras, banco.aneis),
      });
    }

    tx.set(db.doc(`aneisRooms/${roomId}/state/current`), {
      gameId: db.collection("aneisRooms").doc().id,
      phase: knowerHumano ? "setup" : "playing",
      currentUid: knowerHumano ? knowerUid : finders[0],
      knowerMode,
      knowerUid,
      knowerNome,
      dificuldade,
      aneis: banco.aneis,
      tabuleiro,
      baralhoCount: compra.length,
      ultimaJogada: null,
      pendingJogada: null,
      reversivel: null,
      vencedorUid: null,
      vencedorNome: null,
      regrasReveladas: [],
      playerCount: seated.length,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const idsCoisasUsadas: string[] = [];
    for (const mao of Object.values(maos)) {
      for (const coisa of mao) idsCoisasUsadas.push(coisa.id);
    }
    for (const carta of tabuleiro) idsCoisasUsadas.push(carta.coisaId);

    tx.update(roomRef, {
      status: "playing",
      playerCount: seated.length,
      historico: {
        regraIds: [...new Set([...(historico.regraIds ?? []), ...regras.map((regra) => regra.id)])],
        regraAssinaturas: [...new Set([
          ...(historico.regraAssinaturas ?? []),
          ...regras.map((regra) => assinaturaRegra(regra)),
        ])],
        coisaIds: [...new Set([...(historico.coisaIds ?? []), ...idsCoisasUsadas])],
      },
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const aneisPlaceThing = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = requireRoomId(req.data?.roomId);
  const coisaId = req.data?.coisaId;
  const regiao = req.data?.regiao;
  if (typeof coisaId !== "string" || coisaId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Carta inválida");
  }
  if (typeof regiao !== "string" || !REGIOES_VALIDAS.has(regiao)) {
    throw new HttpsError("invalid-argument", "Região inválida");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`aneisRooms/${roomId}`);
    const stateRef = db.doc(`aneisRooms/${roomId}/state/current`);
    const secretRef = db.doc(`aneisRooms/${roomId}/secret/current`);
    const meRef = db.doc(`aneisRooms/${roomId}/players/${uid}`);
    const handRef = db.doc(`aneisRooms/${roomId}/hands/${uid}`);
    const playersRef = db.collection(`aneisRooms/${roomId}/players`);

    const roomDoc = await tx.get(roomRef);
    const stateDoc = await tx.get(stateRef);
    const secretDoc = await tx.get(secretRef);
    const meDoc = await tx.get(meRef);
    const handDoc = await tx.get(handRef);
    const playersSnap = await tx.get(playersRef);

    if (!roomDoc.exists || !stateDoc.exists || !secretDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (!meDoc.exists) {
      throw new HttpsError("permission-denied", "Você não está na sala");
    }

    const phase = stateDoc.get("phase") as string;
    const knowerUid = (stateDoc.get("knowerUid") as string | null) ?? null;
    const knowerMode = (stateDoc.get("knowerMode") as string | undefined) ?? "app";

    const mao = ((handDoc.get("coisas") as CartaPublica[] | undefined) ?? [])
      .filter((carta) => carta && typeof carta.id === "string");
    const carta = mao.find((item) => item.id === coisaId);
    if (!carta) {
      throw new HttpsError("failed-precondition", "Essa carta não está na sua mão");
    }

    const porId = secretDoc.get("porId") as Record<string, Coisa>;
    const coisa = porId[coisaId];
    if (!coisa) {
      throw new HttpsError("internal", "Carta não encontrada no baralho da partida");
    }

    if (phase === "setup") {
      if (knowerUid !== uid) {
        throw new HttpsError("permission-denied", "Só o Knower posiciona as pistas");
      }
      const tabuleiroAnterior = (stateDoc.get("tabuleiro") as CartaTabuleiro[] | undefined) ?? [];
      const maoRestante = mao.filter((item) => item.id !== coisaId);
      const tabuleiro = [
        ...tabuleiroAnterior,
        {coisaId: coisa.id, texto: coisa.texto, regiao},
      ];
      const reversivelSetup: Reversivel = {
        tipo: "setup",
        currentUid: uid,
        tabuleiro: tabuleiroAnterior,
        knowerMao: mao,
      };
      tx.set(handRef, {coisas: maoRestante});
      tx.update(meRef, {maoCount: maoRestante.length});

      if (tabuleiro.length < PISTAS_INICIAIS) {
        tx.update(stateRef, {
          tabuleiro,
          reversivel: reversivelSetup,
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      tx.set(handRef, {coisas: []});
      tx.update(meRef, {maoCount: 0});
      const seats = finderSeats(orderedSeats(playersSnap), knowerUid);
      tx.update(stateRef, {
        phase: "playing",
        currentUid: seats[0]?.uid ?? uid,
        tabuleiro,
        pendingJogada: null,
        reversivel: reversivelSetup,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    if (phase !== "playing") {
      throw new HttpsError("failed-precondition", "Não é hora de posicionar carta");
    }
    if (knowerUid === uid) {
      throw new HttpsError("permission-denied", "O Knower não joga cartas da mão");
    }
    if (stateDoc.get("currentUid") !== uid) {
      throw new HttpsError("permission-denied", "Não é a sua vez");
    }

    const maoRestante = mao.filter((item) => item.id !== coisaId);
    tx.set(handRef, {coisas: maoRestante});
    tx.update(meRef, {maoCount: maoRestante.length});

    if (knowerMode === "jogador" && knowerUid) {
      tx.update(stateRef, {
        phase: "judging",
        pendingJogada: {
          uid,
          nome: meDoc.get("displayName") as string,
          coisaId: coisa.id,
          texto: coisa.texto,
          regiaoEscolhida: regiao,
        },
        reversivel: null,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const regras = secretDoc.get("regras") as Regra[];
    const baralho = [...((secretDoc.get("baralho") as string[] | undefined) ?? [])];
    aplicarResolucao(tx, {
      roomRef,
      stateRef,
      secretRef,
      playersSnap,
      regras,
      porId,
      baralho,
      tabuleiroAtual: (stateDoc.get("tabuleiro") as CartaTabuleiro[] | undefined) ?? [],
      jogadorUid: uid,
      jogadorNome: meDoc.get("displayName") as string,
      coisa,
      regiaoEscolhida: regiao,
      regiaoCerta: regiaoDe(coisa, regras),
      maoRestante,
      knowerUid,
      reversivel: null,
    });
  });

  return {ok: true};
});

type PendingJogada = {
  uid: string;
  nome: string;
  coisaId: string;
  texto: string;
  regiaoEscolhida: string;
};

type Reversivel = {
  tipo?: "judge" | "setup";
  pendingJogada?: PendingJogada;
  currentUid: string;
  tabuleiro: CartaTabuleiro[];
  baralho?: string[];
  finderMao?: CartaPublica[];
  knowerMao?: CartaPublica[];
};

type ResolucaoArgs = {
  roomRef: DocumentReference;
  stateRef: DocumentReference;
  secretRef: DocumentReference;
  playersSnap: QuerySnapshot;
  regras: Regra[];
  porId: Record<string, Coisa>;
  baralho: string[];
  tabuleiroAtual: CartaTabuleiro[];
  jogadorUid: string;
  jogadorNome: string;
  coisa: Coisa;
  regiaoEscolhida: string;
  regiaoCerta: string;
  maoRestante: CartaPublica[];
  knowerUid: string | null;
  reversivel: Reversivel | null;
};

function aplicarResolucao(tx: Transaction, args: ResolucaoArgs) {
  const acertou = args.regiaoCerta === args.regiaoEscolhida;
  const maoRestante = [...args.maoRestante];
  const baralho = [...args.baralho];
  let cartasRestantes = maoRestante.length;

  if (!acertou && baralho.length > 0) {
    const compradaId = baralho.shift() as string;
    const comprada = args.porId[compradaId];
    if (comprada) {
      maoRestante.push(cartaPublica(comprada));
      cartasRestantes = maoRestante.length;
    }
  }

  const finderHandRef = db.doc(`${args.roomRef.path}/hands/${args.jogadorUid}`);
  const finderRef = db.doc(`${args.roomRef.path}/players/${args.jogadorUid}`);
  tx.set(finderHandRef, {coisas: maoRestante});
  tx.update(finderRef, {maoCount: cartasRestantes});
  tx.update(args.secretRef, {baralho});

  const tabuleiro = [
    ...args.tabuleiroAtual,
    {coisaId: args.coisa.id, texto: args.coisa.texto, regiao: args.regiaoCerta},
  ];
  const ultimaJogada = {
    uid: args.jogadorUid,
    nome: args.jogadorNome,
    texto: args.coisa.texto,
    regiaoEscolhida: args.regiaoEscolhida,
    regiaoCerta: args.regiaoCerta,
    acertou,
    cartasRestantes,
  };

  if (acertou && cartasRestantes === 0) {
    tx.update(args.stateRef, {
      phase: "over",
      tabuleiro,
      baralhoCount: baralho.length,
      ultimaJogada,
      pendingJogada: null,
      reversivel: null,
      vencedorUid: args.jogadorUid,
      vencedorNome: args.jogadorNome,
      regrasReveladas: revelarRegras(args.regras, carregarBanco().aneis),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(args.roomRef, {
      status: "finished",
      updatedAt: FieldValue.serverTimestamp(),
    });
    return;
  }

  const seats = orderedSeats(args.playersSnap);
  tx.update(args.stateRef, {
    phase: "playing",
    currentUid: acertou ?
      args.jogadorUid :
      nextFinderUid(seats, args.jogadorUid, args.knowerUid),
    tabuleiro,
    baralhoCount: baralho.length,
    ultimaJogada,
    pendingJogada: null,
    reversivel: args.reversivel,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

export const aneisJudgePlacement = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = requireRoomId(req.data?.roomId);
  const regiao = req.data?.regiao;
  if (typeof regiao !== "string" || !REGIOES_VALIDAS.has(regiao)) {
    throw new HttpsError("invalid-argument", "Região inválida");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`aneisRooms/${roomId}`);
    const stateRef = db.doc(`aneisRooms/${roomId}/state/current`);
    const secretRef = db.doc(`aneisRooms/${roomId}/secret/current`);
    const playersRef = db.collection(`aneisRooms/${roomId}/players`);
    const roomDoc = await tx.get(roomRef);
    const stateDoc = await tx.get(stateRef);
    const secretDoc = await tx.get(secretRef);
    const playersSnap = await tx.get(playersRef);

    if (!roomDoc.exists || !stateDoc.exists || !secretDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (stateDoc.get("phase") !== "judging") {
      throw new HttpsError("failed-precondition", "Não há carta para julgar");
    }
    if (stateDoc.get("knowerUid") !== uid) {
      throw new HttpsError("permission-denied", "Só o Knower posiciona a carta");
    }

    const pending = stateDoc.get("pendingJogada") as {
      uid: string;
      nome: string;
      coisaId: string;
      texto: string;
      regiaoEscolhida: string;
    } | null;
    if (!pending) {
      throw new HttpsError("failed-precondition", "Nenhuma carta pendente");
    }

    const finderHandRef = db.doc(`aneisRooms/${roomId}/hands/${pending.uid}`);
    const finderHandDoc = await tx.get(finderHandRef);
    const maoRestante = ((finderHandDoc.get("coisas") as CartaPublica[] | undefined) ?? [])
      .filter((carta) => carta && carta.id !== pending.coisaId);

    const porId = secretDoc.get("porId") as Record<string, Coisa>;
    const coisa = porId[pending.coisaId] ?? {
      id: pending.coisaId,
      texto: pending.texto,
      palavra: {
        normalizada: pending.texto,
        silabas: 1,
        genero: "n",
        inicia: "",
        termina: "",
        temAcento: false,
        temHifen: false,
        temEspaco: false,
      },
      tags: [],
    };

    aplicarResolucao(tx, {
      roomRef,
      stateRef,
      secretRef,
      playersSnap,
      regras: secretDoc.get("regras") as Regra[],
      porId,
      baralho: [...((secretDoc.get("baralho") as string[] | undefined) ?? [])],
      tabuleiroAtual: (stateDoc.get("tabuleiro") as CartaTabuleiro[] | undefined) ?? [],
      jogadorUid: pending.uid,
      jogadorNome: pending.nome,
      coisa,
      regiaoEscolhida: pending.regiaoEscolhida,
      regiaoCerta: regiao,
      maoRestante,
      knowerUid: uid,
      reversivel: {
        tipo: "judge",
        pendingJogada: pending,
        currentUid: pending.uid,
        tabuleiro: (stateDoc.get("tabuleiro") as CartaTabuleiro[] | undefined) ?? [],
        baralho: [...((secretDoc.get("baralho") as string[] | undefined) ?? [])],
        finderMao: maoRestante,
      },
    });
  });

  return {ok: true};
});

export const aneisUndoJudge = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = requireRoomId(req.data?.roomId);

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`aneisRooms/${roomId}`);
    const stateRef = db.doc(`aneisRooms/${roomId}/state/current`);
    const secretRef = db.doc(`aneisRooms/${roomId}/secret/current`);
    const roomDoc = await tx.get(roomRef);
    const stateDoc = await tx.get(stateRef);
    const secretDoc = await tx.get(secretRef);

    if (!roomDoc.exists || !stateDoc.exists || !secretDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (stateDoc.get("knowerUid") !== uid) {
      throw new HttpsError("permission-denied", "Só o Knower pode desfazer");
    }

    const phase = stateDoc.get("phase") as string;
    const reversivel = stateDoc.get("reversivel") as Reversivel | null;
    if (!reversivel) {
      throw new HttpsError("failed-precondition", "Não há jogada para desfazer");
    }

    if (reversivel.tipo === "setup") {
      if (phase !== "setup" && phase !== "playing") {
        throw new HttpsError("failed-precondition", "Não há jogada para desfazer");
      }
      if (phase === "playing" && stateDoc.get("pendingJogada")) {
        throw new HttpsError("failed-precondition", "Não há jogada para desfazer");
      }
      const knowerMao = reversivel.knowerMao ?? [];
      const knowerHandRef = db.doc(`aneisRooms/${roomId}/hands/${uid}`);
      const knowerRef = db.doc(`aneisRooms/${roomId}/players/${uid}`);
      await tx.get(knowerHandRef);
      await tx.get(knowerRef);

      tx.set(knowerHandRef, {coisas: knowerMao});
      tx.update(knowerRef, {maoCount: knowerMao.length});
      tx.update(stateRef, {
        phase: "setup",
        currentUid: uid,
        tabuleiro: reversivel.tabuleiro,
        pendingJogada: null,
        ultimaJogada: null,
        reversivel: null,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    if (phase !== "playing") {
      throw new HttpsError("failed-precondition", "Não há jogada para desfazer");
    }
    if (!reversivel.pendingJogada || !reversivel.finderMao) {
      throw new HttpsError("failed-precondition", "Não há jogada para desfazer");
    }

    const finderHandRef = db.doc(`aneisRooms/${roomId}/hands/${reversivel.pendingJogada.uid}`);
    const finderRef = db.doc(`aneisRooms/${roomId}/players/${reversivel.pendingJogada.uid}`);
    await tx.get(finderHandRef);
    await tx.get(finderRef);

    tx.set(finderHandRef, {coisas: reversivel.finderMao});
    tx.update(finderRef, {maoCount: reversivel.finderMao.length});
    tx.update(secretRef, {baralho: reversivel.baralho ?? []});
    tx.update(stateRef, {
      phase: "judging",
      currentUid: reversivel.currentUid,
      tabuleiro: reversivel.tabuleiro,
      baralhoCount: (reversivel.baralho ?? []).length,
      pendingJogada: reversivel.pendingJogada,
      ultimaJogada: null,
      reversivel: null,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

function limparPartida(
  tx: Transaction,
  roomId: string,
  roomRef: DocumentReference,
  playersSnap: QuerySnapshot,
) {
  const stateRef = db.doc(`aneisRooms/${roomId}/state/current`);
  const secretRef = db.doc(`aneisRooms/${roomId}/secret/current`);
  const knowerRef = db.doc(`aneisRooms/${roomId}/knower/view`);
  tx.delete(stateRef);
  tx.delete(secretRef);
  tx.delete(knowerRef);

  for (const player of playersSnap.docs) {
    tx.update(player.ref, {seat: null, maoCount: 0});
    tx.delete(db.doc(`aneisRooms/${roomId}/hands/${player.id}`));
  }

  tx.update(roomRef, {
    status: "lobby",
    playerCount: playersSnap.size,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

export const aneisResetRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = requireRoomId(req.data?.roomId);

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`aneisRooms/${roomId}`);
    const stateRef = db.doc(`aneisRooms/${roomId}/state/current`);
    const playersRef = db.collection(`aneisRooms/${roomId}/players`);
    const roomDoc = await tx.get(roomRef);
    const stateDoc = await tx.get(stateRef);
    const playersSnap = await tx.get(playersRef);

    if (!roomDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }
    if (roomDoc.get("hostUid") !== uid) {
      throw new HttpsError("permission-denied", "Só o host pode voltar ao lobby");
    }
    const phase = stateDoc.exists ? stateDoc.get("phase") : null;
    if (roomDoc.get("status") !== "finished" && phase !== "over") {
      throw new HttpsError("failed-precondition", "A partida ainda não terminou");
    }

    await tx.get(db.doc(`aneisRooms/${roomId}/secret/current`));
    await tx.get(db.doc(`aneisRooms/${roomId}/knower/view`));
    for (const player of playersSnap.docs) {
      await tx.get(db.doc(`aneisRooms/${roomId}/hands/${player.id}`));
    }

    limparPartida(tx, roomId, roomRef, playersSnap);
  });

  return {ok: true};
});

export const aneisAbortGame = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = requireRoomId(req.data?.roomId);

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`aneisRooms/${roomId}`);
    const playersRef = db.collection(`aneisRooms/${roomId}/players`);
    const roomDoc = await tx.get(roomRef);
    const playersSnap = await tx.get(playersRef);
    await tx.get(db.doc(`aneisRooms/${roomId}/state/current`));
    await tx.get(db.doc(`aneisRooms/${roomId}/secret/current`));
    await tx.get(db.doc(`aneisRooms/${roomId}/knower/view`));
    for (const player of playersSnap.docs) {
      await tx.get(db.doc(`aneisRooms/${roomId}/hands/${player.id}`));
    }

    if (!roomDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }
    if (roomDoc.get("hostUid") !== uid) {
      throw new HttpsError("permission-denied", "Só o host pode abortar");
    }
    if (roomDoc.get("status") !== "playing") {
      throw new HttpsError("failed-precondition", "Não há partida em andamento");
    }

    limparPartida(tx, roomId, roomRef, playersSnap);
  });

  return {ok: true};
});
