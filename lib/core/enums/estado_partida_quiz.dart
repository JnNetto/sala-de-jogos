enum EstadoPartidaQuiz {
  configuracao,
  passagem,
  categoria,
  pergunta,
  escolhaAlvo,
  passagemAlvo,
  perguntaAlvo,
  resumoRodada,
  resultado;

  String get displayName {
    switch (this) {
      case EstadoPartidaQuiz.configuracao:
        return 'Configuração';
      case EstadoPartidaQuiz.passagem:
        return 'Passagem';
      case EstadoPartidaQuiz.categoria:
        return 'Categoria';
      case EstadoPartidaQuiz.pergunta:
        return 'Pergunta';
      case EstadoPartidaQuiz.escolhaAlvo:
        return 'Escolher alvo';
      case EstadoPartidaQuiz.passagemAlvo:
        return 'Passagem do alvo';
      case EstadoPartidaQuiz.perguntaAlvo:
        return 'Resposta do alvo';
      case EstadoPartidaQuiz.resumoRodada:
        return 'Resumo';
      case EstadoPartidaQuiz.resultado:
        return 'Resultado';
    }
  }
}
