class ResistenciaPrivado {
  final String role;
  final String team;
  final List<Map<String, dynamic>> knowledge;

  const ResistenciaPrivado({
    required this.role,
    required this.team,
    required this.knowledge,
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
    );
  }
}
