import 'package:flutter/widgets.dart';

import '../theme/sala_tokens.dart';

class JogoDisponivel {
  final String id;
  final String nome;

  /// Uma linha, no tom de anfitrião: "Missões, votos e traidores."
  final String descricao;
  final IconData icone;

  /// A luz do jogo: substitui a primária dentro das telas dele.
  final Matiz matiz;
  final int minJogadores;
  final int maxJogadores;
  final int duracaoMinutos;

  /// Jogos novos sobem para o topo da home com a tag "NOVO".
  final bool novo;
  final bool disponivel;

  const JogoDisponivel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.matiz,
    required this.minJogadores,
    required this.maxJogadores,
    required this.duracaoMinutos,
    this.novo = false,
    this.disponivel = true,
  });
}
