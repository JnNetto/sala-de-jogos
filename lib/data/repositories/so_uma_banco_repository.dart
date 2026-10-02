import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/so_uma_carta.dart';

class SoUmaBancoRepository {
  List<SoUmaCarta> _cartas = [];
  bool _carregado = false;

  bool get isCarregado => _carregado;
  List<SoUmaCarta> get cartas => List.unmodifiable(_cartas);

  Future<void> carregar() async {
    if (_carregado) return;

    final raw = await rootBundle.loadString('assets/so_uma_banco.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final lista = (json['cartas'] as List<dynamic>)
        .map((e) => SoUmaCarta.fromJson(e as Map<String, dynamic>))
        .toList();

    _cartas = lista;
    _carregado = true;
  }
}
