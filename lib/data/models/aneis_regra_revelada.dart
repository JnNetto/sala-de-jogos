import 'package:flutter/material.dart';

class AneisRegraRevelada {
  final String anel;
  final String nome;
  final String texto;
  final Color cor;

  const AneisRegraRevelada({
    required this.anel,
    required this.nome,
    required this.texto,
    required this.cor,
  });

  factory AneisRegraRevelada.fromMap(Map<String, dynamic> data) {
    return AneisRegraRevelada(
      anel: data['anel'] as String? ?? '',
      nome: data['nome'] as String? ?? '',
      texto: data['texto'] as String? ?? '',
      cor: _parseCor(data['cor'] as String?),
    );
  }

  static Color _parseCor(String? value) {
    if (value == null || value.isEmpty) return const Color(0xFF64748B);
    final hex = value.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFF64748B);
  }
}
