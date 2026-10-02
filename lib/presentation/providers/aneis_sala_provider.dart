import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/aneis_constants.dart';
import '../../data/models/aneis_carta_publica.dart';
import '../../data/models/aneis_estado_remoto.dart';
import '../../data/models/aneis_jogador_remoto.dart';
import '../../data/models/aneis_knower_view.dart';
import '../../data/models/aneis_sala.dart';
import '../../data/services/aneis_firebase_service.dart';

class AneisSalaProvider extends ChangeNotifier {
  final AneisFirebaseService _service;

  AneisSala? _sala;
  List<AneisJogadorRemoto> _jogadores = const [];
  AneisEstadoRemoto? _estado;
  List<AneisCartaPublica> _mao = const [];
  AneisKnowerView? _visaoKnower;
  bool _isLoading = false;
  String? _erro;
  DateTime? _ultimaEntradaSalaEm;
  String _dificuldade = 'facil';
  String _knowerMode = AneisConstants.knowerJogador;
  String? _knowerUidEscolhido;

  AneisSalaProvider({AneisFirebaseService? service})
    : _service = service ?? AneisFirebaseService();

  AneisSala? get sala => _sala;
  List<AneisJogadorRemoto> get jogadores => _jogadores;
  AneisEstadoRemoto? get estado => _estado;
  List<AneisCartaPublica> get mao => _mao;
  AneisKnowerView? get visaoKnower => _visaoKnower;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  String? get uid => _service.uid;
  String get dificuldade => _dificuldade;
  String get knowerMode => _knowerMode;
  String? get knowerUidEscolhido => _knowerUidEscolhido;
  bool get podeDesfazer => souKnower && _estado?.podeDesfazer == true;
  bool get souHost => _sala != null && _sala!.hostUid == _service.uid;
  bool get souKnower =>
      _estado?.knowerHumano == true && _estado?.knowerUid == uid;
  bool get minhaVez =>
      _estado != null &&
      _estado!.phase == 'playing' &&
      _estado!.currentUid == uid &&
      !souKnower;
  bool get emSetupKnower => souKnower && _estado?.phase == 'setup';
  bool get emJulgamentoKnower => souKnower && _estado?.phase == 'judging';
  bool get podeIniciar =>
      souHost &&
      _sala?.status == 'lobby' &&
      _jogadores.length >= AneisConstants.minJogadores &&
      _jogadores.length <= AneisConstants.maxJogadores;
  bool get podeDetectarRemocao {
    final entrada = _ultimaEntradaSalaEm;
    if (entrada == null) return true;
    return DateTime.now().difference(entrada) > const Duration(seconds: 3);
  }

  void definirKnowerMode(String valor) {
    if (valor != AneisConstants.knowerJogador &&
        valor != AneisConstants.knowerApp) {
      return;
    }
    _knowerMode = valor;
    if (valor != AneisConstants.knowerJogador) {
      _knowerUidEscolhido = null;
    }
    notifyListeners();
  }

  void definirKnowerUid(String? uid) {
    _knowerUidEscolhido = uid;
    notifyListeners();
  }

  void definirDificuldade(String valor) {
    if (!AneisConstants.dificuldades.contains(valor)) return;
    _dificuldade = valor;
    notifyListeners();
  }

  Future<bool> criarSala(String nome) async {
    return _executar(() async {
      _sala = await _service.criarSala(displayName: nome.trim());
      _ultimaEntradaSalaEm = DateTime.now();
      await _salvarUltimaSala(_sala!.id);
    });
  }

  Future<bool> entrarNaSala({
    required String codigo,
    required String nome,
  }) async {
    return _executar(() async {
      _sala = await _service.entrarNaSala(
        codigo: codigo.trim(),
        displayName: nome.trim(),
      );
      _ultimaEntradaSalaEm = DateTime.now();
      await _salvarUltimaSala(_sala!.id);
    });
  }

  Future<bool> restaurarUltimaSala() async {
    final prefs = await SharedPreferences.getInstance();
    final roomId = prefs.getString(AneisConstants.prefsKeyUltimaSalaId);
    if (roomId == null || roomId.isEmpty) return false;

    return _executar(() async {
      final sala = await _service.obterSala(roomId);
      if (sala == null) {
        await prefs.remove(AneisConstants.prefsKeyUltimaSalaId);
        throw Exception('Sala salva não encontrada.');
      }
      _sala = sala;
      _ultimaEntradaSalaEm = DateTime.now();
    });
  }

  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  Stream<AneisSala?> observarSalaAtual() {
    final sala = _sala;
    if (sala == null) return Stream.value(null);
    return _service.observarSala(sala.id).map((novaSala) {
      _sala = novaSala;
      return novaSala;
    });
  }

