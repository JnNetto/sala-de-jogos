import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/utils/service_locator.dart';

class QuizCategoriaProvider extends ChangeNotifier {
  final _repo = ServiceLocator().quizRepository;
  final _random = Random();

  final Set<String> _selecionadas = {};
  final Set<int> _dificuldades = {1, 2, 3};

  List<String> get categorias => _repo.categorias;
  List<String> get selecionadas => _selecionadas.toList();
  List<int> get dificuldadesSelecionadas => _dificuldades.toList()..sort();

  void carregar({List<String>? salvas, List<int>? dificuldades}) {
    final disponiveis = categorias.toSet();
    final filtradas = (salvas ?? [])
        .where((c) => disponiveis.contains(c))
        .toList();
    _selecionadas
      ..clear()
      ..addAll(filtradas.isNotEmpty ? filtradas : categorias);
    if (dificuldades != null && dificuldades.isNotEmpty) {
      _dificuldades
        ..clear()
        ..addAll(dificuldades);
    }
    notifyListeners();
  }

  bool isSelecionada(String c) => _selecionadas.contains(c);

  void toggle(String c) {
    if (_selecionadas.contains(c)) {
      _selecionadas.remove(c);
    } else {
      _selecionadas.add(c);
    }
    notifyListeners();
  }

  void selecionarTodas() {
    _selecionadas
      ..clear()
      ..addAll(categorias);
    notifyListeners();
  }

  void deselecionarTodas() {
    _selecionadas.clear();
    notifyListeners();
  }

  void sortear({int quantidade = 3}) {
    final todas = List<String>.from(categorias)..shuffle(_random);
    _selecionadas
      ..clear()
      ..addAll(todas.take(quantidade.clamp(1, todas.length)));
    notifyListeners();
  }

  bool isDificuldadeSelecionada(int d) => _dificuldades.contains(d);

  void toggleDificuldade(int d) {
    if (_dificuldades.contains(d)) {
      if (_dificuldades.length > 1) _dificuldades.remove(d);
    } else {
      _dificuldades.add(d);
    }
    notifyListeners();
  }

  int quantidade(String c) => _repo.getQuantidade(c);

  int totalDisponivel() => _repo.getQuantidadeTotal(
    categorias: selecionadas,
    dificuldades: dificuldadesSelecionadas,
  );
}
