class ResistenciaPropostaRemota {
  final String id;
  final int round;
  final int attempt;
  final String leaderUid;
  final List<String> memberUids;
  final String status;
  final Map<String, bool>? votes;

  const ResistenciaPropostaRemota({
    required this.id,
    required this.round,
    required this.attempt,
    required this.leaderUid,
    required this.memberUids,
    required this.status,
    required this.votes,
  });

  factory ResistenciaPropostaRemota.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final rawVotes = data['votes'];
    return ResistenciaPropostaRemota(
      id: id,
      round: data['round'] as int? ?? 1,
      attempt: data['attempt'] as int? ?? 1,
      leaderUid: data['leaderUid'] as String? ?? '',
      memberUids: (data['memberUids'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      status: data['status'] as String? ?? 'voting',
      votes: rawVotes is Map
          ? rawVotes.map(
              (key, value) => MapEntry(key.toString(), value == true),
            )
          : null,
    );
  }

  bool get estaEmVotacao => status == 'voting';
  bool get aprovada => status == 'approved';
  bool get rejeitada => status == 'rejected';

  int get aprovacoes => votes?.values.where((voto) => voto).length ?? 0;

  int get rejeicoes => votes?.values.where((voto) => !voto).length ?? 0;
}
