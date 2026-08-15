import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/constants/quiz_da_vez_constants.dart';
import '../models/quiz_pergunta.dart';

class QuizRepository {
  List<QuizPergunta> _perguntas = [];
  List<String> _categorias = [];
  bool _carregado = false;

  bool get isCarregado => _carregado;
  List<QuizPergunta> get perguntas => List.unmodifiable(_perguntas);
  List<String> get categorias => List.unmodifiable(_categorias);

  Future<void> carregar() async {
    if (_carregado) return;
    final raw = await rootBundle.loadString(QuizDaVezConstants.assetBanco);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _perguntas = (json['perguntas'] as List<dynamic>)
        .map((e) => QuizPergunta.fromJson(e as Map<String, dynamic>))
        .toList();
    _categorias = _perguntas.map((p) => p.categoria).toSet().toList()..sort();
    _carregado = true;
  }

  int getQuantidade(String categoria) =>
      _perguntas.where((p) => p.categoria == categoria).length;

  int getQuantidadeTotal({
    required List<String> categorias,
    required List<int> dificuldades,
  }) {
    return getDisponiveis(
      categorias: categorias,
      dificuldades: dificuldades,
      usadasIds: const [],
    ).length;
  }

  List<QuizPergunta> getDisponiveis({
    required List<String> categorias,
    required List<int> dificuldades,
    required List<String> usadasIds,
    String? evitarCategoria,
  }) {
    return _perguntas.where((p) {
      final catOk = categorias.isEmpty || categorias.contains(p.categoria);
      final difOk =
          dificuldades.isEmpty || dificuldades.contains(p.dificuldade);
      final naoUsada = !usadasIds.contains(p.id);
      final evita = evitarCategoria == null || p.categoria != evitarCategoria;
      return catOk && difOk && naoUsada && evita;
    }).toList();
  }
}
