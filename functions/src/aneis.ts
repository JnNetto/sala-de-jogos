import {FieldValue} from "firebase-admin/firestore";
import type {DocumentReference, QuerySnapshot, Transaction} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {EXIGIR_APP_CHECK, db} from "./firebaseAdmin";
import {
  AnelPublico,
  Coisa,
  REGIOES_VALIDAS,
  Regra,
  avaliaRegra,
  escolherPistasPorAnel,
  regiaoDe,
  regiaoTemAnel,
} from "./aneisAvaliador";
import {
  criarSala,
  entrarSala,
  expulsarJogador,
  normalizeCode,
  normalizeDisplayName,
  requireConta,
  requireRoomId,
  requireTargetUid,
  limparTexto,
  sairSala,
  shuffle,
  type SalaLobby,
} from "./salaLobby";

const region = "southamerica-east1";
const MIN_JOGADORES = 2;
const MAX_JOGADORES = 6;
const CARTAS_POR_MAO = 5;
/** Uma pista em cada anel e uma fora. */
const PISTAS_INICIAIS = 4;
/** As pistas do Guardião e duas cartas de folga. */
const CARTAS_SETUP_KNOWER = PISTAS_INICIAIS + 2;
const ANEIS = ["palavra", "atributo", "contexto"] as const;
const OPCOES_POR_ANEL = 4;
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

const aneisLobby: SalaLobby = {
  rooms: "aneisRooms",
  codes: "aneisRoomCodes",
  maxPlayers: MAX_JOGADORES,
  playerExtra: {maoCount: 0},
};

let bancoCache: Banco | undefined;

function carregarBanco(): Banco {
  if (!bancoCache) {
    bancoCache = require("./data/aneis_banco.json") as Banco;
  }
  return bancoCache;
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
    throw new HttpsError("failed-precondition", "Não há quem jogue na partida");
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

/** A preparação do Guardião acaba com uma pista em cada anel e uma fora. */
function preparacaoCompleta(tabuleiro: CartaTabuleiro[]): boolean {
  return ANEIS.every((anel) => tabuleiro.some((carta) => regiaoTemAnel(carta.regiao, anel))) &&
    tabuleiro.some((carta) => carta.regiao === "nenhum");
}

/**
 * Para o "Desvendar uma regra" quando o jogo é o Guardião: a regra certa de
 * cada anel embaralhada com três falsas do mesmo anel.
 */
function opcoesDeRegras(todas: Regra[], escolhidas: Regra[]): Record<string, string[]> {
  const opcoes: Record<string, string[]> = {};
  for (const regra of escolhidas) {
    const assinatura = assinaturaRegra(regra);
    const doAnel = todas.filter((outra) =>
      outra.anel === regra.anel &&
      outra.id !== regra.id &&
      outra.texto !== regra.texto &&
      assinaturaRegra(outra) !== assinatura,
    );
    const falsas = [
      ...shuffle(doAnel.filter((outra) => outra.dificuldade === regra.dificuldade)),
      ...shuffle(doAnel.filter((outra) => outra.dificuldade !== regra.dificuldade)),
    ]
      .map((outra) => outra.texto)
      .filter((texto, i, lista) => lista.indexOf(texto) === i)
      .slice(0, OPCOES_POR_ANEL - 1);
    opcoes[regra.anel] = shuffle([regra.texto, ...falsas]);
  }
  return opcoes;
}

export const aneisCreateRoom = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
  const displayName = normalizeDisplayName(req.data?.displayName);
  return criarSala(aneisLobby, uid, displayName);
});

export const aneisJoinRoom = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
  const displayName = normalizeDisplayName(req.data?.displayName);
  const code = normalizeCode(req.data?.code);
  const roomId = await entrarSala(aneisLobby, uid, displayName, code);
  return {roomId};
});

export const aneisLeaveRoom = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
  const roomId = requireRoomId(req.data?.roomId);
  await sairSala(aneisLobby, uid, roomId);
  return {ok: true};
});

