class ParPerguntas {
  final int id;
  final String categoriaId;
  final int nivel;
  final String principal;
  final String impostor;
  final String eixo;

  const ParPerguntas({
    required this.id,
    required this.categoriaId,
    required this.nivel,
    required this.principal,
    required this.impostor,
    required this.eixo,
  });

  factory ParPerguntas.fromJson(Map<String, dynamic> json) {
    return ParPerguntas(
      id: json['id'] as int,
      categoriaId: json['categoria'] as String,
      nivel: json['nivel'] as int? ?? 2,
      principal: json['principal'] as String,
      impostor: json['impostor'] as String,
      eixo: json['eixo'] as String? ?? '',
    );
  }

  String get idString => id.toString();
}
