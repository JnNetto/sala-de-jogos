import 'package:flutter/foundation.dart';
import '../../core/enums/modo_passe_quiz.dart';
import '../../core/utils/service_locator.dart';
import '../../data/models/configuracao_quiz.dart';

class QuizConfiguracaoProvider extends ChangeNotifier {
  final _service = ServiceLocator().quizPartidaService;

  ConfiguracaoQuiz _configuracao = ConfiguracaoQuiz();
  bool _isLoading = false;

  ConfiguracaoQuiz get configuracao => _configuracao;
  bool get isLoading => _isLoading;

  Future<void> carregar() async {
    _isLoading = true;
    notifyListeners();
    _configuracao = await _service.carregarConfiguracao();
    _isLoading = false;
    notifyListeners();
  }

  void setQuantidadeJogadores(int v) {
    _configuracao = _configuracao.copyWith(quantidadeJogadores: v);
    notifyListeners();
  }

  void setPerguntasPorJogador(int v) {
    _configuracao = _configuracao.copyWith(perguntasPorJogador: v);
    notifyListeners();
  }

  void setTempoPergunta(int v) {
    _configuracao = _configuracao.copyWith(tempoPerguntaSegundos: v);
    notifyListeners();
  }

  void setModoPasse(ModoPasseQuiz modo) {
    _configuracao = _configuracao.copyWith(modoPasse: modo);
    notifyListeners();
  }

  void setMostrarPlacarAposRodada(bool value) {
    _configuracao = _configuracao.copyWith(mostrarPlacarAposRodada: value);
    notifyListeners();
  }

  void setCategorias(List<String> cats) {
    _configuracao = _configuracao.copyWith(categoriasAtivas: cats);
    notifyListeners();
  }

  void setDificuldades(List<int> difs) {
    _configuracao = _configuracao.copyWith(dificuldadesAtivas: difs);
    notifyListeners();
  }

  void setNomes(List<String> nomes) {
    _configuracao = _configuracao.copyWith(nomesJogadores: nomes);
    notifyListeners();
  }

  Future<void> salvar() => _service.salvarConfiguracao(_configuracao);

  String? validar() => _configuracao.getValidationError();
}