export const aneisRemovePlayer = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
  const roomId = requireRoomId(req.data?.roomId);
  const targetUid = requireTargetUid(req.data?.targetUid);
  await expulsarJogador(aneisLobby, uid, roomId, targetUid);
  return {ok: true};
});
export const aneisStartGame = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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
    const historicoRef = db.doc(`aneisRooms/${roomId}/secret/historico`);
    const roomDoc = await tx.get(roomRef);
    const playersSnap = await tx.get(playersRef);
    const historicoDoc = await tx.get(historicoRef);

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
        `Cabe Aqui? precisa de ${MIN_JOGADORES} a ${MAX_JOGADORES} jogadores`,
      );
    }

    const seated = shuffle(uids);
    let knowerUid: string | null = null;
    if (knowerHumano) {
      if (knowerUidPedido.length > 0) {
        if (!uids.includes(knowerUidPedido)) {
          throw new HttpsError("invalid-argument", "O Guardião escolhido não está na sala");
        }
        knowerUid = knowerUidPedido;
      } else {
        knowerUid = seated[0];
      }
    }
    const knowerNome = knowerUid ?
      (playersSnap.docs.find((doc) => doc.id === knowerUid)?.get("displayName") as string | undefined) ??
        "Guardião" :
      null;
    const finders = knowerUid ? seated.filter((id) => id !== knowerUid) : seated;
    if (knowerHumano && finders.length < 1) {
      throw new HttpsError("failed-precondition", "É preciso ao menos uma pessoa além do Guardião");
    }

    const necessarias = knowerHumano ?
      CARTAS_POR_MAO * finders.length + CARTAS_SETUP_KNOWER :
      CARTAS_POR_MAO * seated.length + PISTAS_INICIAIS;
    if (banco.coisas.length < necessarias) {
      throw new HttpsError("internal", "Banco de cartas insuficiente para esta sala");
    }

    // O que já saiu nas partidas desta sala, para variar. Fica no segredo:
    // os ids das regras entregariam as regras da partida.
    const historico = ((historicoDoc.exists ?
      historicoDoc.data() :
      roomDoc.get("historico")) as {
      regraIds?: string[];
      regraAssinaturas?: string[];
      coisaIds?: string[];
    } | undefined) ?? {};
    const regrasUsadas = new Set(historico.regraIds ?? []);
    const assinaturasUsadas = new Set(historico.regraAssinaturas ?? []);
    const coisasUsadas = new Set(historico.coisaIds ?? []);
    const regras: Regra[] = [];
    for (const anel of ANEIS) {
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
    let resto = baralhoCheio.slice(cursor);

    // As pistas saem do banco inteiro (menos as cartas já nas mãos): com uma
    // regra rara, o baralho da partida pode não ter carta para algum anel.
    // As novas na sala vêm primeiro.
    const nasMaos = new Set(Object.values(maos).flat().map((coisa) => coisa.id));
    const candidatas = banco.coisas.filter((coisa) => !nasMaos.has(coisa.id));
    const pistas = escolherPistasPorAnel(
      [
        ...shuffle(candidatas.filter((coisa) => !coisasUsadas.has(coisa.id))),
        ...shuffle(candidatas.filter((coisa) => coisasUsadas.has(coisa.id))),
      ],
      regras,
    );
    const idsPistas = new Set(pistas.map((coisa) => coisa.id));
    resto = resto.filter((coisa) => !idsPistas.has(coisa.id));

    if (knowerUid) {
      // O Guardião recebe as pistas (uma para cada anel e uma que fica
      // fora) e duas cartas de folga.
      const folga = resto.slice(0, CARTAS_SETUP_KNOWER - pistas.length);
      maos[knowerUid] = shuffle([...pistas, ...folga]);
      const naMao = new Set(maos[knowerUid].map((coisa) => coisa.id));
      resto = resto.filter((coisa) => !naMao.has(coisa.id));
    }
    const porId: Record<string, Coisa> = {};
    for (const coisa of [...baralhoCheio, ...pistas]) {
      porId[coisa.id] = coisa;
    }

    const compra = resto;
    const tabuleiro: CartaTabuleiro[] = knowerHumano ?
      [] :
      pistas.map((coisa) => ({
        coisaId: coisa.id,
        texto: coisa.texto,
        regiao: regiaoDe(coisa, regras),
      }));

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
      aneisDesvendados: [],
      pendingPalpite: null,
      opcoesRegras: knowerHumano ? null : opcoesDeRegras(banco.regras, regras),
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
      historico: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(historicoRef, {
        regraIds: [...new Set([...(historico.regraIds ?? []), ...regras.map((regra) => regra.id)])],
        regraAssinaturas: [...new Set([
          ...(historico.regraAssinaturas ?? []),
          ...regras.map((regra) => assinaturaRegra(regra)),
        ])],
        coisaIds: [...new Set([...(historico.coisaIds ?? []), ...idsCoisasUsadas])],
    });
  });

  return {ok: true};
});

