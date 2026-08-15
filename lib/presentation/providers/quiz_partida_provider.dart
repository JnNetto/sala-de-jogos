import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/enums/estado_partida_quiz.dart';
import '../../core/utils/service_locator.dart';
import '../../data/models/configuracao_quiz.dart';
import '../../data/models/partida_quiz.dart';

class QuizPartidaProvider extends ChangeNotifier {
  final _service = ServiceLocator().quizPartidaService;

  PartidaQuiz? _partida;
  bool _isLoading = false;
  String? _erro;
  Timer? _timer;

  PartidaQuiz? get partida => _partida;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  Future<bool> iniciarPartida({
    required ConfiguracaoQuiz configuracao,
    List<String>? nomes,
  }) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();
    try {
      _partida = await _service.iniciarPartida(
        configuracao: configuracao,
        nomes: nomes,
      );
      _isLoading = false;
      notifyListeners();
      return _partida != null;
    } catch (e) {
      _erro = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> prepararRodada() async {
    if (_partida == null) return false;
    _isLoading = true;
    notifyListeners();
    final atualizada = await _service.sortearPerguntaECategoria(_partida!);
    if (atualizada == null) {
      _erro = 'Não há perguntas disponíveis nas categorias selecionadas';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    _partida = atualizada;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void iniciarPergunta() {
    if (_partida == null) return;
    _partida = _service.iniciarPergunta(_partida!);
    notifyListeners();
    _iniciarTimer(ehAlvo: false);
  }

  void _iniciarTimer({required bool ehAlvo}) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_partida == null || _partida!.tempoRestanteSegundos <= 0) {
        timer.cancel();
        if (_partida != null && _partida!.tempoRestanteSegundos <= 0) {
          if (ehAlvo || _partida!.estado == EstadoPartidaQuiz.perguntaAlvo) {
            responderAlvo(null);
          } else if (_partida!.estado == EstadoPartidaQuiz.pergunta) {
            responderProprio(null);
          }
        }
        return;
      }
      _partida = _service.atualizarTempo(
        _partida!,
        _partida!.tempoRestanteSegundos - 1,
      );
      notifyListeners();
    });
  }

  void pausarTimer() => _timer?.cancel();

  void passarPergunta() {
    if (_partida == null) return;
    _timer?.cancel();
    _partida = _service.iniciarEscolhaAlvo(_partida!);
    notifyListeners();
  }

  void selecionarAlvo(int alvoId) {
    if (_partida == null) return;
    _partida = _service.selecionarAlvo(_partida!, alvoId);
    notifyListeners();
  }

  void iniciarPerguntaAlvo() {
    if (_partida == null) return;
    _partida = _service.iniciarPerguntaAlvo(_partida!);
    notifyListeners();
    _iniciarTimer(ehAlvo: true);
  }

  void responderProprio(int? indice) {
    if (_partida == null) return;
    _timer?.cancel();
    _partida = _service.responderProprio(_partida!, indice);
    notifyListeners();
  }

  void responderAlvo(int? indice) {
    if (_partida == null) return;
    _timer?.cancel();
    _partida = _service.responderAlvo(_partida!, indice);
    notifyListeners();
  }

  void avancarAposResumo() {
    if (_partida == null) return;
    _partida = _service.avancarParaProximaRodada(_partida!);
    notifyListeners();
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
