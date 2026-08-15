import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/resistencia_jogador_remoto.dart';
import '../models/resistencia_estado_remoto.dart';
import '../models/resistencia_privado.dart';
import '../models/resistencia_proposta_remota.dart';
import '../models/resistencia_sala.dart';

class ResistenciaFirebaseService {
  static const String _region = 'southamerica-east1';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  ResistenciaFirebaseService({
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

  Future<ResistenciaSala> criarSala({required String displayName}) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('createRoom');
    final result = await callable.call<Map<String, dynamic>>({
      'displayName': displayName,
    });

    final data = result.data;
    final roomId = data['roomId'] as String;
    final snapshot = await _firestore.doc('rooms/$roomId').get();
    return ResistenciaSala.fromMap(roomId, snapshot.data() ?? {});
  }

  Future<ResistenciaSala> entrarNaSala({
    required String codigo,
    required String displayName,
  }) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('joinRoom');
    final result = await callable.call<Map<String, dynamic>>({
      'code': codigo.trim().toUpperCase(),
      'displayName': displayName,
    });

    final data = result.data;
    final roomId = data['roomId'] as String;
    final snapshot = await _firestore.doc('rooms/$roomId').get();
    return ResistenciaSala.fromMap(roomId, snapshot.data() ?? {});
  }

  Future<ResistenciaSala?> obterSala(String roomId) async {
    await garantirLoginAnonimo();
    final snapshot = await _firestore.doc('rooms/$roomId').get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return ResistenciaSala.fromMap(snapshot.id, data);
  }

  Stream<ResistenciaSala?> observarSala(String roomId) {
    return _firestore.doc('rooms/$roomId').snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return ResistenciaSala.fromMap(snapshot.id, data);
    });
  }

  Stream<List<ResistenciaJogadorRemoto>> observarJogadores(String roomId) {
    return _firestore.collection('rooms/$roomId/players').snapshots().map((
      snapshot,
    ) {
      final jogadores = snapshot.docs
          .map((doc) => ResistenciaJogadorRemoto.fromMap(doc.id, doc.data()))
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

  Stream<ResistenciaPrivado?> observarMeuPrivado(String roomId) {
    final currentUid = uid;
    if (currentUid == null) return Stream.value(null);
    return _firestore.doc('rooms/$roomId/private/$currentUid').snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return ResistenciaPrivado.fromMap(data);
    });
  }

  Stream<ResistenciaEstadoRemoto?> observarEstado(String roomId) {
    return _firestore.doc('rooms/$roomId/state/current').snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return ResistenciaEstadoRemoto.fromMap(data);
    });
  }

  Stream<ResistenciaPropostaRemota?> observarProposta(
    String roomId,
    String proposalId,
  ) {
    return _firestore
        .doc('rooms/$roomId/proposals/$proposalId')
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) return null;
          return ResistenciaPropostaRemota.fromMap(snapshot.id, data);
        });
  }

  Future<void> iniciarPartida(String roomId) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('startGame');
    await callable.call<void>({'roomId': roomId});
  }

  Future<void> proporEquipe({
    required String roomId,
    required List<String> memberUids,
  }) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('proposeTeam');
    await callable.call<void>({'roomId': roomId, 'memberUids': memberUids});
  }

  Future<void> votarProposta({
    required String roomId,
    required bool approve,
  }) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('castVote');
    await callable.call<void>({'roomId': roomId, 'approve': approve});
  }

  Future<void> jogarCartaMissao({
    required String roomId,
    required bool success,
  }) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('playMissionCard');
    await callable.call<void>({'roomId': roomId, 'success': success});
  }

  Future<void> voltarAoLobby(String roomId) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('resetRoom');
    await callable.call<void>({'roomId': roomId});
  }

  Future<void> sairDaSala(String roomId) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('leaveRoom');
    await callable.call<void>({'roomId': roomId});
  }

  Future<void> removerJogador({
    required String roomId,
    required String targetUid,
  }) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('removePlayer');
    await callable.call<void>({'roomId': roomId, 'targetUid': targetUid});
  }

  Future<void> abortarPartida(String roomId) async {
    await garantirLoginAnonimo();
    final callable = _functions.httpsCallable('abortGame');
    await callable.call<void>({'roomId': roomId});
  }
}
