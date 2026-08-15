class MudancaPontosQuiz {
  final int jogadorId;
  final String nome;
  final int delta;

  const MudancaPontosQuiz({
    required this.jogadorId,
    required this.nome,
    required this.delta,
  });
}

class ResultadoRodadaQuiz {
  final String jogadorRodadaNome;
  final String respondenteNome;
  final bool passou;
  final bool acertou;
  final String pergunta;
  final String respostaCorreta;
  final String? explicacao;
  final List<MudancaPontosQuiz> mudancas;
  final String mensagem;

  const ResultadoRodadaQuiz({
    required this.jogadorRodadaNome,
    required this.respondenteNome,
    required this.passou,
    required this.acertou,
    required this.pergunta,
    required this.respostaCorreta,
    this.explicacao,
    required this.mudancas,
    required this.mensagem,
  });
}
