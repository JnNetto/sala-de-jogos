import '../../core/enums/papel.dart';

class JogadorPartida {
  final int id;
  final String nome;
  final Papel papel;
  final bool foiEliminado;

  JogadorPartida({
    required this.id,
    required this.nome,
    required this.papel,
    this.foiEliminado = false,
  });

  JogadorPartida copyWith({
    int? id,
    String? nome,
    Papel? papel,
    bool? foiEliminado,
  }) {
    return JogadorPartida(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      papel: papel ?? this.papel,
      foiEliminado: foiEliminado ?? this.foiEliminado,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'papel': papel.name,
      'foiEliminado': foiEliminado,
    };
  }

  factory JogadorPartida.fromJson(Map<String, dynamic> json) {
    return JogadorPartida(
      id: json['id'] as int,
      nome: json['nome'] as String,
      papel: Papel.values.firstWhere((e) => e.name == json['papel']),
      foiEliminado: json['foiEliminado'] as bool? ?? false,
    );
  }

  bool get isEspiao => papel == Papel.espiao;
  bool get isCivil => papel == Papel.civil;
  bool get estaAtivo => !foiEliminado;

  @override
  String toString() {
    return 'JogadorPartida(id: $id, nome: $nome, papel: ${papel.displayName}, eliminado: $foiEliminado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JogadorPartida && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
