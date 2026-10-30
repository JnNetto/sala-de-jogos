import {getAuth} from "firebase-admin/auth";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {EXIGIR_APP_CHECK, db} from "./firebaseAdmin";
import {requireUid, sairSala, type SalaLobby} from "./salaLobby";

const region = "southamerica-east1";

/** O apelido que fica no lugar do de quem excluiu a conta. */
export const NOME_EXCLUIDO = "Conta excluída";

const SALAS: Record<string, SalaLobby> = {
  rooms: {rooms: "rooms", codes: "roomCodes", maxPlayers: 10},
  soUmaRooms: {rooms: "soUmaRooms", codes: "soUmaRoomCodes", maxPlayers: 7},
  aneisRooms: {rooms: "aneisRooms", codes: "aneisRoomCodes", maxPlayers: 6},
};

/**
 * Exclui a conta de quem chama e os dados dela nas salas:
 * - nas salas em lobby, a pessoa sai (o host passa adiante, se for o caso);
 * - nas partidas em andamento, o apelido vira "Conta excluída" (a partida
 *   e tudo dela somem pela limpeza das salas paradas, em até 2 horas);
 * - por fim, a conta é apagada do Firebase Auth.
 */
export const excluirConta = onCall(
  {region, enforceAppCheck: EXIGIR_APP_CHECK},
  async (req) => {
    const uid = requireUid(req.auth?.uid);

    const presencas = await db.collectionGroup("players")
      .where("uid", "==", uid)
      .get();
    for (const jogador of presencas.docs) {
      const sala = jogador.ref.parent.parent;
      const lobby = sala ? SALAS[sala.parent.id] : undefined;
      if (!sala || !lobby) continue;
      const salaDoc = await sala.get();
      if (salaDoc.exists && salaDoc.get("status") === "lobby") {
        try {
          await sairSala(lobby, uid, sala.id);
          continue;
        } catch {
          // Se não der para sair (corrida com o início da partida), cai no
          // caminho de baixo e o apelido é apagado.
        }
      }
      await jogador.ref.update({displayName: NOME_EXCLUIDO}).catch(() => undefined);
    }

    try {
      await getAuth().deleteUser(uid);
    } catch (erro) {
      const codigo = (erro as {code?: string}).code;
      if (codigo !== "auth/user-not-found") {
        throw new HttpsError("internal", "Não deu para excluir a conta agora");
      }
    }
    return {ok: true};
  },
);
