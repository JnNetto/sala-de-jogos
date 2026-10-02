import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {db} from "./firebaseAdmin";

const region = "southamerica-east1";

const MIN_JOGADORES = 3;
const MAX_JOGADORES = 7;
const CARTAS_POR_PARTIDA = 13;

type Carta = { id: string; palavras: string[] };

type PlayerSeat = { uid: string; seat: number };

type Clue = {
  clueId: string;
  autorUid: string;
  texto: string;
  anulada: boolean;
  motivoAutoAnulacao: string | null;
};

type HistoricoEntry = {
  round: number;
  palavras: string[];
  palavraAlvo: string;
  guesserUid: string;
  palpite: string | null;
  resultado: "acerto" | "erro" | "passou";
  pontos: number;
};

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

function normalizeWord(value: unknown, label: string): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${label} inválida`);
  }
  const word = value.trim();
  if (word.length < 1 || word.length > 40) {
    throw new HttpsError("invalid-argument", `${label} deve ter 1 a 40 caracteres`);
  }
  return word;
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
    [list[i], list[j]] = [list[j], list[i]];
  }
  return list;
}

function orderedSeats(
  players: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>,
): PlayerSeat[] {
  return players.docs
    .map((doc) => ({uid: doc.id, seat: doc.get("seat") as number | null}))
    .filter((player): player is PlayerSeat => typeof player.seat === "number")
    .sort((a, b) => a.seat - b.seat);
}

function nextGuesserUid(players: PlayerSeat[], currentUid: string): string {
  const currentIndex = players.findIndex((player) => player.uid === currentUid);
  if (currentIndex < 0 || players.length === 0) {
    throw new HttpsError("failed-precondition", "Adivinhador inválido");
  }
  return players[(currentIndex + 1) % players.length].uid;
}

// --- comparação de pistas ---
// Mesma especificação de lib/core/utils/so_uma_pista_matcher.dart: cobre só os
// casos inequívocos (idêntica, plural e gênero regulares, e uma sugestão de
// mesma raiz por prefixo comum). O resto (homófonas, palavra inventada,
// idioma estrangeiro) fica para o grupo decidir manualmente na comparação.

const COM_ACENTO = "àáâãäåèéêëìíîïòóôõöùúûüçñ";
const SEM_ACENTO = "aaaaaaeeeeiiiiooooouuuucn";

function normalizarPalavra(texto: string): string {
  let resultado = texto.trim().toLowerCase();
  for (let i = 0; i < COM_ACENTO.length; i++) {
    resultado = resultado.split(COM_ACENTO[i]).join(SEM_ACENTO[i]);
  }
  resultado = resultado.replace(/^[^a-z0-9]+|[^a-z0-9]+$/g, "");
  resultado = resultado.replace(/\s+/g, " ");
  return resultado;
}

function radicalPlural(palavra: string): string {
  if (palavra.endsWith("oes") || palavra.endsWith("aes") || palavra.endsWith("ais")) {
    return palavra;
  }
  if (palavra.endsWith("es") && palavra.length > 3) return palavra.slice(0, -2);
  if (palavra.endsWith("s") && palavra.length > 3) return palavra.slice(0, -1);
  return palavra;
}

function mesmoPlural(a: string, b: string): boolean {
  return a !== b && radicalPlural(a) === radicalPlural(b);
}

function mesmoGenero(a: string, b: string): boolean {
  const termina = (s: string, sufixo: string) => s.length > 3 && s.endsWith(sufixo);
  if (termina(a, "o") && termina(b, "a")) return a.slice(0, -1) === b.slice(0, -1);
  if (termina(a, "a") && termina(b, "o")) return a.slice(0, -1) === b.slice(0, -1);
  return false;
}

function possivelMesmaRaiz(a: string, b: string): boolean {
  if (a.length < 4 || b.length < 4 || a === b) return false;
  const menor = a.length < b.length ? a : b;
  const maior = a.length < b.length ? b : a;
  let comuns = 0;
  while (comuns < menor.length && menor[comuns] === maior[comuns]) comuns++;
  return comuns >= 3 && comuns / menor.length >= 0.7;
}

type MatchResultado = { anulada: boolean; motivo?: string };

function compararComAlvo(pista: string, alvo: string): MatchResultado {
  const p = normalizarPalavra(pista);
  const a = normalizarPalavra(alvo);
  if (!p) return {anulada: false};
  if (p === a) return {anulada: true, motivo: "palavra_alvo"};
  if (mesmoPlural(p, a) || mesmoGenero(p, a)) return {anulada: true, motivo: "palavra_alvo"};
  if (possivelMesmaRaiz(p, a)) return {anulada: true, motivo: "palavra_alvo_raiz"};
  return {anulada: false};
}

function compararPistas(x: string, y: string): MatchResultado {
  const nx = normalizarPalavra(x);
  const ny = normalizarPalavra(y);
  if (!nx || !ny) return {anulada: false};
  if (nx === ny) return {anulada: true, motivo: "identica"};
  if (mesmoPlural(nx, ny)) return {anulada: true, motivo: "plural"};
  if (mesmoGenero(nx, ny)) return {anulada: true, motivo: "genero"};
  if (possivelMesmaRaiz(nx, ny)) return {anulada: true, motivo: "raiz"};
  return {anulada: false};
}

function palpiteCorreto(palpite: string, alvo: string): boolean {
  return normalizarPalavra(palpite) === normalizarPalavra(alvo);
}

function aplicarAnulacoes(clues: Clue[], palavraAlvo: string): Clue[] {
  const atualizadas = clues.map((clue) => ({...clue}));

  for (const clue of atualizadas) {
    const resultado = compararComAlvo(clue.texto, palavraAlvo);
    if (resultado.anulada) {
      clue.anulada = true;
      clue.motivoAutoAnulacao = resultado.motivo ?? null;
    }
  }

  for (let i = 0; i < atualizadas.length; i++) {
    for (let j = i + 1; j < atualizadas.length; j++) {
      const resultado = compararPistas(atualizadas[i].texto, atualizadas[j].texto);
      if (resultado.anulada) {
        atualizadas[i].anulada = true;
        atualizadas[i].motivoAutoAnulacao = atualizadas[i].motivoAutoAnulacao ?? resultado.motivo ?? null;
        atualizadas[j].anulada = true;
        atualizadas[j].motivoAutoAnulacao = atualizadas[j].motivoAutoAnulacao ?? resultado.motivo ?? null;
      }
    }
  }

  return atualizadas;
}

// --- callables ---

export const soUmaCreateRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const displayName = normalizeDisplayName(req.data?.displayName);

  for (let attempt = 0; attempt < 8; attempt++) {
    const code = createRoomCode();
    const codeRef = db.doc(`soUmaRoomCodes/${code}`);
    const roomRef = db.collection("soUmaRooms").doc();
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

export const soUmaJoinRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const displayName = normalizeDisplayName(req.data?.displayName);
  const code = normalizeCode(req.data?.code);

  let roomId = "";

  await db.runTransaction(async (tx) => {
    const codeDoc = await tx.get(db.doc(`soUmaRoomCodes/${code}`));
    if (!codeDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }

    roomId = codeDoc.get("roomId") as string;
    const roomRef = db.doc(`soUmaRooms/${roomId}`);
    const playerRef = db.doc(`soUmaRooms/${roomId}/players/${uid}`);
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

export const soUmaLeaveRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`soUmaRooms/${roomId}`);
    const playerRef = db.doc(`soUmaRooms/${roomId}/players/${uid}`);
    const playersRef = db.collection(`soUmaRooms/${roomId}/players`);
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

export const soUmaRemovePlayer = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  const targetUid = req.data?.targetUid;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }
  if (typeof targetUid !== "string" || targetUid.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Jogador inválido");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`soUmaRooms/${roomId}`);
    const playerRef = db.doc(`soUmaRooms/${roomId}/players/${targetUid}`);
    const playersRef = db.collection(`soUmaRooms/${roomId}/players`);
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

export const soUmaStartGame = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }

  const cartasBanco = (
    require("./data/so_uma_banco.json") as {
      cartas: {id: number | string; palavras: string[]}[];
    }
  ).cartas;
  if (cartasBanco.length < CARTAS_POR_PARTIDA) {
    throw new HttpsError("internal", "Banco de cartas insuficiente");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`soUmaRooms/${roomId}`);
    const playersRef = db.collection(`soUmaRooms/${roomId}/players`);
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
      throw new HttpsError("failed-precondition", "Só uma! precisa de 3 a 7 jogadores");
    }

    const seated = shuffle(uids);
    const cartas: Carta[] = shuffle(cartasBanco)
      .slice(0, CARTAS_POR_PARTIDA)
      .map((carta) => ({id: String(carta.id), palavras: carta.palavras}));

    for (let i = 0; i < seated.length; i++) {
      tx.update(db.doc(`soUmaRooms/${roomId}/players/${seated[i]}`), {seat: i});
    }

    tx.set(db.doc(`soUmaRooms/${roomId}/secret/deck`), {
      cards: cartas,
      drawIndex: 0,
    });

    const gameId = db.collection("soUmaRooms").doc().id;
    tx.set(db.doc(`soUmaRooms/${roomId}/state/current`), {
      gameId,
      round: 0,
      guesserUid: seated[0],
      currentRoundId: null,
      phase: "drawing",
      deckRemaining: cartas.length,
      submittedCount: 0,
      expectedCount: 0,
      pistasReveladas: [],
      cartasGanhas: 0,
      historico: [],
      playerCount: seated.length,
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(roomRef, {
      status: "playing",
      playerCount: seated.length,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const soUmaChooseNumber = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  const numero = req.data?.numero;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }
  if (typeof numero !== "number" || numero < 1 || numero > 5) {
    throw new HttpsError("invalid-argument", "Escolha um número de 1 a 5");
  }

  await db.runTransaction(async (tx) => {
    const stateRef = db.doc(`soUmaRooms/${roomId}/state/current`);
    const deckRef = db.doc(`soUmaRooms/${roomId}/secret/deck`);
    const stateDoc = await tx.get(stateRef);
    const deckDoc = await tx.get(deckRef);

    if (!stateDoc.exists || !deckDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (stateDoc.get("phase") !== "drawing") {
      throw new HttpsError("failed-precondition", "Não é hora de puxar carta");
    }
    if (stateDoc.get("guesserUid") !== uid) {
      throw new HttpsError("permission-denied", "Só quem está adivinhando escolhe o número");
    }

    const cards = deckDoc.get("cards") as Carta[];
    const drawIndex = deckDoc.get("drawIndex") as number;
    if (drawIndex >= cards.length) {
      throw new HttpsError("failed-precondition", "O baralho acabou");
    }

    const carta = cards[drawIndex];
    const palavraAlvo = carta.palavras[numero - 1];
    const playerCount = stateDoc.get("playerCount") as number;
    const escritores = playerCount - 1;
    const expectedCount = escritores;

    const roundRef = db.collection(`soUmaRooms/${roomId}/rounds`).doc();
    tx.set(roundRef, {
      guesserUid: uid,
      palavras: carta.palavras,
      mysteryIndex: numero - 1,
      palavraAlvo,
      clues: [],
      createdAt: FieldValue.serverTimestamp(),
    });

    tx.update(deckRef, {drawIndex: drawIndex + 1});

    tx.update(stateRef, {
      round: (stateDoc.get("round") as number) + 1,
      currentRoundId: roundRef.id,
      phase: "writing",
      submittedCount: 0,
      expectedCount,
      deckRemaining: cards.length - (drawIndex + 1),
      pistasReveladas: [],
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const soUmaSubmitClues = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  const palavrasRaw = req.data?.palavras;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }
  if (!Array.isArray(palavrasRaw)) {
    throw new HttpsError("invalid-argument", "Pistas inválidas");
  }

  await db.runTransaction(async (tx) => {
    const stateRef = db.doc(`soUmaRooms/${roomId}/state/current`);
    const meRef = db.doc(`soUmaRooms/${roomId}/players/${uid}`);
    const stateDoc = await tx.get(stateRef);
    const meDoc = await tx.get(meRef);

    if (!stateDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (!meDoc.exists) {
      throw new HttpsError("permission-denied", "Você não está na sala");
    }
    if (stateDoc.get("phase") !== "writing") {
      throw new HttpsError("failed-precondition", "Não é hora de escrever pistas");
    }
    if (stateDoc.get("guesserUid") === uid) {
      throw new HttpsError("permission-denied", "Quem adivinha não escreve pista");
    }

    const playerCount = stateDoc.get("playerCount") as number;
    const esperadas = playerCount === 3 ? 2 : 1;
    if (palavrasRaw.length !== esperadas) {
      throw new HttpsError("invalid-argument", `Envie exatamente ${esperadas} pista(s)`);
    }
    const palavras = palavrasRaw.map((item) => normalizeWord(item, "Pista"));

    const roundId = stateDoc.get("currentRoundId") as string | null;
    if (!roundId) {
      throw new HttpsError("failed-precondition", "Rodada não encontrada");
    }
    const roundRef = db.doc(`soUmaRooms/${roomId}/rounds/${roundId}`);
    const secretRef = db.doc(`soUmaRooms/${roomId}/secret/clues_${roundId}`);
    const roundDoc = await tx.get(roundRef);
    const secretDoc = await tx.get(secretRef);

    if (!roundDoc.exists) {
      throw new HttpsError("failed-precondition", "Rodada não encontrada");
    }

    const rawClues = secretDoc.exists ? secretDoc.get("clues") : {};
    const clues: Record<string, string[]> =
      rawClues && typeof rawClues === "object" ? {...rawClues} : {};
    if (Object.prototype.hasOwnProperty.call(clues, uid)) {
      throw new HttpsError("already-exists", "Você já enviou sua pista");
    }

    clues[uid] = palavras;
    const submittedCount = Object.keys(clues).length;

    tx.set(secretRef, {clues, updatedAt: FieldValue.serverTimestamp()}, {merge: true});

    const expectedCount = stateDoc.get("expectedCount") as number;
    if (submittedCount < expectedCount) {
      tx.update(stateRef, {
        submittedCount,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const palavraAlvo = roundDoc.get("palavraAlvo") as string;
    const flatClues: Clue[] = [];
    for (const [autorUid, textos] of Object.entries(clues)) {
      textos.forEach((texto, index) => {
        flatClues.push({
          clueId: `${autorUid}_${index}`,
          autorUid,
          texto,
          anulada: false,
          motivoAutoAnulacao: null,
        });
      });
    }

    const analisadas = aplicarAnulacoes(flatClues, palavraAlvo);
    tx.update(roundRef, {clues: analisadas});
    tx.update(stateRef, {
      phase: "comparing",
      submittedCount,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const soUmaToggleClueCancel = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  const clueId = req.data?.clueId;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }
  if (typeof clueId !== "string" || clueId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Pista inválida");
  }

  await db.runTransaction(async (tx) => {
    const stateRef = db.doc(`soUmaRooms/${roomId}/state/current`);
    const stateDoc = await tx.get(stateRef);
    if (!stateDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (stateDoc.get("phase") !== "comparing") {
      throw new HttpsError("failed-precondition", "Não é hora de comparar pistas");
    }
    if (stateDoc.get("guesserUid") === uid) {
      throw new HttpsError("permission-denied", "Quem adivinha não participa da comparação");
    }

    const roundId = stateDoc.get("currentRoundId") as string | null;
    if (!roundId) {
      throw new HttpsError("failed-precondition", "Rodada não encontrada");
    }
    const roundRef = db.doc(`soUmaRooms/${roomId}/rounds/${roundId}`);
    const roundDoc = await tx.get(roundRef);
    if (!roundDoc.exists) {
      throw new HttpsError("failed-precondition", "Rodada não encontrada");
    }

    const clues = (roundDoc.get("clues") as Clue[] | undefined) ?? [];
    let encontrada = false;
    const atualizadas = clues.map((clue) => {
      if (clue.clueId !== clueId) return clue;
      encontrada = true;
      return {...clue, anulada: !clue.anulada};
    });
    if (!encontrada) {
      throw new HttpsError("not-found", "Pista não encontrada");
    }

    tx.update(roundRef, {clues: atualizadas});
  });

  return {ok: true};
});

export const soUmaFinalizeComparison = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }

  await db.runTransaction(async (tx) => {
    const stateRef = db.doc(`soUmaRooms/${roomId}/state/current`);
    const stateDoc = await tx.get(stateRef);
    if (!stateDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (stateDoc.get("phase") !== "comparing") {
      throw new HttpsError("failed-precondition", "Não é hora de finalizar a comparação");
    }
    if (stateDoc.get("guesserUid") === uid) {
      throw new HttpsError("permission-denied", "Quem adivinha não participa da comparação");
    }

    const roundId = stateDoc.get("currentRoundId") as string | null;
    if (!roundId) {
      throw new HttpsError("failed-precondition", "Rodada não encontrada");
    }
    const roundRef = db.doc(`soUmaRooms/${roomId}/rounds/${roundId}`);
    const roundDoc = await tx.get(roundRef);
    if (!roundDoc.exists) {
      throw new HttpsError("failed-precondition", "Rodada não encontrada");
    }

    const clues = (roundDoc.get("clues") as Clue[] | undefined) ?? [];
    const sobreviventes = clues.filter((clue) => !clue.anulada).map((clue) => clue.texto);

    tx.update(stateRef, {
      phase: "guessing",
      pistasReveladas: sobreviventes,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const soUmaSubmitGuess = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  const passar = req.data?.passar === true;
  const palpiteRaw = req.data?.palpite;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }
  const palpite = passar ? null : normalizeWord(palpiteRaw, "Palpite");

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`soUmaRooms/${roomId}`);
    const stateRef = db.doc(`soUmaRooms/${roomId}/state/current`);
    const deckRef = db.doc(`soUmaRooms/${roomId}/secret/deck`);
    const playersRef = db.collection(`soUmaRooms/${roomId}/players`);
    const stateDoc = await tx.get(stateRef);
    const deckDoc = await tx.get(deckRef);
    const playersSnap = await tx.get(playersRef);

    if (!stateDoc.exists || !deckDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (stateDoc.get("phase") !== "guessing") {
      throw new HttpsError("failed-precondition", "Não é hora de adivinhar");
    }
    if (stateDoc.get("guesserUid") !== uid) {
      throw new HttpsError("permission-denied", "Só quem está adivinhando pode responder");
    }

    const roundId = stateDoc.get("currentRoundId") as string | null;
    if (!roundId) {
      throw new HttpsError("failed-precondition", "Rodada não encontrada");
    }
    const roundRef = db.doc(`soUmaRooms/${roomId}/rounds/${roundId}`);
    const roundDoc = await tx.get(roundRef);
    if (!roundDoc.exists) {
      throw new HttpsError("failed-precondition", "Rodada não encontrada");
    }

    const palavraAlvo = roundDoc.get("palavraAlvo") as string;
    const palavras = roundDoc.get("palavras") as string[];
    const resultado: "acerto" | "erro" | "passou" = passar ?
      "passou" :
      (palpiteCorreto(palpite as string, palavraAlvo) ? "acerto" : "erro");

    const cards = deckDoc.get("cards") as Carta[];
    let drawIndex = deckDoc.get("drawIndex") as number;
    if (resultado === "erro" && drawIndex < cards.length) {
      drawIndex += 1;
    }
    tx.update(deckRef, {drawIndex});
    const deckRemaining = cards.length - drawIndex;

    const cartasGanhas = (stateDoc.get("cartasGanhas") as number) + (resultado === "acerto" ? 1 : 0);
    const historico = [...((stateDoc.get("historico") as HistoricoEntry[] | undefined) ?? [])];
    historico.push({
      round: stateDoc.get("round") as number,
      palavras,
      palavraAlvo,
      guesserUid: uid,
      palpite,
      resultado,
      pontos: resultado === "acerto" ? 1 : 0,
    });

    if (deckRemaining <= 0) {
      tx.update(stateRef, {
        phase: "over",
        currentRoundId: null,
        deckRemaining: 0,
        cartasGanhas,
        historico,
        pistasReveladas: [],
        updatedAt: FieldValue.serverTimestamp(),
      });
      tx.update(roomRef, {
        status: "finished",
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const seats = orderedSeats(playersSnap);
    tx.update(stateRef, {
      phase: "drawing",
      guesserUid: nextGuesserUid(seats, uid),
      currentRoundId: null,
      deckRemaining,
      cartasGanhas,
      historico,
      submittedCount: 0,
      expectedCount: 0,
      pistasReveladas: [],
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const soUmaResetRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`soUmaRooms/${roomId}`);
    const stateRef = db.doc(`soUmaRooms/${roomId}/state/current`);
    const playersRef = db.collection(`soUmaRooms/${roomId}/players`);
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

    tx.update(roomRef, {
      status: "lobby",
      playerCount: playersSnap.size,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.delete(stateRef);

    for (const player of playersSnap.docs) {
      tx.update(player.ref, {seat: null});
    }
  });

  return {ok: true};
});

export const soUmaAbortGame = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`soUmaRooms/${roomId}`);
    const stateRef = db.doc(`soUmaRooms/${roomId}/state/current`);
    const playersRef = db.collection(`soUmaRooms/${roomId}/players`);
    const roomDoc = await tx.get(roomRef);
    const playersSnap = await tx.get(playersRef);

    if (!roomDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }
    if (roomDoc.get("hostUid") !== uid) {
      throw new HttpsError("permission-denied", "Só o host pode abortar");
    }
    if (roomDoc.get("status") !== "playing") {
      throw new HttpsError("failed-precondition", "Não há partida em andamento");
    }

    tx.update(roomRef, {
      status: "lobby",
      playerCount: playersSnap.size,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.delete(stateRef);

    for (const player of playersSnap.docs) {
      tx.update(player.ref, {seat: null});
    }
  });

  return {ok: true};
});
