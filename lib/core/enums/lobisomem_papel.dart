import 'lobisomem_equipe.dart';

enum LobisomemPapel {
  aldeao,
  lobisomem,
  vidente,
  bruxa,
  cacador,
  bobo,
  anciao;

  bool get ehLobisomem => this == LobisomemPapel.lobisomem;

  bool get ehEspecial =>
      this == LobisomemPapel.vidente ||
      this == LobisomemPapel.bruxa ||
      this == LobisomemPapel.cacador ||
      this == LobisomemPapel.bobo ||
      this == LobisomemPapel.anciao;

  bool get temAcaoNoturna =>
      this == LobisomemPapel.lobisomem ||
      this == LobisomemPapel.vidente ||
      this == LobisomemPapel.bruxa;

  LobisomemEquipe get equipe {
    switch (this) {
      case LobisomemPapel.lobisomem:
        return LobisomemEquipe.lobisomens;
      case LobisomemPapel.bobo:
        return LobisomemEquipe.neutro;
      case LobisomemPapel.aldeao:
      case LobisomemPapel.vidente:
      case LobisomemPapel.bruxa:
      case LobisomemPapel.cacador:
      case LobisomemPapel.anciao:
        return LobisomemEquipe.aldeia;
    }
  }

  String get nome {
    switch (this) {
      case LobisomemPapel.aldeao:
        return 'Aldeão';
      case LobisomemPapel.lobisomem:
        return 'Lobisomem';
      case LobisomemPapel.vidente:
        return 'Vidente';
      case LobisomemPapel.bruxa:
        return 'Bruxa';
      case LobisomemPapel.cacador:
        return 'Caçador';
      case LobisomemPapel.bobo:
        return 'Bobo da Corte';
      case LobisomemPapel.anciao:
        return 'Ancião';
    }
  }

  String get descricao {
    switch (this) {
      case LobisomemPapel.aldeao:
        return 'Discuta, observe e vote. Você não age durante a Noite.';
      case LobisomemPapel.lobisomem:
        return 'Com a alcateia, escolha uma vítima a cada Noite. Não ataquem um companheiro.';
      case LobisomemPapel.vidente:
        return 'A cada Noite, aponte alguém vivo e descubra se é Lobisomem.';
      case LobisomemPapel.bruxa:
        return 'Você tem uma cura e um veneno. Pode guardar, usar uma ou as duas na mesma Noite.';
      case LobisomemPapel.cacador:
        return 'Ao morrer, escolha imediatamente outra pessoa viva para cair com você.';
      case LobisomemPapel.bobo:
        return 'Você vence sozinho se a aldeia te eliminar na votação. Se morrer à noite, não ganha.';
      case LobisomemPapel.anciao:
        return 'Sobrevive ao primeiro ataque dos lobisomens e morre no segundo. Outras mortes te eliminam normalmente.';
    }
  }

  static const List<LobisomemPapel> especiaisDisponiveis = [
    LobisomemPapel.vidente,
    LobisomemPapel.bruxa,
    LobisomemPapel.cacador,
    LobisomemPapel.bobo,
    LobisomemPapel.anciao,
  ];
}
