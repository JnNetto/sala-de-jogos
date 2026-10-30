import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Lançada quando uma ação online pede uma conta e ninguém entrou (ou só
/// há uma sessão anônima).
class ContaNecessaria implements Exception {
  const ContaNecessaria();

  @override
  String toString() => 'Entre com sua conta para jogar online.';
}

/// O login do app. Os jogos num celular só não precisam de conta; os
/// online, sim: com Google em qualquer plataforma e com Apple no iOS (a
/// Apple exige a opção dela quando há login do Google).
class ContaService {
  ContaService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// O id do cliente web do Google (OAuth). No Android, sem ele, o
  /// `google_sign_in` usa o `default_web_client_id` que o plugin do Google
  /// Services gera a partir do google-services.json.
  static const _clienteWeb = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static bool _googleIniciado = false;

  User? get usuario => _auth.currentUser;

  /// Entrou com uma conta de verdade (anônimo não conta).
  bool get logado {
    final u = _auth.currentUser;
    return u != null && !u.isAnonymous;
  }

  Stream<User?> get mudancas => _auth.userChanges();

  /// A Apple só aparece no iPhone e no iPad.
  static bool get temApple =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Para as ações online: o usuário logado, ou [ContaNecessaria].
  User exigirConta() {
    final u = _auth.currentUser;
    if (u == null || u.isAnonymous) throw const ContaNecessaria();
    return u;
  }

  /// Abre o login do Google. Devolve `false` se a pessoa desistir.
  Future<bool> entrarComGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
      return true;
    }
    final google = GoogleSignIn.instance;
    if (!_googleIniciado) {
      await google.initialize(
        serverClientId: _clienteWeb.isEmpty ? null : _clienteWeb,
      );
      _googleIniciado = true;
    }
    try {
      final conta = await google.authenticate();
      final idToken = conta.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'sem-token',
          message: 'O Google não devolveu a credencial. Tente de novo.',
        );
      }
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
  }

  /// Abre o login da Apple (iOS). Devolve `false` se a pessoa desistir.
  Future<bool> entrarComApple() async {
    try {
      await _auth.signInWithProvider(
        AppleAuthProvider()
          ..addScope('email')
          ..addScope('name'),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' || e.code == 'web-context-canceled') {
        return false;
      }
      rethrow;
    }
  }

  /// Exclui a conta no servidor (sai das salas, apaga o apelido e a conta)
  /// e encerra a sessão aqui.
  Future<void> excluirConta() async {
    exigirConta();
    await FirebaseFunctions.instanceFor(
      region: 'southamerica-east1',
    ).httpsCallable('excluirConta').call<void>();
    await _auth.signOut();
    if (!kIsWeb && _googleIniciado) {
      try {
        // Desfaz a ligação com o Google, não só a sessão.
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
    }
  }

  Future<void> sair() async {
    await _auth.signOut();
    if (!kIsWeb && _googleIniciado) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Sair do Firebase já basta; o Google só esquece a conta escolhida.
      }
    }
  }
}
