enum EstadoPartida {
  configuracao,
  distribuicaoPapeis,
  discussao,
  votacao,
  resultado;

  String get displayName {
    switch (this) {
      case EstadoPartida.configuracao:
        return 'Configuração';
      case EstadoPartida.distribuicaoPapeis:
        return 'Distribuição de Papéis';
      case EstadoPartida.discussao:
        return 'Discussão';
      case EstadoPartida.votacao:
        return 'Votação';
      case EstadoPartida.resultado:
        return 'Resultado';
    }
  }
}
