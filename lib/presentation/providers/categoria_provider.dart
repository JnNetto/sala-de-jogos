import 'package:flutter/foundation.dart';
import '../../core/utils/service_locator.dart';
import '../../data/models/categoria.dart';

class CategoriaProvider extends ChangeNotifier {
  final _palavraRepository = ServiceLocator().palavraRepository;

  List<Categoria> _categorias = [];
  List<String> _categoriasSelecionadas = [];

  List<Categoria> get categorias => _categorias;
  List<String> get categoriasSelecionadas => _categoriasSelecionadas;
  bool get todasSelecionadas =>
      _categoriasSelecionadas.length == _categorias.length;
  bool get nenhumaSelecionada => _categoriasSelecionadas.isEmpty;

  void carregarCategorias() {
    _categorias = _palavraRepository.getCategorias();
    _categoriasSelecionadas = _categorias.map((c) => c.id).toList();
    notifyListeners();
  }

  void toggleCategoria(String categoriaId) {
    if (_categoriasSelecionadas.contains(categoriaId)) {
      _categoriasSelecionadas.remove(categoriaId);
    } else {
      _categoriasSelecionadas.add(categoriaId);
    }
    notifyListeners();
  }

  void selecionarTodas() {
    _categoriasSelecionadas = _categorias.map((c) => c.id).toList();
    notifyListeners();
  }

  void deselecionarTodas() {
    _categoriasSelecionadas.clear();
    notifyListeners();
  }

  void sortearCategorias({int quantidade = 3}) {
    if (_categorias.length <= quantidade) {
      selecionarTodas();
      return;
    }

    final categoriasEmbaralhadas = List<Categoria>.from(_categorias)..shuffle();
    _categoriasSelecionadas = categoriasEmbaralhadas
        .take(quantidade)
        .map((c) => c.id)
        .toList();
    notifyListeners();
  }

  bool isSelecionada(String categoriaId) {
    return _categoriasSelecionadas.contains(categoriaId);
  }

  int getQuantidadePalavras(String categoriaId) {
    return _palavraRepository.getPalavrasPorCategoria(categoriaId).length;
  }

  int getQuantidadeTotalPalavras() {
    return _palavraRepository
        .getPalavrasPorCategorias(_categoriasSelecionadas)
        .length;
  }
}
