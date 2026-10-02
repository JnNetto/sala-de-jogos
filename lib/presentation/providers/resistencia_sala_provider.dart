import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/resistencia_jogador_remoto.dart';
import '../../data/models/resistencia_estado_remoto.dart';
import '../../data/models/resistencia_privado.dart';
import '../../data/models/resistencia_proposta_remota.dart';
import '../../data/models/resistencia_sala.dart';
import '../../data/services/resistencia_firebase_service.dart';

class ResistenciaSalaProvider extends ChangeNotifier {
  static const String _ultimaSalaKey = 'resistencia_ultima_sala_id';

  final ResistenciaFirebaseService _service;

  ResistenciaSala? _sala;
  List<ResistenciaJogadorRemoto> _jogadores = const [];
  ResistenciaPrivado? _privado;
  ResistenciaEstadoRemoto? _estado;
  ResistenciaPropostaRemota? _proposta;
  bool _isLoading = false;
  String? _erro;
  DateTime? _ultimaEntradaSalaEm;
  final Map<String, bool> _papelReveladoCache = {};
  final Map<String, bool> _resultadoPropostaCache = {};
  final Map<String, bool> _resultadoMissaoCache = {};
  final Set<String> _marcadoresEmCarga = {};

  ResistenciaSalaProvider({ResistenciaFirebaseService? service})
    : _service = service ?? ResistenciaFirebaseService();

  ResistenciaSala? get sala => _sala;
  List<ResistenciaJogadorRemoto> get jogadores => _jogadores;
  ResistenciaPrivado? get privado => _privado;
  ResistenciaEstadoRemoto? get estado => _estado;
  ResistenciaPropostaRemota? get proposta => _proposta;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  String? get uid => _service.uid;
  bool get souHost => _sala != null && _sala!.hostUid == _service.uid;
  bool get podeIniciar =>
      souHost && _sala?.status == 'lobby' && _jogadores.length >= 5;
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
    final roomId = prefs.getString(_ultimaSalaKey);
    if (roomId == null || roomId.isEmpty) return false;

    return _executar(() async {
      final sala = await _service.obterSala(roomId);
      if (sala == null) {
        await prefs.remove(_ultimaSalaKey);
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

  Stream<ResistenciaSala?> observarSalaAtual() {
    final sala = _sala;
    if (sala == null) return Stream.value(null);
    return _service.observarSala(sala.id).map((novaSala) {
      _sala = novaSala;
      return novaSala;
    });
  }

  Stream<List<ResistenciaJogadorRemoto>> observarJogadoresAtuais() {
    final sala = _sala;
    if (sala == null) return Stream.value(const []);
    return _service.observarJogadores(sala.id).map((novosJogadores) {
      _jogadores = novosJogadores;
      return novosJogadores;
    });
  }

  Stream<ResistenciaPrivado?> observarMeuPrivadoAtual() {
    final sala = _sala;
    if (sala == null) return Stream.value(null);
    return _service.observarMeuPrivado(sala.id).map((privado) {
      _privado = privado;
      return privado;
    });
  }

  Stream<ResistenciaEstadoRemoto?> observarEstadoAtual() {
    final sala = _sala;
    if (sala == null) return Stream.value(null);
    return _service.observarEstado(sala.id).map((estado) {
      _estado = estado;
      return estado;
    });
  }

  Stream<ResistenciaPropostaRemota?> observarPropostaAtual() {
    final proposalId = _estado?.currentProposalId;
    if (proposalId == null) return Stream.value(null);
    return observarPropostaPorId(proposalId);
  }

  Stream<ResistenciaPropostaRemota?> observarPropostaPorId(String proposalId) {
    final sala = _sala;
    if (sala == null) return Stream.value(null);
    return _service.observarProposta(sala.id, proposalId).map((proposta) {
      _proposta = proposta;
      return proposta;
    });
  }

  Future<bool> iniciarPartidaRemota() async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(() => _service.iniciarPartida(sala.id));
  }

  Future<bool> proporEquipeRemota(List<String> memberUids) async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(
      () => _service.proporEquipe(roomId: sala.id, memberUids: memberUids),
    );
  }

  Future<bool> votarPropostaRemota(bool approve) async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(
      () => _service.votarProposta(roomId: sala.id, approve: approve),
    );
  }

  Future<bool> jogarCartaMissaoRemota(bool success) async {
    final sala = _sala;
    if (sala == null) return false;
    return _executar(
      () => _service.jogarCartaMissao(roomId: sala.id, success: success),
    );
  }

  Future<bool> voltarAoLobbyRemoto() async {
    final sala = _sala;
    if (sala == null) return false;
    final ok = await _executar(() => _service.voltarAoLobby(sala.id));
    if (ok) limparMarcadoresPartida();
    return ok;
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
    final ok = await _executar(() => _service.abortarPartida(sala.id));
    if (ok) limparMarcadoresPartida();
    return ok;
  }

