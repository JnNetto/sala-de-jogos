class AneisSala {
  final String id;
  final String codigo;
  final String hostUid;
  final String status;
  final int playerCount;

  const AneisSala({
    required this.id,
    required this.codigo,
    required this.hostUid,
    required this.status,
    required this.playerCount,
  });

  factory AneisSala.fromMap(String id, Map<String, dynamic> data) {
    return AneisSala(
      id: id,
      codigo: data['code'] as String? ?? '',
      hostUid: data['hostUid'] as String? ?? '',
      status: data['status'] as String? ?? 'lobby',
      playerCount: data['playerCount'] as int? ?? 0,
    );
  }
}