export const aneisPlaceThing = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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
        throw new HttpsError("permission-denied", "Só o Guardião posiciona as pistas");
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

      if (!preparacaoCompleta(tabuleiro) && maoRestante.length > 0) {
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
      throw new HttpsError("permission-denied", "O Guardião não joga cartas da mão");
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

export const aneisJudgePlacement = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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
      throw new HttpsError("permission-denied", "Só o Guardião posiciona a carta");
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

export const aneisUndoJudge = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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
      throw new HttpsError("permission-denied", "Só o Guardião pode desfazer");
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

type PalpiteDeRegra = {
  uid: string;
  nome: string;
  anel: string;
  palpite: string;
};

type RegraRevelada = ReturnType<typeof revelarRegras>[number];

type PalpiteArgs = {
  roomRef: DocumentReference;
  stateRef: DocumentReference;
  secretRef: DocumentReference;
  playersSnap: QuerySnapshot;
  regras: Regra[];
  porId: Record<string, Coisa>;
  baralho: string[];
  mao: CartaPublica[];
  jogadorUid: string;
  jogadorNome: string;
  anel: string;
  palpite: string;
  acertou: boolean;
  knowerUid: string | null;
  desvendados: RegraRevelada[];
};

/**
 * Fecha um "Desvendar uma regra". Acertou: descarta duas cartas ao acaso e
 * o anel fica aberto para todos. Errou: compra uma. A vez passa nos dois
 * casos; quem fica sem cartas vence.
 */
function resolverPalpite(tx: Transaction, args: PalpiteArgs) {
  const banco = carregarBanco();
  const baralho = [...args.baralho];
  let mao = [...args.mao];
  const desvendados = [...args.desvendados];
  const regra = args.regras.find((item) => item.anel === args.anel);

  if (args.acertou) {
    mao = shuffle(mao).slice(2);
    if (regra) desvendados.push(...revelarRegras([regra], banco.aneis));
  } else if (baralho.length > 0) {
    const comprada = args.porId[baralho.shift() as string];
    if (comprada) mao.push(cartaPublica(comprada));
  }

  tx.set(db.doc(`${args.roomRef.path}/hands/${args.jogadorUid}`), {coisas: mao});
  tx.update(db.doc(`${args.roomRef.path}/players/${args.jogadorUid}`), {
    maoCount: mao.length,
  });
  tx.update(args.secretRef, {baralho});

  const ultimaJogada = {
    tipo: "regra",
    uid: args.jogadorUid,
    nome: args.jogadorNome,
    anel: args.anel,
    palpite: args.palpite,
    texto: args.palpite,
    regiaoEscolhida: args.anel,
    regiaoCerta: args.anel,
    acertou: args.acertou,
    cartasRestantes: mao.length,
  };

  if (mao.length === 0) {
    tx.update(args.stateRef, {
      phase: "over",
      baralhoCount: baralho.length,
      ultimaJogada,
      pendingJogada: null,
      pendingPalpite: null,
      aneisDesvendados: desvendados,
      reversivel: null,
      vencedorUid: args.jogadorUid,
      vencedorNome: args.jogadorNome,
      regrasReveladas: revelarRegras(args.regras, banco.aneis),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(args.roomRef, {
      status: "finished",
      updatedAt: FieldValue.serverTimestamp(),
    });
    return;
  }

  tx.update(args.stateRef, {
    phase: "playing",
    currentUid: nextFinderUid(orderedSeats(args.playersSnap), args.jogadorUid, args.knowerUid),
    baralhoCount: baralho.length,
    ultimaJogada,
    pendingJogada: null,
    pendingPalpite: null,
    aneisDesvendados: desvendados,
    reversivel: null,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

export const aneisGuessRule = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
  const roomId = requireRoomId(req.data?.roomId);
  const anel = req.data?.anel;
  const palpiteRaw = req.data?.palpite;
  if (typeof anel !== "string" || !(ANEIS as readonly string[]).includes(anel)) {
    throw new HttpsError("invalid-argument", "Anel inválido");
  }
  const palpite = typeof palpiteRaw === "string" ? limparTexto(palpiteRaw) : "";
  if (palpite.length < 1 || palpite.length > 80) {
    throw new HttpsError("invalid-argument", "Diga qual seria a regra");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`aneisRooms/${roomId}`);
    const stateRef = db.doc(`aneisRooms/${roomId}/state/current`);
    const secretRef = db.doc(`aneisRooms/${roomId}/secret/current`);
    const meRef = db.doc(`aneisRooms/${roomId}/players/${uid}`);
    const handRef = db.doc(`aneisRooms/${roomId}/hands/${uid}`);
    const roomDoc = await tx.get(roomRef);
    const stateDoc = await tx.get(stateRef);
    const secretDoc = await tx.get(secretRef);
    const meDoc = await tx.get(meRef);
    const handDoc = await tx.get(handRef);
    const playersSnap = await tx.get(db.collection(`aneisRooms/${roomId}/players`));

    if (!roomDoc.exists || !stateDoc.exists || !secretDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (!meDoc.exists) {
      throw new HttpsError("permission-denied", "Você não está na sala");
    }
    if (stateDoc.get("phase") !== "playing") {
      throw new HttpsError("failed-precondition", "Não é hora de desvendar");
    }
    const knowerUid = (stateDoc.get("knowerUid") as string | null) ?? null;
    if (knowerUid === uid) {
      throw new HttpsError("permission-denied", "O Guardião já sabe as regras");
    }
    if (stateDoc.get("currentUid") !== uid) {
      throw new HttpsError("permission-denied", "Não é a sua vez");
    }
    const desvendados = (stateDoc.get("aneisDesvendados") as RegraRevelada[] | undefined) ?? [];
    if (desvendados.some((item) => item.anel === anel)) {
      throw new HttpsError("failed-precondition", "Esse anel já foi desvendado");
    }

    const nome = meDoc.get("displayName") as string;
    if (stateDoc.get("knowerMode") === "jogador" && knowerUid) {
      const pendingPalpite: PalpiteDeRegra = {uid, nome, anel, palpite};
      tx.update(stateRef, {
        phase: "judgingRule",
        pendingPalpite,
        reversivel: null,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const opcoes = (stateDoc.get("opcoesRegras") as Record<string, string[]> | null)?.[anel] ?? [];
    if (!opcoes.includes(palpite)) {
      throw new HttpsError("invalid-argument", "Escolha uma das opções");
    }
    const regras = secretDoc.get("regras") as Regra[];
    resolverPalpite(tx, {
      roomRef,
      stateRef,
      secretRef,
      playersSnap,
      regras,
      porId: secretDoc.get("porId") as Record<string, Coisa>,
      baralho: (secretDoc.get("baralho") as string[] | undefined) ?? [],
      mao: (handDoc.get("coisas") as CartaPublica[] | undefined) ?? [],
      jogadorUid: uid,
      jogadorNome: nome,
      anel,
      palpite,
      acertou: regras.find((regra) => regra.anel === anel)?.texto === palpite,
      knowerUid,
      desvendados,
    });
  });

  return {ok: true};
});

export const aneisJudgeRule = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
  const roomId = requireRoomId(req.data?.roomId);
  const acertou = req.data?.acertou;
  if (typeof acertou !== "boolean") {
    throw new HttpsError("invalid-argument", "Diga se o palpite acertou");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`aneisRooms/${roomId}`);
    const stateRef = db.doc(`aneisRooms/${roomId}/state/current`);
    const secretRef = db.doc(`aneisRooms/${roomId}/secret/current`);
    const roomDoc = await tx.get(roomRef);
    const stateDoc = await tx.get(stateRef);
    const secretDoc = await tx.get(secretRef);
    const playersSnap = await tx.get(db.collection(`aneisRooms/${roomId}/players`));

    if (!roomDoc.exists || !stateDoc.exists || !secretDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (stateDoc.get("phase") !== "judgingRule") {
      throw new HttpsError("failed-precondition", "Não há palpite para julgar");
    }
    if (stateDoc.get("knowerUid") !== uid) {
      throw new HttpsError("permission-denied", "Só o Guardião julga o palpite");
    }
    const pendente = stateDoc.get("pendingPalpite") as PalpiteDeRegra | null;
    if (!pendente) {
      throw new HttpsError("failed-precondition", "Nenhum palpite pendente");
    }
    const handDoc = await tx.get(db.doc(`aneisRooms/${roomId}/hands/${pendente.uid}`));

    resolverPalpite(tx, {
      roomRef,
      stateRef,
      secretRef,
      playersSnap,
      regras: secretDoc.get("regras") as Regra[],
      porId: secretDoc.get("porId") as Record<string, Coisa>,
      baralho: (secretDoc.get("baralho") as string[] | undefined) ?? [],
      mao: (handDoc.get("coisas") as CartaPublica[] | undefined) ?? [],
      jogadorUid: pendente.uid,
      jogadorNome: pendente.nome,
      anel: pendente.anel,
      palpite: pendente.palpite,
      acertou,
      knowerUid: uid,
      desvendados: (stateDoc.get("aneisDesvendados") as RegraRevelada[] | undefined) ?? [],
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

export const aneisResetRoom = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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

export const aneisAbortGame = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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