  Future<void> esquecerUltimaSala() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ultimaSalaKey);
    _sala = null;
    _jogadores = const [];
    _privado = null;
    _estado = null;
    _proposta = null;
    _ultimaEntradaSalaEm = null;
    limparMarcadoresPartida();
    notifyListeners();
  }

  void limparMarcadoresPartida() {
    _papelReveladoCache.clear();
    _resultadoPropostaCache.clear();
    _resultadoMissaoCache.clear();
    _marcadoresEmCarga.clear();
  }

  bool? papelReveladoSync(String gameId) {
    if (gameId.isEmpty) return false;
    return _papelReveladoCache[gameId];
  }

  bool? resultadoPropostaVistoSync(String gameId, String proposalId) {
    if (gameId.isEmpty || proposalId.isEmpty) return false;
    return _resultadoPropostaCache['$gameId:$proposalId'];
  }

  bool? resultadoMissaoVistoSync(String gameId, int missionCount) {
    if (gameId.isEmpty || missionCount <= 0) return false;
    return _resultadoMissaoCache['$gameId:$missionCount'];
  }

  Future<void> garantirPapelReveladoCarregado(String gameId) async {
    if (gameId.isEmpty || _papelReveladoCache.containsKey(gameId)) return;
    if (!_marcadoresEmCarga.add('papel:$gameId')) return;
    try {
      await papelReveladoNestaPartida(gameId);
      notifyListeners();
    } finally {
      _marcadoresEmCarga.remove('papel:$gameId');
    }
  }

  Future<void> garantirResultadoPropostaCarregado(
    String gameId,
    String proposalId,
  ) async {
    final key = '$gameId:$proposalId';
    if (gameId.isEmpty ||
        proposalId.isEmpty ||
        _resultadoPropostaCache.containsKey(key)) {
      return;
    }
    if (!_marcadoresEmCarga.add('proposta:$key')) return;
    try {
      await resultadoPropostaVisto(gameId, proposalId);
      notifyListeners();
    } finally {
      _marcadoresEmCarga.remove('proposta:$key');
    }
  }

  Future<void> garantirResultadoMissaoCarregado(
    String gameId,
    int missionCount,
  ) async {
    final key = '$gameId:$missionCount';
    if (gameId.isEmpty ||
        missionCount <= 0 ||
        _resultadoMissaoCache.containsKey(key)) {
      return;
    }
    if (!_marcadoresEmCarga.add('missao:$key')) return;
    try {
      await resultadoMissaoVisto(gameId, missionCount);
      notifyListeners();
    } finally {
      _marcadoresEmCarga.remove('missao:$key');
    }
  }

  Future<bool> papelReveladoNestaPartida(String gameId) async {
    if (gameId.isEmpty) return false;
    final cached = _papelReveladoCache[gameId];
    if (cached != null) return cached;
    final sala = _sala;
    final uid = _service.uid;
    if (sala == null || uid == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final visto =
        prefs.getBool(_papelReveladoKey(sala.id, uid, gameId)) ?? false;
    _papelReveladoCache[gameId] = visto;
    return visto;
  }

  Future<void> marcarPapelRevelado(String gameId) async {
    if (gameId.isEmpty) return;
    final sala = _sala;
    final uid = _service.uid;
    if (sala == null || uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_papelReveladoKey(sala.id, uid, gameId), true);
    _papelReveladoCache[gameId] = true;
    notifyListeners();
  }

  Future<bool> resultadoPropostaVisto(String gameId, String proposalId) async {
    if (gameId.isEmpty || proposalId.isEmpty) return false;
    final key = '$gameId:$proposalId';
    final cached = _resultadoPropostaCache[key];
    if (cached != null) return cached;
    final sala = _sala;
    final uid = _service.uid;
    if (sala == null || uid == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final visto =
        prefs.getBool(
          _resultadoPropostaKey(sala.id, uid, gameId, proposalId),
        ) ??
        false;
    _resultadoPropostaCache[key] = visto;
    return visto;
  }

  Future<void> marcarResultadoPropostaVisto(
    String gameId,
    String proposalId,
  ) async {
    if (gameId.isEmpty || proposalId.isEmpty) return;
    final sala = _sala;
    final uid = _service.uid;
    if (sala == null || uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _resultadoPropostaKey(sala.id, uid, gameId, proposalId),
      true,
    );
    _resultadoPropostaCache['$gameId:$proposalId'] = true;
    notifyListeners();
  }

  Future<bool> resultadoMissaoVisto(String gameId, int missionCount) async {
    if (gameId.isEmpty || missionCount <= 0) return false;
    final key = '$gameId:$missionCount';
    final cached = _resultadoMissaoCache[key];
    if (cached != null) return cached;
    final sala = _sala;
    final uid = _service.uid;
    if (sala == null || uid == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final visto =
        prefs.getBool(
          _resultadoMissaoKey(sala.id, uid, gameId, missionCount),
        ) ??
        false;
    _resultadoMissaoCache[key] = visto;
    return visto;
  }

  Future<void> marcarResultadoMissaoVisto(
    String gameId,
    int missionCount,
  ) async {
    if (gameId.isEmpty || missionCount <= 0) return;
    final sala = _sala;
    final uid = _service.uid;
    if (sala == null || uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _resultadoMissaoKey(sala.id, uid, gameId, missionCount),
      true,
    );
    _resultadoMissaoCache['$gameId:$missionCount'] = true;
    notifyListeners();
  }

  Future<void> _salvarUltimaSala(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ultimaSalaKey, roomId);
  }

  String _papelReveladoKey(String roomId, String uid, String gameId) {
    return 'resistencia_papel_revelado_${roomId}_${uid}_$gameId';
  }

  String _resultadoPropostaKey(
    String roomId,
    String uid,
    String gameId,
    String proposalId,
  ) {
    return 'resistencia_resultado_proposta_${roomId}_${uid}_${gameId}_$proposalId';
  }

  String _resultadoMissaoKey(
    String roomId,
    String uid,
    String gameId,
    int missionCount,
  ) {
    return 'resistencia_resultado_missao_${roomId}_${uid}_${gameId}_$missionCount';
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
