import type {DocumentSnapshot} from "firebase-admin/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {db} from "./firebaseAdmin";

const region = "southamerica-east1";

/** Sem movimento por esse tempo, ninguém está mais jogando ali. */
const ABANDONO_MS = 2 * 60 * 60 * 1000;
const POR_RODADA = 200;

const SALAS = [
  {rooms: "rooms", codes: "roomCodes"},
  {rooms: "soUmaRooms", codes: "soUmaRoomCodes"},
  {rooms: "aneisRooms", codes: "aneisRoomCodes"},
];

function ultimoMovimento(doc: DocumentSnapshot): number {
  const quando = doc.get("updatedAt") as FirebaseFirestore.Timestamp | undefined;
  return quando?.toMillis() ?? 0;
}

async function apagar(sala: DocumentSnapshot, codes: string): Promise<void> {
  const code = sala.get("code") as string | undefined;
  await db.recursiveDelete(sala.ref);
  if (!code) return;
  const codeRef = db.doc(`${codes}/${code}`);
  const codeDoc = await codeRef.get();
  if (codeDoc.exists && codeDoc.get("roomId") === sala.id) {
    await codeRef.delete();
  }
}

/**
 * A cada meia hora, apaga as salas vazias e as sem movimento há duas horas
 * (nem na sala, nem na partida): o documento, tudo dentro dele e o código.
 */
export const limparSalasAbandonadas = onSchedule(
  {schedule: "every 30 minutes", timeZone: "America/Sao_Paulo", region},
  async () => {
    const limite = Date.now() - ABANDONO_MS;
    for (const {rooms, codes} of SALAS) {
      const vazias = await db.collection(rooms)
        .where("playerCount", "==", 0)
        .limit(POR_RODADA)
        .get();
      for (const sala of vazias.docs) {
        await apagar(sala, codes);
      }

      const paradas = await db.collection(rooms)
        .where("updatedAt", "<", new Date(limite))
        .limit(POR_RODADA)
        .get();
      for (const sala of paradas.docs) {
        // As jogadas mexem no estado da partida, não no documento da sala.
        const estado = await sala.ref.collection("state").doc("current").get();
        if (estado.exists && ultimoMovimento(estado) >= limite) continue;
        await apagar(sala, codes);
      }
    }
  },
);
