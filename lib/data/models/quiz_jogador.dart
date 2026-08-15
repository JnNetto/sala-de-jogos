class QuizJogador {
  final int id;
  final String nome;
  final int pontos;

  const QuizJogador({required this.id, required this.nome, this.pontos = 0});

  QuizJogador copyWith({int? id, String? nome, int? pontos}) {
    return QuizJogador(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      pontos: pontos ?? this.pontos,
    );
  }

  QuizJogador adicionarPontos(int delta) => copyWith(pontos: pontos + delta);
}
