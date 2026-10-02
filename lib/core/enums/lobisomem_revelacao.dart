enum LobisomemRevelacao {
  total,
  soEquipe,
  nenhuma;

  String get nome {
    switch (this) {
      case LobisomemRevelacao.total:
        return 'Total';
      case LobisomemRevelacao.soEquipe:
        return 'Só a equipe';
      case LobisomemRevelacao.nenhuma:
        return 'Nenhuma';
    }
  }

  String get descricao {
    switch (this) {
      case LobisomemRevelacao.total:
        return 'Ao morrer, o papel é anunciado';
      case LobisomemRevelacao.soEquipe:
        return 'Ao morrer, anuncia-se só Aldeia ou Lobisomens';
      case LobisomemRevelacao.nenhuma:
        return 'O papel permanece secreto até o fim';
    }
  }
}
