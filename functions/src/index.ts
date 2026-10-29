import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {db} from "./firebaseAdmin";
import {
  legalMissionCard,
  missionSecretId,
  resolveMission,
  resolveVote,
  teamSizeFor,
} from "./resistenciaTurno";
import {
  criarSala,
  entrarSala,
  expulsarJogador,
  normalizeCode,
  normalizeDisplayName,
  requireRoomId,
  requireTargetUid,
  requireUid,
  sairSala,
  shuffle,
  type SalaLobby,
} from "./salaLobby";

export * from "./soUma";
export * from "./aneis";

const region = "southamerica-east1";
const spyCount: Record<number, number> = {
  5: 2,
  6: 2,
  7: 3,
  8: 3,
  9: 3,
  10: 4,
};
type Assignment = {
  uid: string;
  seat: number;
  role: "resistance" | "spy";
  team: "good" | "evil";
};

type PlayerSeat = {
  uid: string;
  seat: number;
};

type Reveal = {
  uid: string;
  role: string;
  team: string;
};

const resistenciaLobby: SalaLobby = {
  rooms: "rooms",
  codes: "roomCodes",
  maxPlayers: 10,
  roomExtra: {
    settings: {
      variant: "basic",
      fiveRejectsRule: "spiesWin",
    },
  },
};

function buildBasicRoles(playerCount: number): Array<Pick<Assignment, "role" | "team">> {
  const spies = spyCount[playerCount];
  if (!spies) {
    throw new HttpsError("failed-precondition", "A partida precisa de 5 a 10 jogadores");
  }
  const good = playerCount - spies;
  return [
    ...Array(good).fill({role: "resistance", team: "good"}),
    ...Array(spies).fill({role: "spy", team: "evil"}),
  ];
}

function computeKnowledge(assignments: Assignment[]): Map<string, Array<{uid: string; label: string}>> {
  const map = new Map<string, Array<{uid: string; label: string}>>();
  for (const me of assignments) {
    const seen: Array<{uid: string; label: string}> = [];
    if (me.role === "spy") {
      for (const other of assignments) {
        if (other.uid !== me.uid && other.role === "spy") {
          seen.push({uid: other.uid, label: "espião"});
        }
      }
    }
    map.set(me.uid, shuffle(seen));
  }
  return map;
}

function orderedSeats(
  players: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>,
): PlayerSeat[] {
  return players.docs
    .map((doc) => ({uid: doc.id, seat: doc.get("seat") as number | null}))
    .filter((player): player is PlayerSeat => typeof player.seat === "number")
    .sort((a, b) => a.seat - b.seat);
}

function nextLeaderUid(players: PlayerSeat[], leaderUid: string): string {
  const currentIndex = players.findIndex((player) => player.uid === leaderUid);
  if (currentIndex < 0 || players.length === 0) {
    throw new HttpsError("failed-precondition", "Líder inválido");
  }
  return players[(currentIndex + 1) % players.length].uid;
}

async function readReveals(
  tx: FirebaseFirestore.Transaction,
  roomId: string,
  players: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>,
): Promise<Reveal[]> {
  const reveals: Reveal[] = [];
  for (const player of players.docs) {
    const privateDoc = await tx.get(db.doc(`rooms/${roomId}/private/${player.id}`));
    if (privateDoc.exists) {
      reveals.push({
        uid: player.id,
        role: privateDoc.get("role") as string,
        team: privateDoc.get("team") as string,
      });
    }
  }
  return reveals;
}

function writeReveals(
  tx: FirebaseFirestore.Transaction,
  roomId: string,
  reveals: Reveal[],
): void {
  for (const reveal of reveals) {
    tx.update(db.doc(`rooms/${roomId}/players/${reveal.uid}`), {
      revealedRole: reveal.role,
      revealedTeam: reveal.team,
    });
  }
}

export const createRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const displayName = normalizeDisplayName(req.data?.displayName);
  return criarSala(resistenciaLobby, uid, displayName);
});

export const joinRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const displayName = normalizeDisplayName(req.data?.displayName);
  const code = normalizeCode(req.data?.code);
  const roomId = await entrarSala(resistenciaLobby, uid, displayName, code);
  return {roomId};
});

export const leaveRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = requireRoomId(req.data?.roomId);
  await sairSala(resistenciaLobby, uid, roomId);
  return {ok: true};
});

