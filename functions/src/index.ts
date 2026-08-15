import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const region = "southamerica-east1";
const spyCount: Record<number, number> = {
  5: 2,
  6: 2,
  7: 3,
  8: 3,
  9: 3,
  10: 4,
};
const teamSizes: Record<number, number[]> = {
  5: [2, 3, 2, 3, 3],
  6: [2, 3, 4, 3, 4],
  7: [2, 3, 3, 4, 4],
  8: [3, 4, 4, 5, 5],
  9: [3, 4, 4, 5, 5],
  10: [3, 4, 4, 5, 5],
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

function failsRequired(round: number, playerCount: number): number {
  return round === 4 && playerCount >= 7 ? 2 : 1;
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

  for (let attempt = 0; attempt < 8; attempt++) {
    const code = createRoomCode();
    const codeRef = db.doc(`roomCodes/${code}`);
    const roomRef = db.collection("rooms").doc();
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
          settings: {
            variant: "basic",
            fiveRejectsRule: "spiesWin",
          },
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

export const joinRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const displayName = normalizeDisplayName(req.data?.displayName);
  const code = normalizeCode(req.data?.code);

  let roomId = "";

  await db.runTransaction(async (tx) => {
    const codeDoc = await tx.get(db.doc(`roomCodes/${code}`));
    if (!codeDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }

    roomId = codeDoc.get("roomId") as string;
    const roomRef = db.doc(`rooms/${roomId}`);
    const playerRef = db.doc(`rooms/${roomId}/players/${uid}`);
    const roomDoc = await tx.get(roomRef);
    const playerDoc = await tx.get(playerRef);

    if (!roomDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }
    if (roomDoc.get("status") !== "lobby") {
      throw new HttpsError("failed-precondition", "Partida já iniciada");
    }
    if (!playerDoc.exists && (roomDoc.get("playerCount") as number) >= 10) {
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

export const leaveRoom = onCall({region}, async (req) => {
  const uid = requireUid(req.auth?.uid);
  const roomId = req.data?.roomId;
  if (typeof roomId !== "string" || roomId.trim().length < 1) {
    throw new HttpsError("invalid-argument", "Sala inválida");
  }

  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`rooms/${roomId}`);
    const playerRef = db.doc(`rooms/${roomId}/players/${uid}`);
    const playersRef = db.collection(`rooms/${roomId}/players`);
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

export const removePlayer = onCall({region}, async (req) => {
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
    const roomRef = db.doc(`rooms/${roomId}`);
    const playerRef = db.doc(`rooms/${roomId}/players/${targetUid}`);
    const playersRef = db.collection(`rooms/${roomId}/players`);
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
      teamSize: teamSizes[seated.length][0],
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

    const approvals = Object.values(votes).filter(Boolean).length;
    const approved = approvals > totalPlayers / 2;
    tx.update(proposalRef, {
      status: approved ? "approved" : "rejected",
      votes,
      revealedAt: FieldValue.serverTimestamp(),
    });

    if (approved) {
      tx.update(stateRef, {
        phase: "mission",
        lastProposalId: proposalId,
        submittedCount: 0,
        expectedCount: stateDoc.get("teamSize"),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const nextAttempt = (stateDoc.get("attempt") as number) + 1;
    if (nextAttempt > 5) {
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
      attempt: nextAttempt,
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
    const secretRef = db.doc(`rooms/${roomId}/secret/mission_${stateDoc.get("round")}`);
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
    cards[uid] = team === "good" ? true : success;
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
    const failCount = Object.values(cards).filter((card) => !card).length;
    const missionSucceeded = failCount < failsRequired(round, playerCount);
    const missionResults = [
      ...((stateDoc.get("missionResults") as boolean[]) ?? []),
      missionSucceeded,
    ];
    const failCounts = [
      ...((stateDoc.get("failCounts") as number[]) ?? []),
      failCount,
    ];
    const successes = missionResults.filter(Boolean).length;
    const failures = missionResults.filter((result) => !result).length;

    if (successes >= 3 || failures >= 3) {
      writeReveals(tx, roomId, reveals);
      tx.update(stateRef, {
        phase: "over",
        missionResults,
        failCounts,
        submittedCount: 0,
        expectedCount: 0,
        winner: successes >= 3 ? "resistance" : "spies",
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
      teamSize: teamSizes[playerCount][nextRound - 1],
      missionResults,
      failCounts,
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
