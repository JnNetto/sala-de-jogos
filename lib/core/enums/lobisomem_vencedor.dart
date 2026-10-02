enum LobisomemVencedor {
  aldeia,
  lobisomens,
  empate,
  bobo;

  String get nome {
    switch (this) {
      case LobisomemVencedor.aldeia:
        return 'Aldeia';
      case LobisomemVencedor.lobisomens:
        return 'Lobisomens';
      case LobisomemVencedor.empate:
        return 'Empate';
      case LobisomemVencedor.bobo:
        return 'Bobo da Corte';
    }
  }
}
