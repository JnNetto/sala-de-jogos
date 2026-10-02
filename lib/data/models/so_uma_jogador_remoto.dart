class SoUmaJogadorRemoto {
  final String uid;
  final String displayName;
  final int? seat;

  const SoUmaJogadorRemoto({
    required this.uid,
    required this.displayName,
    this.seat,
  });

  factory SoUmaJogadorRemoto.fromMap(String uid, Map<String, dynamic> data) {
    return SoUmaJogadorRemoto(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'Jogador',
      seat: data['seat'] as int?,
    );
  }
}
