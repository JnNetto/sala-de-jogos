import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'conta_service.dart';
import '../models/aneis_carta_publica.dart';
import '../models/aneis_estado_remoto.dart';
import '../models/aneis_jogador_remoto.dart';
import '../models/aneis_knower_view.dart';
import '../models/aneis_sala.dart';

class AneisFirebaseService {
  static const String _region = 'southamerica-east1';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AneisFirebaseService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instanceFor(region: _region);

  User? get usuarioAtual => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  /// As salas online só aceitam quem entrou com uma conta (não anônima).
  Future<User> exigirConta() async {
    final atual = _auth.currentUser;
    if (atual == null || atual.isAnonymous) throw const ContaNecessaria();
    return atual;
  }

  Future<AneisSala> criarSala({required String displayName}) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisCreateRoom');
    final result = await callable.call<Map<String, dynamic>>({
      'displayName': displayName,
    });

    final roomId = result.data['roomId'] as String;
    final snapshot = await _firestore.doc('aneisRooms/$roomId').get();
    return AneisSala.fromMap(roomId, snapshot.data() ?? {});
  }

  Future<AneisSala> entrarNaSala({
    required String codigo,
    required String displayName,
  }) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisJoinRoom');
    final result = await callable.call<Map<String, dynamic>>({
      'code': codigo.trim().toUpperCase(),
      'displayName': displayName,
    });

    final roomId = result.data['roomId'] as String;
    final snapshot = await _firestore.doc('aneisRooms/$roomId').get();
    return AneisSala.fromMap(roomId, snapshot.data() ?? {});
  }

  Future<AneisSala?> obterSala(String roomId) async {
    await exigirConta();
    final snapshot = await _firestore.doc('aneisRooms/$roomId').get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return AneisSala.fromMap(snapshot.id, data);
  }

  Stream<AneisSala?> observarSala(String roomId) {
    return _firestore.doc('aneisRooms/$roomId').snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return AneisSala.fromMap(snapshot.id, data);
    });
  }

  Stream<List<AneisJogadorRemoto>> observarJogadores(String roomId) {
    return _firestore.collection('aneisRooms/$roomId/players').snapshots().map((
      snapshot,
    ) {
      final jogadores = snapshot.docs
          .map((doc) => AneisJogadorRemoto.fromMap(doc.id, doc.data()))
          .toList();
      jogadores.sort((a, b) {
        final seatA = a.seat;
        final seatB = b.seat;
        if (seatA != null && seatB != null) return seatA.compareTo(seatB);
        if (seatA != null) return -1;
        if (seatB != null) return 1;
        return a.displayName.compareTo(b.displayName);
      });
      return jogadores;
    });
  }

  Stream<AneisEstadoRemoto?> observarEstado(String roomId) {
    return _firestore.doc('aneisRooms/$roomId/state/current').snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return AneisEstadoRemoto.fromMap(data);
    });
  }

  Stream<List<AneisCartaPublica>> observarMao(String roomId, String uid) {
    return _firestore.doc('aneisRooms/$roomId/hands/$uid').snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return const [];
      return (data['coisas'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AneisCartaPublica.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    });
  }

  Stream<AneisKnowerView?> observarVisaoKnower(String roomId) {
    return _firestore
        .doc('aneisRooms/$roomId/knower/view')
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) return null;
          return AneisKnowerView.fromMap(data);
        })
        .handleError((Object _, StackTrace __) {});
  }

  Future<void> iniciarPartida({
    required String roomId,
    required String dificuldade,
    required String knowerMode,
    String? knowerUid,
  }) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisStartGame');
    await callable.call<void>({
      'roomId': roomId,
      'dificuldade': dificuldade,
      'knowerMode': knowerMode,
      if (knowerUid != null) 'knowerUid': knowerUid,
    });
  }

  Future<void> posicionarCarta({
    required String roomId,
    required String coisaId,
    required String regiao,
  }) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisPlaceThing');
    await callable.call<void>({
      'roomId': roomId,
      'coisaId': coisaId,
      'regiao': regiao,
    });
  }

  Future<void> julgarPosicao({
    required String roomId,
    required String regiao,
  }) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisJudgePlacement');
    await callable.call<void>({'roomId': roomId, 'regiao': regiao});
  }

  Future<void> desvendarRegra({
    required String roomId,
    required String anel,
    required String palpite,
  }) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisGuessRule');
    await callable.call<void>({
      'roomId': roomId,
      'anel': anel,
      'palpite': palpite,
    });
  }

  Future<void> julgarRegra({
    required String roomId,
    required bool acertou,
  }) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisJudgeRule');
    await callable.call<void>({'roomId': roomId, 'acertou': acertou});
  }

  Future<void> desfazerJulgamento(String roomId) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisUndoJudge');
    await callable.call<void>({'roomId': roomId});
  }

  Future<void> voltarAoLobby(String roomId) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisResetRoom');
    await callable.call<void>({'roomId': roomId});
  }

  Future<void> sairDaSala(String roomId) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisLeaveRoom');
    await callable.call<void>({'roomId': roomId});
  }

  Future<void> removerJogador({
    required String roomId,
    required String targetUid,
  }) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisRemovePlayer');
    await callable.call<void>({'roomId': roomId, 'targetUid': targetUid});
  }

  Future<void> abortarPartida(String roomId) async {
    await exigirConta();
    final callable = _functions.httpsCallable('aneisAbortGame');
    await callable.call<void>({'roomId': roomId});
  }
}
