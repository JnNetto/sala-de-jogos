import 'package:flutter/foundation.dart';
import '../../core/utils/service_locator.dart';
import '../../data/models/configuracao_partida.dart';

class ConfiguracaoProvider extends ChangeNotifier {
  final _partidaService = ServiceLocator().partidaService;

  ConfiguracaoPartida _configuracao = ConfiguracaoPartida();
  bool _isLoading = false;

  ConfiguracaoPartida get configuracao => _configuracao;
  bool get isLoading => _isLoading;

  Future<void> carregarConfiguracao() async {
    _isLoading = true;
    notifyListeners();

    try {
      _configuracao = await _partidaService.carregarConfiguracao();
    } catch (e) {
      _configuracao = ConfiguracaoPartida();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> atualizarConfiguracao(ConfiguracaoPartida novaConfig) async {
    _configuracao = novaConfig;
    notifyListeners();
    await _partidaService.salvarConfiguracao(novaConfig);
  }

  void setQuantidadeJogadores(int quantidade) {
    _configuracao = _configuracao.copyWith(quantidadeJogadores: quantidade);
    notifyListeners();
  }

  void setQuantidadeEspioes(int quantidade) {
    _configuracao = _configuracao.copyWith(quantidadeEspioes: quantidade);
    notifyListeners();
  }

  void setEspiaoVePalavraRelacionada(bool value) {
    _configuracao = _configuracao.copyWith(espiaoVePalavraRelacionada: value);
    notifyListeners();
  }

  void setDuracaoDiscussao(int segundos) {
    _configuracao = _configuracao.copyWith(duracaoDiscussaoSegundos: segundos);
    notifyListeners();
  }

  void setCategoriasAtivas(List<String> categoriasIds) {
    _configuracao = _configuracao.copyWith(categoriasAtivasIds: categoriasIds);
    notifyListeners();
  }

  void setNomesJogadores(List<String> nomes) {
    _configuracao = _configuracao.copyWith(nomesJogadores: nomes);
    notifyListeners();
  }

  Future<void> salvar() async {
    await _partidaService.salvarConfiguracao(_configuracao);
  }

  String? validarConfiguracao() {
    return _configuracao.getValidationError();
  }
}
