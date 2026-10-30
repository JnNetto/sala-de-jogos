import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {EXIGIR_APP_CHECK, db} from "./firebaseAdmin";
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
import {aplicarAnulacoes, palpiteCorreto, pistasPorEscritor} from "./soUmaPistas";

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

const soUmaLobby: SalaLobby = {
  rooms: "soUmaRooms",
  codes: "soUmaRoomCodes",
  maxPlayers: MAX_JOGADORES,
};

function normalizeWord(value: unknown, label: string): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${label} inválida`);
  }
  const word = limparTexto(value);
  if (word.length < 1 || word.length > 40) {
    throw new HttpsError("invalid-argument", `${label} deve ter 1 a 40 caracteres`);
  }
  return word;
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

// --- callables ---

export const soUmaCreateRoom = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
  const displayName = normalizeDisplayName(req.data?.displayName);
  return criarSala(soUmaLobby, uid, displayName);
});

export const soUmaJoinRoom = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
  const displayName = normalizeDisplayName(req.data?.displayName);
  const code = normalizeCode(req.data?.code);
  const roomId = await entrarSala(soUmaLobby, uid, displayName, code);
  return {roomId};
});

export const soUmaLeaveRoom = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
  const roomId = requireRoomId(req.data?.roomId);
  await sairSala(soUmaLobby, uid, roomId);
  return {ok: true};
});

export const soUmaRemovePlayer = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
  const roomId = requireRoomId(req.data?.roomId);
  const targetUid = requireTargetUid(req.data?.targetUid);
  await expulsarJogador(soUmaLobby, uid, roomId, targetUid);
  return {ok: true};
});

export const soUmaStartGame = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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
      throw new HttpsError("failed-precondition", "Eco! precisa de 3 a 7 jogadores");
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
      palavrasUsadas: [],
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

export const soUmaChooseNumber = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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

    // Depois de um erro, a mesma carta volta e as palavras já tentadas
    // ficam de fora.
    const usadas = (stateDoc.get("palavrasUsadas") as number[] | undefined) ?? [];
    if (usadas.includes(numero)) {
      throw new HttpsError("failed-precondition", "Essa palavra já saiu. Escolha outra.");
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

export const soUmaSubmitClues = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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
    const esperadas = pistasPorEscritor(playerCount);
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

export const soUmaToggleClueCancel = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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

export const soUmaFinalizeComparison = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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

export const soUmaSubmitGuess = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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

    // Errou: a carta volta para o topo e a mesma pessoa escolhe outra
    // palavra dela. Só quando as cinco já foram tentadas a carta se perde.
    const cards = deckDoc.get("cards") as Carta[];
    let drawIndex = deckDoc.get("drawIndex") as number;
    const tentadas = [
      ...((stateDoc.get("palavrasUsadas") as number[] | undefined) ?? []),
      (roundDoc.get("mysteryIndex") as number) + 1,
    ];
    const repete = resultado === "erro" && tentadas.length < palavras.length;
    if (repete) drawIndex -= 1;
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
        palavrasUsadas: [],
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
      guesserUid: repete ? uid : nextGuesserUid(seats, uid),
      currentRoundId: null,
      deckRemaining,
      cartasGanhas,
      historico,
      palavrasUsadas: repete ? tentadas : [],
      submittedCount: 0,
      expectedCount: 0,
      pistasReveladas: [],
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const soUmaResetRoom = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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

export const soUmaAbortGame = onCall({region, enforceAppCheck: EXIGIR_APP_CHECK}, async (req) => {
  const uid = requireConta(req.auth);
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
