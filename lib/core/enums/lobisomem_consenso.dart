enum LobisomemConsenso {
  semAtaqueSeDivergirem,
  maioriaSimples;

  String get nome {
    switch (this) {
      case LobisomemConsenso.semAtaqueSeDivergirem:
        return 'Consenso total';
      case LobisomemConsenso.maioriaSimples:
        return 'Maioria simples';
    }
  }

  String get descricao {
    switch (this) {
      case LobisomemConsenso.semAtaqueSeDivergirem:
        return 'Se os lobisomens divergirem, não há ataque.';
      case LobisomemConsenso.maioriaSimples:
        return 'Vale o alvo com mais votos. Empate: sem ataque.';
    }
  }
}