  Stream<List<AneisJogadorRemoto>> observarJogadoresAtuais() {
    final sala = _sala;
    if (sala == null) return Stream.value(const []);
    return _service.observarJogadores(sala.id).map((novosJogadores) {
      _jogadores = novosJogadores;
      return novosJogadores;
    });
  }

  Stream<AneisEstadoRemoto?> observarEstadoAtual() {
    final sala = _sala;
    if (sala == null) return Stream.value(null);
    return _service.observarEstado(sala.id).map((estado) {
      _estado = estado;
      return estado;
    });
  }

  Stream<List<AneisCartaPublica>> observarMaoAtual() {
    final sala = _sala;
    final uidAtual = uid;
    if (sala == null || uidAtual == null) return Stream.value(const []);
    return _service.observarMao(sala.id, uidAtual).map((mao) {
      _mao = mao;
      return mao;
    });
  }

  Stream<AneisKnowerView?> observarVisaoKnowerAtual() {
    final sala = _sala;
    if (sala == null) return Stream.value(null);
    return _service.observarVisaoKnower(sala.id).map((visao) {
      _visaoKnower = visao;
      return visao;
    });
  }

  Future<bool> iniciarPartidaRemota() async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(
      () => _service.iniciarPartida(
        roomId: sala.id,
        dificuldade: _dificuldade,
        knowerMode: _knowerMode,
        knowerUid: _knowerMode == AneisConstants.knowerJogador
            ? _knowerUidEscolhido
            : null,
      ),
    );
  }

  Future<bool> posicionarCarta({
    required String coisaId,
    required String regiao,
  }) async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(
      () => _service.posicionarCarta(
        roomId: sala.id,
        coisaId: coisaId,
        regiao: regiao,
      ),
    );
  }

  Future<bool> julgarPosicao({required String regiao}) async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(
      () => _service.julgarPosicao(roomId: sala.id, regiao: regiao),
    );
  }

  Future<bool> desfazerJulgamento() async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(() => _service.desfazerJulgamento(sala.id));
  }

  Future<bool> voltarAoLobbyRemoto() async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(() => _service.voltarAoLobby(sala.id));
  }

  Future<bool> sairDaSalaRemota() async {
    final sala = _sala;
    if (sala == null) return false;
    final ok = await _executar(() => _service.sairDaSala(sala.id));
    if (ok) {
      await esquecerUltimaSala();
    }
    return ok;
  }

  Future<bool> removerJogadorRemoto(String targetUid) async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(
      () => _service.removerJogador(roomId: sala.id, targetUid: targetUid),
    );
  }

  Future<bool> abortarPartidaRemota() async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(() => _service.abortarPartida(sala.id));
  }

  Future<void> esquecerUltimaSala() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AneisConstants.prefsKeyUltimaSalaId);
    _sala = null;
    _jogadores = const [];
    _estado = null;
    _mao = const [];
    _visaoKnower = null;
    _ultimaEntradaSalaEm = null;
    _knowerUidEscolhido = null;
    notifyListeners();
  }

  Future<void> _salvarUltimaSala(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AneisConstants.prefsKeyUltimaSalaId, roomId);
  }

  Future<bool> _executar(Future<void> Function() action) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on FirebaseFunctionsException catch (e) {
      _erro = e.message ?? _traduzirErro(e.code);
      return false;
    } catch (e) {
      _erro = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _traduzirErro(String code) {
    switch (code) {
      case 'unauthenticated':
        return 'Não foi possível autenticar.';
      case 'not-found':
        return 'Sala não encontrada.';
      case 'failed-precondition':
        return 'A sala não está disponível.';
      case 'permission-denied':
        return 'Você não pode fazer isso nesta sala.';
      case 'invalid-argument':
        return 'Confira os dados e tente novamente.';
      case 'already-exists':
        return 'Essa ação já foi registrada.';
      case 'resource-exhausted':
        return 'Tente novamente em instantes.';
      default:
        return 'Erro ao acessar a sala.';
    }
  }
}
