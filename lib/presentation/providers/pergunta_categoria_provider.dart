import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/utils/service_locator.dart';
import '../../data/models/categoria_pergunta.dart';

class PerguntaCategoriaProvider extends ChangeNotifier {
  final _repository = ServiceLocator().perguntaRepository;
  final _random = Random();

  final Set<String> _selecionadas = {};
  final Set<int> _niveisSelecionados = {1, 2, 3};

  List<CategoriaPergunta> get categorias => _repository.getCategorias();
  List<String> get categoriasSelecionadas => _selecionadas.toList();
  List<int> get niveisSelecionados => _niveisSelecionados.toList()..sort();

  void carregarCategorias({List<String>? idsSalvos, List<int>? niveisSalvos}) {
    _selecionadas.clear();
    if (idsSalvos != null && idsSalvos.isNotEmpty) {
      _selecionadas.addAll(idsSalvos);
    } else {
      _selecionadas.addAll(categorias.map((c) => c.id));
    }

    if (niveisSalvos != null && niveisSalvos.isNotEmpty) {
      _niveisSelecionados
        ..clear()
        ..addAll(niveisSalvos);
    }

    notifyListeners();
  }

  bool isSelecionada(String id) => _selecionadas.contains(id);

  void toggleCategoria(String id) {
    if (_selecionadas.contains(id)) {
      _selecionadas.remove(id);
    } else {
      _selecionadas.add(id);
    }
    notifyListeners();
  }

  void selecionarTodas() {
    _selecionadas
      ..clear()
      ..addAll(categorias.map((c) => c.id));
    notifyListeners();
  }

  void deselecionarTodas() {
    _selecionadas.clear();
    notifyListeners();
  }

  void sortearCategorias({int quantidade = 3}) {
    final todas = categorias.map((c) => c.id).toList()..shuffle(_random);
    _selecionadas
      ..clear()
      ..addAll(todas.take(quantidade.clamp(1, todas.length)));
    notifyListeners();
  }

  bool isNivelSelecionado(int nivel) => _niveisSelecionados.contains(nivel);

  void toggleNivel(int nivel) {
    if (_niveisSelecionados.contains(nivel)) {
      if (_niveisSelecionados.length > 1) {
        _niveisSelecionados.remove(nivel);
      }
    } else {
      _niveisSelecionados.add(nivel);
    }
    notifyListeners();
  }

  int getQuantidadePares(String categoriaId) {
    return _repository.getQuantidadePares(categoriaId);
  }

  int getQuantidadeTotalPares() {
    return _repository.getQuantidadeTotalPares(
      categoriasIds: categoriasSelecionadas,
      niveis: niveisSelecionados,
    );
  }
}
