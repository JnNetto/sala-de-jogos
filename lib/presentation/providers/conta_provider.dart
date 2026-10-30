import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/aneis_constants.dart';
import '../../core/constants/so_uma_constants.dart';
import '../../core/utils/service_locator.dart';
import '../../data/services/conta_service.dart';
import 'resistencia_sala_provider.dart';

/// A conta de quem joga, para as telas: se entrou, quem é, e as ações de
/// entrar e sair.
class ContaProvider extends ChangeNotifier {
  ContaProvider({ContaService? service})
    : _service = service ?? ContaService() {
    _assinatura = _service.mudancas.listen((_) => notifyListeners());
  }

  final ContaService _service;
  late final StreamSubscription<User?> _assinatura;
  bool _ocupado = false;
  String? _erro;

  bool get logado => _service.logado;
  bool get ocupado => _ocupado;
  String? get erro => _erro;
  bool get temApple => ContaService.temApple;

  User? get _usuario => _service.usuario;
  String? get nome {
    final n = _usuario?.displayName?.trim();
    return n == null || n.isEmpty ? null : n;
  }

  /// O primeiro nome, para sugerir como apelido na sala.
  String? get primeiroNome => nome?.split(' ').first;
  String? get email => logado ? _usuario?.email : null;

  Future<bool> entrarComGoogle() => _entrar(_service.entrarComGoogle);
  Future<bool> entrarComApple() => _entrar(_service.entrarComApple);

  /// Exclui a conta e esquece, neste aparelho, o apelido e as salas
  /// salvas. Devolve `false` (com [erro]) se não der.
  Future<bool> excluirConta() async {
    if (_ocupado) return false;
    _ocupado = true;
    _erro = null;
    notifyListeners();
    try {
      await _service.excluirConta();
      await ServiceLocator().storageService.limparNomeJogador();
      final prefs = await SharedPreferences.getInstance();
      for (final chave in [
        AneisConstants.prefsKeyUltimaSalaId,
        SoUmaConstants.prefsKeyUltimaSalaId,
        ResistenciaSalaProvider.chaveUltimaSala,
      ]) {
        await prefs.remove(chave);
      }
      return true;
    } on FirebaseFunctionsException catch (e) {
      _erro = e.code == 'unavailable'
          ? 'Sem conexão. Tente de novo.'
          : e.message ?? 'Não deu para excluir a conta agora.';
      return false;
    } catch (_) {
      _erro = 'Não deu para excluir a conta agora.';
      return false;
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  Future<void> sair() async {
    await _service.sair();
    notifyListeners();
  }

  Future<bool> _entrar(Future<bool> Function() acao) async {
    if (_ocupado) return false;
    _ocupado = true;
    _erro = null;
    notifyListeners();
    try {
      return await acao();
    } on FirebaseAuthException catch (e) {
      _erro = switch (e.code) {
        'network-request-failed' => 'Sem conexão. Tente de novo.',
        'account-exists-with-different-credential' =>
          'Esse e-mail já entrou de outro jeito. Use o mesmo login de antes.',
        _ => e.message ?? 'Não deu para entrar. Tente de novo.',
      };
      return false;
    } on GoogleSignInException catch (e) {
      _erro = e.description ?? 'Não deu para entrar com o Google.';
      return false;
    } catch (_) {
      _erro = 'Não deu para entrar. Tente de novo.';
      return false;
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _assinatura.cancel();
    super.dispose();
  }
}
