import '../models/categoria.dart';
import '../models/palavra.dart';
import 'dados_iniciais.dart';

class PalavraRepository {
  final List<Categoria> _categorias = List.from(DadosIniciais.categorias);
  final List<Palavra> _palavras = List.from(DadosIniciais.palavras);

  List<Categoria> getCategorias() {
    return List.unmodifiable(_categorias);
  }

  List<Categoria> getCategoriasAtivas() {
    return _categorias.where((c) => c.ativa).toList();
  }

  Categoria? getCategoriaById(String id) {
    try {
      return _categorias.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  void atualizarCategoria(Categoria categoria) {
    final index = _categorias.indexWhere((c) => c.id == categoria.id);
    if (index != -1) {
      _categorias[index] = categoria;
    }
  }

  void toggleCategoriaAtiva(String categoriaId) {
    final index = _categorias.indexWhere((c) => c.id == categoriaId);
    if (index != -1) {
      _categorias[index] = _categorias[index].copyWith(
        ativa: !_categorias[index].ativa,
      );
    }
  }

  List<Palavra> getPalavras() {
    return List.unmodifiable(_palavras);
  }

  List<Palavra> getPalavrasPorCategoria(String categoriaId) {
    return _palavras.where((p) => p.categoriaId == categoriaId).toList();
  }

  List<Palavra> getPalavrasPorCategorias(List<String> categoriasIds) {
    return _palavras
        .where((p) => categoriasIds.contains(p.categoriaId))
        .toList();
  }

  Palavra? getPalavraById(String id) {
    try {
      return _palavras.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Palavra? getPalavraRelacionada(String palavraId) {
    final palavra = getPalavraById(palavraId);
    if (palavra == null) return null;
    return getPalavraById(palavra.palavraRelacionadaId);
  }

  List<Palavra> getPalavrasDisponiveisParaSorteio({
    required List<String> categoriasIds,
    required List<String> palavrasUsadasIds,
  }) {
    var palavrasDisponiveis = getPalavrasPorCategorias(categoriasIds);

    palavrasDisponiveis = palavrasDisponiveis
        .where((p) => !palavrasUsadasIds.contains(p.id))
        .toList();

    return palavrasDisponiveis;
  }

  int getQuantidadePalavrasPorCategorias(List<String> categoriasIds) {
    return getPalavrasPorCategorias(categoriasIds).length;
  }
}
