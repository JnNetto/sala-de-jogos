class Estatisticas {
  final int partidasJogadas;
  final int vitoriasCivis;
  final int vitoriasEspioes;
  final double tempoMedioPartidaSegundos;

  Estatisticas({
    this.partidasJogadas = 0,
    this.vitoriasCivis = 0,
    this.vitoriasEspioes = 0,
    this.tempoMedioPartidaSegundos = 0.0,
  });

  Estatisticas copyWith({
    int? partidasJogadas,
    int? vitoriasCivis,
    int? vitoriasEspioes,
    double? tempoMedioPartidaSegundos,
  }) {
    return Estatisticas(
      partidasJogadas: partidasJogadas ?? this.partidasJogadas,
      vitoriasCivis: vitoriasCivis ?? this.vitoriasCivis,
      vitoriasEspioes: vitoriasEspioes ?? this.vitoriasEspioes,
      tempoMedioPartidaSegundos:
          tempoMedioPartidaSegundos ?? this.tempoMedioPartidaSegundos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partidasJogadas': partidasJogadas,
      'vitoriasCivis': vitoriasCivis,
      'vitoriasEspioes': vitoriasEspioes,
      'tempoMedioPartidaSegundos': tempoMedioPartidaSegundos,
    };
  }

  factory Estatisticas.fromJson(Map<String, dynamic> json) {
    return Estatisticas(
      partidasJogadas: json['partidasJogadas'] as int? ?? 0,
      vitoriasCivis: json['vitoriasCivis'] as int? ?? 0,
      vitoriasEspioes: json['vitoriasEspioes'] as int? ?? 0,
      tempoMedioPartidaSegundos:
          (json['tempoMedioPartidaSegundos'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Estatisticas registrarPartida({
    required bool civisVenceram,
    required int duracaoSegundos,
  }) {
    final novasPartidas = partidasJogadas + 1;
    final novasVitoriasCivis = civisVenceram
        ? vitoriasCivis + 1
        : vitoriasCivis;
    final novasVitoriasEspioes = !civisVenceram
        ? vitoriasEspioes + 1
        : vitoriasEspioes;

    final novoTempoMedio =
        ((tempoMedioPartidaSegundos * partidasJogadas) + duracaoSegundos) /
        novasPartidas;

    return copyWith(
      partidasJogadas: novasPartidas,
      vitoriasCivis: novasVitoriasCivis,
      vitoriasEspioes: novasVitoriasEspioes,
      tempoMedioPartidaSegundos: novoTempoMedio,
    );
  }

  double get percentualVitoriasCivis {
    if (partidasJogadas == 0) return 0.0;
    return (vitoriasCivis / partidasJogadas) * 100;
  }

  double get percentualVitoriasEspioes {
    if (partidasJogadas == 0) return 0.0;
    return (vitoriasEspioes / partidasJogadas) * 100;
  }

  String get tempoMedioFormatado {
    final minutos = (tempoMedioPartidaSegundos / 60).floor();
    final segundos = (tempoMedioPartidaSegundos % 60).floor();
    return '$minutos:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Estatisticas(partidas: $partidasJogadas, civis: $vitoriasCivis, espiões: $vitoriasEspioes)';
  }
}
