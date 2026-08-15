enum EstadoPartidaPergunta {
  configuracao,
  distribuicaoPerguntas,
  coletaRespostas,
  revelacaoRespostas,
  discussao,
  votacao,
  resultado;

  String get displayName {
    switch (this) {
      case EstadoPartidaPergunta.configuracao:
        return 'Configuração';
      case EstadoPartidaPergunta.distribuicaoPerguntas:
        return 'Distribuição';
      case EstadoPartidaPergunta.coletaRespostas:
        return 'Respostas';
      case EstadoPartidaPergunta.revelacaoRespostas:
        return 'Revelação';
      case EstadoPartidaPergunta.discussao:
        return 'Discussão';
      case EstadoPartidaPergunta.votacao:
        return 'Votação';
      case EstadoPartidaPergunta.resultado:
        return 'Resultado';
    }
  }
}
