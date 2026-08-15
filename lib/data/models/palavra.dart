class Palavra {
  final String id;
  final String categoriaId;
  final String palavraRelacionadaId;
  final String texto;

  Palavra({
    required this.id,
    required this.categoriaId,
    required this.palavraRelacionadaId,
    required this.texto,
  });

  Palavra copyWith({
    String? id,
    String? categoriaId,
    String? palavraRelacionadaId,
    String? texto,
  }) {
    return Palavra(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      palavraRelacionadaId: palavraRelacionadaId ?? this.palavraRelacionadaId,
      texto: texto ?? this.texto,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoriaId': categoriaId,
      'palavraRelacionadaId': palavraRelacionadaId,
      'texto': texto,
    };
  }

  factory Palavra.fromJson(Map<String, dynamic> json) {
    return Palavra(
      id: json['id'] as String,
      categoriaId: json['categoriaId'] as String,
      palavraRelacionadaId: json['palavraRelacionadaId'] as String,
      texto: json['texto'] as String,
    );
  }

  @override
  String toString() {
    return 'Palavra(id: $id, texto: $texto, categoriaId: $categoriaId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Palavra && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
