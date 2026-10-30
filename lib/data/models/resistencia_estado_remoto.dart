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

  /// Equipes recusadas na partida inteira (as tochas apagadas).
  final int rejections;
  final bool lanternUsed;

  /// Na fase "lantern": o guia que pode usar a Lanterna.
  final String? lanternHolderUid;

  /// Em quem a Lanterna foi usada (todos sabem; só o guia viu a carta).
  final String? lanternByUid;
  final String? lanternTargetUid;
  final int? lanternRound;

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
    this.rejections = 0,
    this.lanternUsed = false,
    this.lanternHolderUid,
    this.lanternByUid,
    this.lanternTargetUid,
    this.lanternRound,
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
      rejections: data['rejections'] as int? ?? 0,
      lanternUsed: data['lanternUsed'] as bool? ?? false,
      lanternHolderUid: data['lanternHolderUid'] as String?,
      lanternByUid: (data['lanternUse'] as Map?)?['byUid'] as String?,
      lanternTargetUid: (data['lanternUse'] as Map?)?['targetUid'] as String?,
      lanternRound: (data['lanternUse'] as Map?)?['round'] as int?,
    );
  }

  int get successes => missionResults.where((result) => result).length;
  int get failures => missionResults.where((result) => !result).length;
}
