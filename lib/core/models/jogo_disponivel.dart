import 'package:flutter/material.dart';

class JogoDisponivel {
  final String id;
  final String nome;
  final String descricao;
  final IconData icone;
  final Color cor;
  final bool disponivel;

  const JogoDisponivel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.cor,
    this.disponivel = true,
  });
}
