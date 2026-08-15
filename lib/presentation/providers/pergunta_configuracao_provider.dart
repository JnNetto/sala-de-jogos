import 'package:flutter/foundation.dart';
import '../../core/utils/service_locator.dart';
import '../../data/models/configuracao_pergunta_impostora.dart';

class PerguntaConfiguracaoProvider extends ChangeNotifier {
  final _service = ServiceLocator().perguntaPartidaService;

  ConfiguracaoPerguntaImpostora _configuracao = ConfiguracaoPerguntaImpostora();
  bool _isLoading = false;

  ConfiguracaoPerguntaImpostora get configuracao => _configuracao;
  bool get isLoading => _isLoading;

  Future<void> carregarConfiguracao() async {
    _isLoading = true;
    notifyListeners();
    final carregada = await _service.carregarConfiguracao();
    _configuracao = carregada.copyWith(
      jogadoresRestantesParaVitoriaImpostor:
          carregada.limiarVitoriaImpostorClamped,
    );
    _isLoading = false;
    notifyListeners();
  }

  void atualizarConfiguracao(ConfiguracaoPerguntaImpostora config) {
    _configuracao = config;
    notifyListeners();
  }

  void setQuantidadeJogadores(int value) {
    _configuracao = _configuracao.copyWith(
      quantidadeJogadores: value,
      jogadoresRestantesParaVitoriaImpostor:
          ConfiguracaoPerguntaImpostora.defaultLimiarVitoriaImpostor(value),
    );
    if (_configuracao.quantidadeImpostores > _configuracao.maxImpostores) {
      _configuracao = _configuracao.copyWith(
        quantidadeImpostores: _configuracao.maxImpostores,
      );
    }
    _configuracao = _configuracao.copyWith(
      jogadoresRestantesParaVitoriaImpostor:
          _configuracao.limiarVitoriaImpostorClamped,
    );
    notifyListeners();
  }

  void setQuantidadeImpostores(int value) {
    _configuracao = _configuracao.copyWith(quantidadeImpostores: value);
    _configuracao = _configuracao.copyWith(
      jogadoresRestantesParaVitoriaImpostor:
          _configuracao.limiarVitoriaImpostorClamped,
    );
    notifyListeners();
  }

  void setJogadoresRestantesParaVitoriaImpostor(int value) {
    _configuracao = _configuracao.copyWith(
      jogadoresRestantesParaVitoriaImpostor: value.clamp(
        _configuracao.minLimiarVitoriaImpostor,
        _configuracao.maxLimiarVitoriaImpostor,
      ),
    );
    notifyListeners();
  }

  void setDuracaoDiscussao(int value) {
    _configuracao = _configuracao.copyWith(duracaoDiscussaoSegundos: value);
    notifyListeners();
  }

  void setCategoriasAtivas(List<String> ids) {
    _configuracao = _configuracao.copyWith(categoriasAtivasIds: ids);
    notifyListeners();
  }

  void setNiveisAtivos(List<int> niveis) {
    _configuracao = _configuracao.copyWith(niveisAtivos: niveis);
    notifyListeners();
  }

  void setNomesJogadores(List<String> nomes) {
    _configuracao = _configuracao.copyWith(nomesJogadores: nomes);
    notifyListeners();
  }

  Future<void> salvar() async {
    await _service.salvarConfiguracao(_configuracao);
  }

  String? validarConfiguracao() => _configuracao.getValidationError();
}
