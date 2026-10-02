import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/so_uma_constants.dart';
import '../../data/models/so_uma_estado_remoto.dart';
import '../../data/models/so_uma_jogador_remoto.dart';
import '../../data/models/so_uma_rodada_remota.dart';
import '../../data/models/so_uma_sala.dart';
import '../../data/services/so_uma_firebase_service.dart';

class SoUmaSalaProvider extends ChangeNotifier {
  final SoUmaFirebaseService _service;

  SoUmaSala? _sala;
  List<SoUmaJogadorRemoto> _jogadores = const [];
  SoUmaEstadoRemoto? _estado;
  SoUmaRodadaRemota? _rodada;
  bool _isLoading = false;
  String? _erro;
  DateTime? _ultimaEntradaSalaEm;
  String? _gameIdLocal;

  SoUmaSalaProvider({SoUmaFirebaseService? service})
    : _service = service ?? SoUmaFirebaseService();

  SoUmaSala? get sala => _sala;
  List<SoUmaJogadorRemoto> get jogadores => _jogadores;
  SoUmaEstadoRemoto? get estado => _estado;
  SoUmaRodadaRemota? get rodada => _rodada;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  String? get uid => _service.uid;
  bool get souHost => _sala != null && _sala!.hostUid == _service.uid;
  bool get souAdivinhador => _estado != null && _estado!.guesserUid == uid;
  bool get podeIniciar =>
      souHost &&
      _sala?.status == 'lobby' &&
      _jogadores.length >= SoUmaConstants.minJogadores &&
      _jogadores.length <= SoUmaConstants.maxJogadores;
  bool get podeDetectarRemocao {
    final entrada = _ultimaEntradaSalaEm;
    if (entrada == null) return true;
    return DateTime.now().difference(entrada) > const Duration(seconds: 3);
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
    final roomId = prefs.getString(SoUmaConstants.prefsKeyUltimaSalaId);
    if (roomId == null || roomId.isEmpty) return false;

    return _executar(() async {
      final sala = await _service.obterSala(roomId);
      if (sala == null) {
        await prefs.remove(SoUmaConstants.prefsKeyUltimaSalaId);
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

  Stream<SoUmaSala?> observarSalaAtual() {
    final sala = _sala;
    if (sala == null) return Stream.value(null);
    return _service.observarSala(sala.id).map((novaSala) {
      _sala = novaSala;
      return novaSala;
    });
  }

  Stream<List<SoUmaJogadorRemoto>> observarJogadoresAtuais() {
    final sala = _sala;
    if (sala == null) return Stream.value(const []);
    return _service.observarJogadores(sala.id).map((novosJogadores) {
      _jogadores = novosJogadores;
      return novosJogadores;
    });
  }

  Stream<SoUmaEstadoRemoto?> observarEstadoAtual() {
    final sala = _sala;
    if (sala == null) return Stream.value(null);
    return _service.observarEstado(sala.id).map((estado) {
      _estado = estado;
      return estado;
    });
  }

  Stream<SoUmaRodadaRemota?> observarRodadaAtual() {
    final roundId = _estado?.currentRoundId;
    if (roundId == null) return Stream.value(null);
    return observarRodadaPorId(roundId);
  }

  Stream<SoUmaRodadaRemota?> observarRodadaPorId(String roundId) {
    final sala = _sala;
    if (sala == null) return Stream.value(null);
    return _service.observarRodada(sala.id, roundId).map((rodada) {
      _rodada = rodada;
      return rodada;
    });
  }

  Future<bool> iniciarPartidaRemota() async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(() => _service.iniciarPartida(sala.id));
  }

  Future<bool> escolherNumeroRemoto(int numero) async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(
      () => _service.escolherNumero(roomId: sala.id, numero: numero),
    );
  }

  Future<bool> enviarPistasRemoto(List<String> palavras) async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(
      () => _service.enviarPistas(roomId: sala.id, palavras: palavras),
    );
  }

  Future<bool> alternarAnulacaoPistaRemota(String clueId) async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(
      () => _service.alternarAnulacaoPista(roomId: sala.id, clueId: clueId),
    );
  }

  Future<bool> finalizarComparacaoRemota() async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(() => _service.finalizarComparacao(sala.id));
  }

  Future<bool> enviarPalpiteRemoto({
    String? palpite,
    bool passar = false,
  }) async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(
      () => _service.enviarPalpite(
        roomId: sala.id,
        palpite: palpite,
        passar: passar,
      ),
    );
  }

  Future<bool> voltarAoLobbyRemoto() async {
    final sala = _sala;
    if (sala == null) return false;
    final ok = await _executar(() => _service.voltarAoLobby(sala.id));
    if (ok) resetarMarcadoresResultadoRodada();
    return ok;
  }

  Future<bool> sairDaSalaRemota() async {
    final sala = _sala;
    if (sala == null) return false;
    final ok = await _executar(() => _service.sairDaSala(sala.id));
    if (ok) {
      resetarMarcadoresResultadoRodada();
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
    final ok = await _executar(() => _service.abortarPartida(sala.id));
    if (ok) resetarMarcadoresResultadoRodada();
    return ok;
  }

  Future<void> esquecerUltimaSala() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SoUmaConstants.prefsKeyUltimaSalaId);
    _sala = null;
    _jogadores = const [];
    _estado = null;
    _rodada = null;
    _ultimaEntradaSalaEm = null;
    _gameIdLocal = null;
    notifyListeners();
  }

  void resetarMarcadoresResultadoRodada() {
    _gameIdLocal = null;
  }

  Future<bool> resultadoRodadaVisto({
    required String roomId,
    required String gameId,
    required int quantidadeHistorico,
  }) async {
    if (quantidadeHistorico <= 0) return false;
    final uid = _service.uid;
    if (uid == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(
          _resultadoRodadaKey(
            roomId,
            uid,
            _gameIdDaPartida(gameId),
            quantidadeHistorico,
          ),
        ) ??
        false;
  }

  Future<void> marcarResultadoRodadaVisto({
    required String roomId,
    required String gameId,
    required int quantidadeHistorico,
  }) async {
    if (quantidadeHistorico <= 0) return;
    final uid = _service.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _resultadoRodadaKey(
        roomId,
        uid,
        _gameIdDaPartida(gameId),
        quantidadeHistorico,
      ),
      true,
    );
  }

  Future<void> _salvarUltimaSala(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SoUmaConstants.prefsKeyUltimaSalaId, roomId);
  }

  String _gameIdDaPartida(String gameId) {
    if (gameId.isNotEmpty) {
      _gameIdLocal = null;
      return gameId;
    }
    return _gameIdLocal ??= DateTime.now().microsecondsSinceEpoch.toString();
  }

  String _resultadoRodadaKey(
    String roomId,
    String uid,
    String gameId,
    int quantidade,
  ) {
    return 'so_uma_resultado_rodada_${roomId}_${uid}_${gameId}_$quantidade';
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
