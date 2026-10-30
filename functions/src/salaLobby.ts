import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "./firebaseAdmin";
import {
  createRoomCode,
  entradaBloqueada,
  hostDepoisDeSair,
  type SalaLobby,
} from "./salaLobbyRegras";

export {
  createRoomCode,
  entradaBloqueada,
  hostDepoisDeSair,
  limparTexto,
  normalizeCode,
  normalizeDisplayName,
  requireConta,
  requireRoomId,
  requireTargetUid,
  requireUid,
  shuffle,
  type SalaLobby,
} from "./salaLobbyRegras";

export async function criarSala(
  lobby: SalaLobby,
  uid: string,
  displayName: string,
): Promise<{roomId: string; code: string}> {
  for (let attempt = 0; attempt < 8; attempt++) {
    const code = createRoomCode();
    const codeRef = db.doc(`${lobby.codes}/${code}`);
    const roomRef = db.collection(lobby.rooms).doc();
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
          ...lobby.roomExtra,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        tx.set(playerRef, {
          uid,
          displayName,
          seat: null,
          ...lobby.playerExtra,
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
}

export async function entrarSala(
  lobby: SalaLobby,
  uid: string,
  displayName: string,
  code: string,
): Promise<string> {
  let roomId = "";

  await db.runTransaction(async (tx) => {
    const codeDoc = await tx.get(db.doc(`${lobby.codes}/${code}`));
    if (!codeDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }

    roomId = codeDoc.get("roomId") as string;
    const roomRef = db.doc(`${lobby.rooms}/${roomId}`);
    const playerRef = db.doc(`${lobby.rooms}/${roomId}/players/${uid}`);
    const roomDoc = await tx.get(roomRef);
    const playerDoc = await tx.get(playerRef);

    if (!roomDoc.exists) {
      throw new HttpsError("not-found", "Sala não encontrada");
    }
    if (roomDoc.get("status") !== "lobby") {
      throw new HttpsError("failed-precondition", "Partida já iniciada");
    }
    if (entradaBloqueada(
      playerDoc.exists,
      roomDoc.get("playerCount") as number,
      lobby.maxPlayers,
    )) {
      throw new HttpsError("failed-precondition", "Sala cheia");
    }

    tx.set(playerRef, {
      uid,
      displayName,
      seat: null,
      ...lobby.playerExtra,
      joinedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    if (!playerDoc.exists) {
      tx.update(roomRef, {
        playerCount: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });

  return roomId;
}

export async function sairSala(
  lobby: SalaLobby,
  uid: string,
  roomId: string,
): Promise<void> {
  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`${lobby.rooms}/${roomId}`);
    const playerRef = db.doc(`${lobby.rooms}/${roomId}/players/${uid}`);
    const playersRef = db.collection(`${lobby.rooms}/${roomId}/players`);
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

    const remaining = playersSnap.docs
      .filter((doc) => doc.id !== uid)
      .map((doc) => doc.id);
    tx.delete(playerRef);

    const hostUid = hostDepoisDeSair(
      roomDoc.get("hostUid") as string,
      uid,
      remaining,
    );
    if (hostUid === null) {
      tx.update(roomRef, {
        playerCount: 0,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    tx.update(roomRef, {
      hostUid,
      playerCount: remaining.length,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

export async function expulsarJogador(
  lobby: SalaLobby,
  uid: string,
  roomId: string,
  targetUid: string,
): Promise<void> {
  await db.runTransaction(async (tx) => {
    const roomRef = db.doc(`${lobby.rooms}/${roomId}`);
    const playerRef = db.doc(`${lobby.rooms}/${roomId}/players/${targetUid}`);
    const playersRef = db.collection(`${lobby.rooms}/${roomId}/players`);
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
}
