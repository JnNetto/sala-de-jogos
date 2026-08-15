class ResistenciaJogadorRemoto {
  final String uid;
  final String displayName;
  final int? seat;
  final String? revealedRole;
  final String? revealedTeam;

  const ResistenciaJogadorRemoto({
    required this.uid,
    required this.displayName,
    this.seat,
    this.revealedRole,
    this.revealedTeam,
  });

  factory ResistenciaJogadorRemoto.fromMap(
    String uid,
    Map<String, dynamic> data,
  ) {
    return ResistenciaJogadorRemoto(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'Jogador',
      seat: data['seat'] as int?,
      revealedRole: data['revealedRole'] as String?,
      revealedTeam: data['revealedTeam'] as String?,
    );
  }
}
