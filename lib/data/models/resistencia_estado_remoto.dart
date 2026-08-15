class ResistenciaEstadoRemoto {
  final String gameId;
  final String phase;
  final int round;
  final int attempt;
  final String leaderUid;
  final int teamSize;
  final List<bool> missionResults;
  final List<int> failCounts;
  final String? currentProposalId;
  final String? lastProposalId;
  final int submittedCount;
  final int expectedCount;
  final String? winner;
  final int playerCount;

  const ResistenciaEstadoRemoto({
    required this.gameId,
    required this.phase,
    required this.round,
    required this.attempt,
    required this.leaderUid,
    required this.teamSize,
    required this.missionResults,
    required this.failCounts,
    required this.currentProposalId,
    required this.lastProposalId,
    required this.submittedCount,
    required this.expectedCount,
    required this.winner,
    required this.playerCount,
  });

  factory ResistenciaEstadoRemoto.fromMap(Map<String, dynamic> data) {
    return ResistenciaEstadoRemoto(
      gameId: data['gameId'] as String? ?? '',
      phase: data['phase'] as String? ?? 'lobby',
      round: data['round'] as int? ?? 1,
      attempt: data['attempt'] as int? ?? 1,
      leaderUid: data['leaderUid'] as String? ?? '',
      teamSize: data['teamSize'] as int? ?? 0,
      missionResults: (data['missionResults'] as List<dynamic>? ?? const [])
          .whereType<bool>()
          .toList(growable: false),
      failCounts: (data['failCounts'] as List<dynamic>? ?? const [])
          .whereType<int>()
          .toList(growable: false),
      currentProposalId: data['currentProposalId'] as String?,
      lastProposalId: data['lastProposalId'] as String?,
      submittedCount: data['submittedCount'] as int? ?? 0,
      expectedCount: data['expectedCount'] as int? ?? 0,
      winner: data['winner'] as String?,
      playerCount: data['playerCount'] as int? ?? 0,
    );
  }

  int get successes => missionResults.where((result) => result).length;
  int get failures => missionResults.where((result) => !result).length;
}
