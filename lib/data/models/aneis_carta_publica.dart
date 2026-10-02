class AneisCartaPublica {
  final String id;
  final String texto;

  const AneisCartaPublica({required this.id, required this.texto});

  factory AneisCartaPublica.fromMap(Map<String, dynamic> data) {
    return AneisCartaPublica(
      id: data['id'] as String? ?? '',
      texto: data['texto'] as String? ?? '',
    );
  }
}
