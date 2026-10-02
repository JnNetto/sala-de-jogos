import 'so_uma_historico_entrada.dart';

class SoUmaEstadoRemoto {
  final String gameId;
  final int round;
  final String guesserUid;
  final String? currentRoundId;
  final String phase;
  final int deckRemaining;
  final int submittedCount;
  final int expectedCount;
  final List<String> pistasReveladas;
  final int cartasGanhas;
  final List<SoUmaHistoricoEntrada> historico;
  final int playerCount;

  const SoUmaEstadoRemoto({
    required this.gameId,
    required this.round,
    required this.guesserUid,
    required this.currentRoundId,
    required this.phase,
    required this.deckRemaining,
    required this.submittedCount,
    required this.expectedCount,
    required this.pistasReveladas,
    required this.cartasGanhas,
    required this.historico,
    required this.playerCount,
  });

  factory SoUmaEstadoRemoto.fromMap(Map<String, dynamic> data) {
    final rawHistorico = data['historico'] as List<dynamic>? ?? const [];
    return SoUmaEstadoRemoto(
      gameId: data['gameId'] as String? ?? '',
      round: data['round'] as int? ?? 0,
      guesserUid: data['guesserUid'] as String? ?? '',
      currentRoundId: data['currentRoundId'] as String?,
      phase: data['phase'] as String? ?? 'drawing',
      deckRemaining: data['deckRemaining'] as int? ?? 0,
      submittedCount: data['submittedCount'] as int? ?? 0,
      expectedCount: data['expectedCount'] as int? ?? 0,
      pistasReveladas: (data['pistasReveladas'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      cartasGanhas: data['cartasGanhas'] as int? ?? 0,
      historico: rawHistorico
          .whereType<Map>()
          .map(
            (item) =>
                SoUmaHistoricoEntrada.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      playerCount: data['playerCount'] as int? ?? 0,
    );
  }
}
