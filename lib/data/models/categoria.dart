class Categoria {
  final String id;
  final String nome;
  final String? descricao;
  final bool ativa;

  Categoria({
    required this.id,
    required this.nome,
    this.descricao,
    this.ativa = true,
  });

  Categoria copyWith({
    String? id,
    String? nome,
    String? descricao,
    bool? ativa,
  }) {
    return Categoria(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativa: ativa ?? this.ativa,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'descricao': descricao, 'ativa': ativa};
  }

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      ativa: json['ativa'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'Categoria(id: $id, nome: $nome, ativa: $ativa)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categoria && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
