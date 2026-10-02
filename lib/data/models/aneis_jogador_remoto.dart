class AneisJogadorRemoto {
  final String uid;
  final String displayName;
  final int? seat;
  final int maoCount;

  const AneisJogadorRemoto({
    required this.uid,
    required this.displayName,
    this.seat,
    this.maoCount = 0,
  });

  factory AneisJogadorRemoto.fromMap(String uid, Map<String, dynamic> data) {
    return AneisJogadorRemoto(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'Jogador',
      seat: data['seat'] as int?,
      maoCount: data['maoCount'] as int? ?? 0,
    );
  }
}
