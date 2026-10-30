class ResistenciaPrivado {
  final String role;
  final String team;
  final List<Map<String, dynamic>> knowledge;

  /// O que a Lanterna mostrou para este jogador, se ele a usou.
  final String? lanternaAlvoUid;
  final bool? lanternaCarta;

  const ResistenciaPrivado({
    required this.role,
    required this.team,
    required this.knowledge,
    this.lanternaAlvoUid,
    this.lanternaCarta,
  });

  factory ResistenciaPrivado.fromMap(Map<String, dynamic> data) {
    final rawKnowledge = data['knowledge'] as List<dynamic>? ?? const [];
    return ResistenciaPrivado(
      role: data['role'] as String? ?? 'resistance',
      team: data['team'] as String? ?? 'good',
      knowledge: rawKnowledge
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false),
      lanternaAlvoUid: (data['lantern'] as Map?)?['targetUid'] as String?,
      lanternaCarta: (data['lantern'] as Map?)?['success'] as bool?,
    );
  }
}
