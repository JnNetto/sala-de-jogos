import 'package:flutter/material.dart';

import '../constants/aneis_constants.dart';

enum AneisRegiao {
  nenhum,
  palavra,
  atributo,
  contexto,
  palavraAtributo,
  palavraContexto,
  atributoContexto,
  todos;

  String get id {
    switch (this) {
      case AneisRegiao.nenhum:
        return 'nenhum';
      case AneisRegiao.palavra:
        return 'palavra';
      case AneisRegiao.atributo:
        return 'atributo';
      case AneisRegiao.contexto:
        return 'contexto';
      case AneisRegiao.palavraAtributo:
        return 'palavra_atributo';
      case AneisRegiao.palavraContexto:
        return 'palavra_contexto';
      case AneisRegiao.atributoContexto:
        return 'atributo_contexto';
      case AneisRegiao.todos:
        return 'todos';
    }
  }

  String get rotulo {
    switch (this) {
      case AneisRegiao.nenhum:
        return 'Nenhum anel';
      case AneisRegiao.palavra:
        return 'Só Palavra';
      case AneisRegiao.atributo:
        return 'Só Atributo';
      case AneisRegiao.contexto:
        return 'Só Contexto';
      case AneisRegiao.palavraAtributo:
        return 'Palavra + Atributo';
      case AneisRegiao.palavraContexto:
        return 'Palavra + Contexto';
      case AneisRegiao.atributoContexto:
        return 'Atributo + Contexto';
      case AneisRegiao.todos:
        return 'Os três';
    }
  }

  bool get noPalavra =>
      this == AneisRegiao.palavra ||
      this == AneisRegiao.palavraAtributo ||
      this == AneisRegiao.palavraContexto ||
      this == AneisRegiao.todos;

  bool get noAtributo =>
      this == AneisRegiao.atributo ||
      this == AneisRegiao.palavraAtributo ||
      this == AneisRegiao.atributoContexto ||
      this == AneisRegiao.todos;

  bool get noContexto =>
      this == AneisRegiao.contexto ||
      this == AneisRegiao.palavraContexto ||
      this == AneisRegiao.atributoContexto ||
      this == AneisRegiao.todos;

  Color get cor {
    final cores = <Color>[];
    if (noPalavra) cores.add(AneisConstants.corPalavra);
    if (noAtributo) cores.add(AneisConstants.corAtributo);
    if (noContexto) cores.add(AneisConstants.corContexto);
    if (cores.isEmpty) return AneisConstants.corNenhum;
    if (cores.length == 1) return cores.first;
    return Color.lerp(cores.first, cores.last, 0.5) ?? cores.first;
  }

  bool get ehAnelExclusivo =>
      this == AneisRegiao.palavra ||
      this == AneisRegiao.atributo ||
      this == AneisRegiao.contexto;

  static AneisRegiao fromId(String? id) {
    return AneisRegiao.values.firstWhere(
      (regiao) => regiao.id == id,
      orElse: () => AneisRegiao.nenhum,
    );
  }

  static AneisRegiao fromCirculos({
    required bool palavra,
    required bool atributo,
    required bool contexto,
  }) {
    if (palavra && atributo && contexto) return AneisRegiao.todos;
    if (palavra && atributo) return AneisRegiao.palavraAtributo;
    if (palavra && contexto) return AneisRegiao.palavraContexto;
    if (atributo && contexto) return AneisRegiao.atributoContexto;
    if (palavra) return AneisRegiao.palavra;
    if (atributo) return AneisRegiao.atributo;
    if (contexto) return AneisRegiao.contexto;
    return AneisRegiao.nenhum;
  }
}
