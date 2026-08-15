import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/utils/service_locator.dart';
import '../../data/models/configuracao_partida.dart';
import '../../data/models/partida_atual.dart';

class PartidaProvider extends ChangeNotifier {
  final _partidaService = ServiceLocator().partidaService;

  PartidaAtual? _partida;
  bool _isLoading = false;
  String? _erro;
  Timer? _timer;

  PartidaAtual? get partida => _partida;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  bool get temPartidaAtiva => _partida != null;

  Future<bool> iniciarNovaPartida({
    required ConfiguracaoPartida configuracao,
    List<String>? nomesJogadores,
  }) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _partida = await _partidaService.iniciarNovaPartida(
        configuracao: configuracao,
        nomesJogadores: nomesJogadores,
      );

      if (_partida == null) {
        _erro = 'Não há palavras disponíveis nas categorias selecionadas';
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _erro = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void iniciarDistribuicaoPapeis() {
    if (_partida == null) return;
    _partida = _partidaService.iniciarDistribuicaoPapeis(_partida!);
    notifyListeners();
  }

  void iniciarDiscussao() {
    if (_partida == null) return;
    _partida = _partidaService.iniciarDiscussao(_partida!);
    notifyListeners();
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_partida == null || _partida!.tempoRestanteSegundos <= 0) {
        timer.cancel();
        if (_partida != null && _partida!.tempoRestanteSegundos <= 0) {
          iniciarVotacao();
        }
        return;
      }

      _partida = _partidaService.atualizarTempoDiscussao(
        _partida!,
        _partida!.tempoRestanteSegundos - 1,
      );
      notifyListeners();
    });
  }

  void pularDiscussao() {
    _timer?.cancel();
    iniciarVotacao();
  }

  void pausarDiscussao() {
    _timer?.cancel();
  }

  void retomarDiscussao() {
    if (_partida == null) return;
    _iniciarTimer();
  }

  void iniciarVotacao() {
    if (_partida == null) return;
    _timer?.cancel();
    _partida = _partidaService.iniciarVotacao(_partida!);
    notifyListeners();
  }

  void votarJogador(int jogadorId) {
    if (_partida == null) return;
    _partida = _partidaService.votarJogador(_partida!, jogadorId);
    notifyListeners();
  }

  Future<void> finalizarPartida() async {
    if (_partida == null) return;
    _timer?.cancel();
    await _partidaService.finalizarPartida(_partida!);
  }

  Future<bool> jogarNovamente() async {
    if (_partida == null) return false;
    final configuracaoAtual = _partida!.configuracao;
    _timer?.cancel();

    return await iniciarNovaPartida(
      configuracao: configuracaoAtual,
      nomesJogadores: configuracaoAtual.nomesJogadores.isNotEmpty
          ? configuracaoAtual.nomesJogadores
          : null,
    );
  }

  void encerrarPartida() {
    _timer?.cancel();
    _partida = null;
    _erro = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
