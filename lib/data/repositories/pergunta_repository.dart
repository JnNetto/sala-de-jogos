import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/constants/pergunta_impostora_constants.dart';
import '../models/categoria_pergunta.dart';
import '../models/par_perguntas.dart';

class PerguntaRepository {
  List<ParPerguntas> _pares = [];
  List<CategoriaPergunta> _categorias = [];
  bool _carregado = false;

  bool get isCarregado => _carregado;
  List<ParPerguntas> get pares => List.unmodifiable(_pares);
  List<CategoriaPergunta> get categorias => List.unmodifiable(_categorias);

  Future<void> carregar() async {
    if (_carregado) return;

    final raw = await rootBundle.loadString(
      'assets/pergunta_impostora_banco.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final lista = (json['pares'] as List<dynamic>)
        .map((e) => ParPerguntas.fromJson(e as Map<String, dynamic>))
        .toList();

    _pares = lista;

    final ids = lista.map((p) => p.categoriaId).toSet().toList()..sort();
    _categorias = ids
        .map(
          (id) => CategoriaPergunta(
            id: id,
            nome: PerguntaImpostoraConstants.nomeCategoria(id),
          ),
        )
        .toList();

    _carregado = true;
  }

  List<CategoriaPergunta> getCategorias() => categorias;

  int getQuantidadePares(String categoriaId) {
    return _pares.where((p) => p.categoriaId == categoriaId).length;
  }

  int getQuantidadeTotalPares({
    required List<String> categoriasIds,
    required List<int> niveis,
  }) {
    return getParesDisponiveis(
      categoriasIds: categoriasIds,
      niveis: niveis,
      usadosIds: const [],
    ).length;
  }

  List<ParPerguntas> getParesDisponiveis({
    required List<String> categoriasIds,
    required List<int> niveis,
    required List<String> usadosIds,
  }) {
    return _pares.where((par) {
      final categoriaOk =
          categoriasIds.isEmpty || categoriasIds.contains(par.categoriaId);
      final nivelOk = niveis.isEmpty || niveis.contains(par.nivel);
      final naoUsado = !usadosIds.contains(par.idString);
      return categoriaOk && nivelOk && naoUsado;
    }).toList();
  }
}
