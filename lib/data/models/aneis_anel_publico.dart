import 'package:flutter/material.dart';

class AneisAnelPublico {
  final String id;
  final String nome;
  final String subtitulo;
  final Color cor;

  const AneisAnelPublico({
    required this.id,
    required this.nome,
    required this.subtitulo,
    required this.cor,
  });

  factory AneisAnelPublico.fromMap(Map<String, dynamic> data) {
    return AneisAnelPublico(
      id: data['id'] as String? ?? '',
      nome: data['nome'] as String? ?? '',
      subtitulo: data['subtitulo'] as String? ?? '',
      cor: _parseCor(data['cor'] as String?),
    );
  }

  static Color _parseCor(String? value) {
    if (value == null || value.isEmpty) return const Color(0xFF64748B);
    final hex = value.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return const Color(0xFF64748B);
  }
}
