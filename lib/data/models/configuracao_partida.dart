class ConfiguracaoPartida {
  final int quantidadeJogadores;
  final int quantidadeEspioes;
  final bool espiaoVePalavraRelacionada;
  final int duracaoDiscussaoSegundos;
  final List<String> categoriasAtivasIds;
  final List<String> nomesJogadores;

  ConfiguracaoPartida({
    this.quantidadeJogadores = 4,
    this.quantidadeEspioes = 1,
    this.espiaoVePalavraRelacionada = true,
    this.duracaoDiscussaoSegundos = 300,
    this.categoriasAtivasIds = const [],
    this.nomesJogadores = const [],
  });

  ConfiguracaoPartida copyWith({
    int? quantidadeJogadores,
    int? quantidadeEspioes,
    bool? espiaoVePalavraRelacionada,
    int? duracaoDiscussaoSegundos,
    List<String>? categoriasAtivasIds,
    List<String>? nomesJogadores,
  }) {
    return ConfiguracaoPartida(
      quantidadeJogadores: quantidadeJogadores ?? this.quantidadeJogadores,
      quantidadeEspioes: quantidadeEspioes ?? this.quantidadeEspioes,
      espiaoVePalavraRelacionada:
          espiaoVePalavraRelacionada ?? this.espiaoVePalavraRelacionada,
      duracaoDiscussaoSegundos:
          duracaoDiscussaoSegundos ?? this.duracaoDiscussaoSegundos,
      categoriasAtivasIds: categoriasAtivasIds ?? this.categoriasAtivasIds,
      nomesJogadores: nomesJogadores ?? this.nomesJogadores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantidadeJogadores': quantidadeJogadores,
      'quantidadeEspioes': quantidadeEspioes,
      'espiaoVePalavraRelacionada': espiaoVePalavraRelacionada,
      'duracaoDiscussaoSegundos': duracaoDiscussaoSegundos,
      'categoriasAtivasIds': categoriasAtivasIds,
      'nomesJogadores': nomesJogadores,
    };
  }

  factory ConfiguracaoPartida.fromJson(Map<String, dynamic> json) {
    return ConfiguracaoPartida(
      quantidadeJogadores: json['quantidadeJogadores'] as int? ?? 4,
      quantidadeEspioes: json['quantidadeEspioes'] as int? ?? 1,
      espiaoVePalavraRelacionada:
          json['espiaoVePalavraRelacionada'] as bool? ?? true,
      duracaoDiscussaoSegundos: json['duracaoDiscussaoSegundos'] as int? ?? 300,
      categoriasAtivasIds:
          (json['categoriasAtivasIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      nomesJogadores:
          (json['nomesJogadores'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  bool isValid() {
    if (quantidadeJogadores < 4 || quantidadeJogadores > 12) return false;
    if (quantidadeEspioes < 1) return false;
    if (quantidadeEspioes > quantidadeJogadores - 3) return false;
    if (duracaoDiscussaoSegundos < 30) return false;
    return true;
  }

  String? getValidationError() {
    if (quantidadeJogadores < 4 || quantidadeJogadores > 12) {
      return 'Quantidade de jogadores deve estar entre 4 e 12';
    }
    if (quantidadeEspioes < 1) {
      return 'Deve haver pelo menos 1 espião';
    }
    if (quantidadeEspioes > quantidadeJogadores - 3) {
      return 'Quantidade de espiões não pode exceder jogadores - 3';
    }
    if (duracaoDiscussaoSegundos < 30) {
      return 'Duração da discussão deve ser de pelo menos 30 segundos';
    }
    return null;
  }

  @override
  String toString() {
    return 'ConfiguracaoPartida(jogadores: $quantidadeJogadores, espiões: $quantidadeEspioes, duração: ${duracaoDiscussaoSegundos}s)';
  }
}
