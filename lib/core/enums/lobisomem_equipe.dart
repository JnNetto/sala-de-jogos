enum LobisomemEquipe {
  aldeia,
  lobisomens,
  neutro;

  String get nome {
    switch (this) {
      case LobisomemEquipe.aldeia:
        return 'Aldeia';
      case LobisomemEquipe.lobisomens:
        return 'Lobisomens';
      case LobisomemEquipe.neutro:
        return 'Neutro';
    }
  }
}