export const removePlayer = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = requireRoomId(req.data?.roomId);
  const targetUid = requireTargetUid(req.data?.targetUid);
  await expulsarJogador(resistenciaLobby, uid, roomId, targetUid);
  return {ok: true};
});

export const startGame = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`rooms/${roomId}`);
    const playersRef = db.collection(`rooms/${roomId}/players`);
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
    if (uids.length < 5 || uids.length > 10) {
      throw new HttpsError("failed-precondition", "A partida precisa de 5 a 10 jogadores");
    }

    const seated = shuffle(uids);
    const roles = shuffle(buildBasicRoles(seated.length));
    const gameId = db.collection("rooms").doc().id;
    const assignments: Assignment[] = seated.map((playerUid, index) => ({
      uid: playerUid,
      seat: index,
      role: roles[index].role,
      team: roles[index].team,
    }));
    const knowledge = computeKnowledge(assignments);

    for (const assignment of assignments) {
      tx.update(db.doc(`rooms/${roomId}/players/${assignment.uid}`), {
        seat: assignment.seat,
      });
      tx.set(db.doc(`rooms/${roomId}/private/${assignment.uid}`), {
        role: assignment.role,
        team: assignment.team,
        knowledge: knowledge.get(assignment.uid) ?? [],
      });
    }

    tx.set(db.doc(`rooms/${roomId}/state/current`), {
      gameId,
      phase: "proposing",
      round: 1,
      attempt: 1,
      leaderUid: assignments[0].uid,
      teamSize: teamSizeFor(seated.length, 1),
      missionResults: [],
      failCounts: [],
      currentProposalId: null,
      lastProposalId: null,
      submittedCount: 0,
      expectedCount: 0,
      winner: null,
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

export const proposeTeam = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  const memberUids = req.data?.memberUids;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }
  if (!Array.isArray(memberUids) || !memberUids.every((item) => typeof item === "string")) {
    throw new HttpsError("invalid-argument", "Equipe inválida");
  }

  await db.runTransaction(async (tx) => {
    const stateRef = db.doc(`rooms/${roomId}/state/current`);
    const playersRef = db.collection(`rooms/${roomId}/players`);
    const meRef = db.doc(`rooms/${roomId}/players/${uid}`);
    const stateDoc = await tx.get(stateRef);
    const playersSnap = await tx.get(playersRef);
    const meDoc = await tx.get(meRef);

    if (!stateDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (!meDoc.exists) {
      throw new HttpsError("permission-denied", "Você não está na sala");
    }
    if (stateDoc.get("phase") !== "proposing") {
      throw new HttpsError("failed-precondition", "Não é hora de propor equipe");
    }
    if (stateDoc.get("leaderUid") !== uid) {
      throw new HttpsError("permission-denied", "Só o líder pode propor");
    }

    const teamSize = stateDoc.get("teamSize") as number;
    const uniqueMemberUids = [...new Set(memberUids)];
    if (uniqueMemberUids.length !== memberUids.length || memberUids.length !== teamSize) {
      throw new HttpsError("invalid-argument", `Selecione exatamente ${teamSize} jogadores`);
    }

    const playerIds = new Set(playersSnap.docs.map((doc) => doc.id));
    for (const memberUid of memberUids) {
      if (!playerIds.has(memberUid)) {
        throw new HttpsError("invalid-argument", "Equipe contém jogador inválido");
      }
    }

    const proposalRef = db.collection(`rooms/${roomId}/proposals`).doc();
    tx.set(proposalRef, {
      round: stateDoc.get("round"),
      attempt: stateDoc.get("attempt"),
      leaderUid: uid,
      memberUids,
      status: "voting",
      votes: null,
      revealedAt: null,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(stateRef, {
      phase: "voting",
      currentProposalId: proposalRef.id,
      lastProposalId: null,
      submittedCount: 0,
      expectedCount: stateDoc.get("playerCount"),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const castVote = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  const approve = req.data?.approve;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }
  if (typeof approve !== "boolean") {
    throw new HttpsError("invalid-argument", "Voto inválido");
  }

  await db.runTransaction(async (tx) => {
    const stateRef = db.doc(`rooms/${roomId}/state/current`);
    const playersRef = db.collection(`rooms/${roomId}/players`);
    const meRef = db.doc(`rooms/${roomId}/players/${uid}`);
    const stateDoc = await tx.get(stateRef);
    const playersSnap = await tx.get(playersRef);
    const meDoc = await tx.get(meRef);

    if (!stateDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (!meDoc.exists) {
      throw new HttpsError("permission-denied", "Você não está na sala");
    }
    if (stateDoc.get("phase") !== "voting") {
      throw new HttpsError("failed-precondition", "Não é hora de votar");
    }

    const proposalId = stateDoc.get("currentProposalId") as string | null;
    if (!proposalId) {
      throw new HttpsError("failed-precondition", "Proposta não encontrada");
    }

    const proposalRef = db.doc(`rooms/${roomId}/proposals/${proposalId}`);
    const secretRef = db.doc(`rooms/${roomId}/secret/votes_${proposalId}`);
    const proposalDoc = await tx.get(proposalRef);
    const secretDoc = await tx.get(secretRef);
    const reveals = await readReveals(tx, roomId, playersSnap);

    if (!proposalDoc.exists || proposalDoc.get("status") !== "voting") {
      throw new HttpsError("failed-precondition", "Proposta não está em votação");
    }

    const rawVotes = secretDoc.exists ? secretDoc.get("votes") : {};
    const votes: Record<string, boolean> =
      rawVotes && typeof rawVotes === "object" ? {...rawVotes} : {};
    if (Object.prototype.hasOwnProperty.call(votes, uid)) {
      throw new HttpsError("already-exists", "Você já votou");
    }

    votes[uid] = approve;
    const totalPlayers = stateDoc.get("playerCount") as number;
    const submittedCount = Object.keys(votes).length;

    tx.set(secretRef, {
      votes,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    if (submittedCount < totalPlayers) {
      tx.update(stateRef, {
        submittedCount,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const resolution = resolveVote({
      votes,
      totalPlayers,
      attempt: stateDoc.get("attempt") as number,
    });
    tx.update(proposalRef, {
      status: resolution.outcome === "mission" ? "approved" : "rejected",
      votes,
      revealedAt: FieldValue.serverTimestamp(),
    });

    if (resolution.outcome === "mission") {
      tx.update(stateRef, {
        phase: "mission",
        lastProposalId: proposalId,
        submittedCount: 0,
        expectedCount: stateDoc.get("teamSize"),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    if (resolution.outcome === "spies") {
      writeReveals(tx, roomId, reveals);
      tx.update(stateRef, {
        phase: "over",
        lastProposalId: proposalId,
        submittedCount: 0,
        expectedCount: 0,
        winner: "spies",
        updatedAt: FieldValue.serverTimestamp(),
      });
      tx.update(db.doc(`rooms/${roomId}`), {
        status: "finished",
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const seats = orderedSeats(playersSnap);
    if (seats.length !== totalPlayers) {
      throw new HttpsError("failed-precondition", "Jogadores sem assento");
    }

    tx.update(stateRef, {
      phase: "proposing",
      attempt: resolution.nextAttempt,
      leaderUid: nextLeaderUid(seats, stateDoc.get("leaderUid") as string),
      currentProposalId: null,
      lastProposalId: proposalId,
      submittedCount: 0,
      expectedCount: 0,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const playMissionCard = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  const success = req.data?.success;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }
  if (typeof success !== "boolean") {
    throw new HttpsError("invalid-argument", "Carta inválida");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`rooms/${roomId}`);
    const stateRef = db.doc(`rooms/${roomId}/state/current`);
    const playersRef = db.collection(`rooms/${roomId}/players`);
    const meRef = db.doc(`rooms/${roomId}/players/${uid}`);
    const privateRef = db.doc(`rooms/${roomId}/private/${uid}`);
    const stateDoc = await tx.get(stateRef);
    const playersSnap = await tx.get(playersRef);
    const meDoc = await tx.get(meRef);
    const privateDoc = await tx.get(privateRef);

    if (!stateDoc.exists) {
      throw new HttpsError("failed-precondition", "Partida não iniciada");
    }
    if (!meDoc.exists || !privateDoc.exists) {
      throw new HttpsError("permission-denied", "Você não está na sala");
    }
    if (stateDoc.get("phase") !== "mission") {
      throw new HttpsError("failed-precondition", "Não é hora da missão");
    }

    const proposalId = stateDoc.get("currentProposalId") as string | null;
    if (!proposalId) {
      throw new HttpsError("failed-precondition", "Proposta não encontrada");
    }

    const proposalRef = db.doc(`rooms/${roomId}/proposals/${proposalId}`);
    // A proposal ID is unique across rounds and reused-room games. Using only
    // the round here caused cards from an earlier game to be counted again.
    const secretRef = db.doc(
      `rooms/${roomId}/secret/${missionSecretId(proposalId)}`,
    );
    const proposalDoc = await tx.get(proposalRef);
    const secretDoc = await tx.get(secretRef);
    const reveals = await readReveals(tx, roomId, playersSnap);

    if (!proposalDoc.exists || proposalDoc.get("status") !== "approved") {
      throw new HttpsError("failed-precondition", "Equipe não aprovada");
    }

    const memberUids = proposalDoc.get("memberUids") as string[];
    if (!memberUids.includes(uid)) {
      throw new HttpsError("permission-denied", "Você não está nesta missão");
    }

    const rawCards = secretDoc.exists ? secretDoc.get("cards") : {};
    const cards: Record<string, boolean> =
      rawCards && typeof rawCards === "object" ? {...rawCards} : {};
    if (Object.prototype.hasOwnProperty.call(cards, uid)) {
      throw new HttpsError("already-exists", "Você já jogou sua carta");
    }

    const team = privateDoc.get("team") as string;
    cards[uid] = legalMissionCard(team, success);
    const submittedCount = Object.keys(cards).length;

    tx.set(secretRef, {
      cards,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    if (submittedCount < memberUids.length) {
      tx.update(stateRef, {
        submittedCount,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const round = stateDoc.get("round") as number;
    const playerCount = stateDoc.get("playerCount") as number;
    const resolved = resolveMission({
      cards,
      round,
      playerCount,
      missionResults: (stateDoc.get("missionResults") as boolean[]) ?? [],
      failCounts: (stateDoc.get("failCounts") as number[]) ?? [],
    });

    if (resolved.over) {
      writeReveals(tx, roomId, reveals);
      tx.update(stateRef, {
        phase: "over",
        missionResults: resolved.missionResults,
        failCounts: resolved.failCounts,
        submittedCount: 0,
        expectedCount: 0,
        winner: resolved.winner,
        updatedAt: FieldValue.serverTimestamp(),
      });
      tx.update(roomRef, {
        status: "finished",
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const seats = orderedSeats(playersSnap);
    if (seats.length !== playerCount) {
      throw new HttpsError("failed-precondition", "Jogadores sem assento");
    }
    const nextRound = round + 1;

    tx.update(stateRef, {
      phase: "proposing",
      round: nextRound,
      attempt: 1,
      leaderUid: nextLeaderUid(seats, stateDoc.get("leaderUid") as string),
      teamSize: teamSizeFor(playerCount, nextRound),
      missionResults: resolved.missionResults,
      failCounts: resolved.failCounts,
      currentProposalId: null,
      submittedCount: 0,
      expectedCount: 0,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

export const abortGame = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`rooms/${roomId}`);
    const stateRef = db.doc(`rooms/${roomId}/state/current`);
    const playersRef = db.collection(`rooms/${roomId}/players`);
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

    const privateDocs = [];
    for (const player of playersSnap.docs) {
      privateDocs.push(await tx.get(db.doc(`rooms/${roomId}/private/${player.id}`)));
    }

    tx.update(roomRef, {
      status: "lobby",
      playerCount: playersSnap.size,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.delete(stateRef);

    for (let i = 0; i < playersSnap.docs.length; i++) {
      tx.update(playersSnap.docs[i].ref, {
        seat: null,
        revealedRole: FieldValue.delete(),
        revealedTeam: FieldValue.delete(),
      });
      if (privateDocs[i].exists) {
        tx.delete(privateDocs[i].ref);
      }
    }
  });

  return {ok: true};
});

export const resetRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`rooms/${roomId}`);
    const stateRef = db.doc(`rooms/${roomId}/state/current`);
    const playersRef = db.collection(`rooms/${roomId}/players`);
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

    const privateDocs = [];
    for (const player of playersSnap.docs) {
      privateDocs.push(await tx.get(db.doc(`rooms/${roomId}/private/${player.id}`)));
    }

    tx.update(roomRef, {
      status: "lobby",
      playerCount: playersSnap.size,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.delete(stateRef);

    for (let i = 0; i < playersSnap.docs.length; i++) {
      const player = playersSnap.docs[i];
      tx.update(player.ref, {
        seat: null,
        revealedRole: FieldValue.delete(),
        revealedTeam: FieldValue.delete(),
      });
      if (privateDocs[i].exists) {
        tx.delete(privateDocs[i].ref);
      }
    }
  });

  return {ok: true};
});
