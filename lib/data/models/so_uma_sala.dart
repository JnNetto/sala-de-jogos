class SoUmaSala {
  final String id;
  final String codigo;
  final String hostUid;
  final String status;
  final int playerCount;

  const SoUmaSala({
    required this.id,
    required this.codigo,
    required this.hostUid,
    required this.status,
    required this.playerCount,
  });

  factory SoUmaSala.fromMap(String id, Map<String, dynamic> data) {
    return SoUmaSala(
      id: id,
      codigo: data['code'] as String? ?? '',
      hostUid: data['hostUid'] as String? ?? '',
      status: data['status'] as String? ?? 'lobby',
      playerCount: data['playerCount'] as int? ?? 0,
    );
  }
}
