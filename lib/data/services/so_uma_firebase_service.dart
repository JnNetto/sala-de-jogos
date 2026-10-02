import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/so_uma_estado_remoto.dart';
import '../models/so_uma_jogador_remoto.dart';
import '../models/so_uma_rodada_remota.dart';
import '../models/so_uma_sala.dart';

class SoUmaFirebaseService {
  static const String _region = 'southamerica-east1';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  SoUmaFirebaseService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instanceFor(region: _region);

  User? get usuarioAtual => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  Future<User> garantirLoginAnonimo() async {
    if (kIsWeb) {
      await _auth.setPersistence(Persistence.SESSION);
    }

    final atual = _auth.currentUser;
    if (atual != null) return atual;

    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  Future<SoUmaSala> criarSala({required String displayName}) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaCreateRoom');
    final result = await callable.call<Map<String, dynamic>>({
      'displayName': displayName,
    });

    final data = result.data;
    final roomId = data['roomId'] as String;
    final snapshot = await _firestore.doc('soUmaRooms/$roomId').get();
    return SoUmaSala.fromMap(roomId, snapshot.data() ?? {});
  }

  Future<SoUmaSala> entrarNaSala({
    required String codigo,
    required String displayName,
  }) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaJoinRoom');
    final result = await callable.call<Map<String, dynamic>>({
      'code': codigo.trim().toUpperCase(),
      'displayName': displayName,
    });

    final data = result.data;
    final roomId = data['roomId'] as String;
    final snapshot = await _firestore.doc('soUmaRooms/$roomId').get();
    return SoUmaSala.fromMap(roomId, snapshot.data() ?? {});
  }

  Future<SoUmaSala?> obterSala(String roomId) async {
    await garantirLoginAnonimo();
    final snapshot = await _firestore.doc('soUmaRooms/$roomId').get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return SoUmaSala.fromMap(snapshot.id, data);
  }

  Stream<SoUmaSala?> observarSala(String roomId) {
    return _firestore.doc('soUmaRooms/$roomId').snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return SoUmaSala.fromMap(snapshot.id, data);
    });
  }

  Stream<List<SoUmaJogadorRemoto>> observarJogadores(String roomId) {
    return _firestore.collection('soUmaRooms/$roomId/players').snapshots().map((
      snapshot,
    ) {
      final jogadores = snapshot.docs
          .map((doc) => SoUmaJogadorRemoto.fromMap(doc.id, doc.data()))
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

  Stream<SoUmaEstadoRemoto?> observarEstado(String roomId) {
    return _firestore.doc('soUmaRooms/$roomId/state/current').snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return SoUmaEstadoRemoto.fromMap(data);
    });
  }

  Stream<SoUmaRodadaRemota?> observarRodada(String roomId, String roundId) {
    return _firestore.doc('soUmaRooms/$roomId/rounds/$roundId').snapshots().map(
      (snapshot) {
        final data = snapshot.data();
        if (!snapshot.exists || data == null) return null;
        return SoUmaRodadaRemota.fromMap(snapshot.id, data);
      },
    );
  }

  Future<void> iniciarPartida(String roomId) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaStartGame');
    await callable.call<void>({'roomId': roomId});
  }

  Future<void> escolherNumero({
    required String roomId,
    required int numero,
  }) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaChooseNumber');
    await callable.call<void>({'roomId': roomId, 'numero': numero});
  }

  Future<void> enviarPistas({
    required String roomId,
    required List<String> palavras,
  }) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaSubmitClues');
    await callable.call<void>({'roomId': roomId, 'palavras': palavras});
  }

  Future<void> alternarAnulacaoPista({
    required String roomId,
    required String clueId,
  }) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaToggleClueCancel');
    await callable.call<void>({'roomId': roomId, 'clueId': clueId});
  }

  Future<void> finalizarComparacao(String roomId) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaFinalizeComparison');
    await callable.call<void>({'roomId': roomId});
  }

  Future<void> enviarPalpite({
    required String roomId,
    String? palpite,
    bool passar = false,
  }) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaSubmitGuess');
    await callable.call<void>({
      'roomId': roomId,
      if (!passar) 'palpite': palpite,
      'passar': passar,
    });
  }

  Future<void> voltarAoLobby(String roomId) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaResetRoom');
    await callable.call<void>({'roomId': roomId});
  }

  Future<void> sairDaSala(String roomId) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaLeaveRoom');
    await callable.call<void>({'roomId': roomId});
  }

  Future<void> removerJogador({
    required String roomId,
    required String targetUid,
  }) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaRemovePlayer');
    await callable.call<void>({'roomId': roomId, 'targetUid': targetUid});
  }

  Future<void> abortarPartida(String roomId) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('soUmaAbortGame');
    await callable.call<void>({'roomId': roomId});
  }
}
