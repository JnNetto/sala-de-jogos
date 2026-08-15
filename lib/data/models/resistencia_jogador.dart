import '../../core/enums/resistencia_papel.dart';

class ResistenciaJogador {
  final String id;
  final String nome;
  final int? assento;
  final ResistenciaPapel? papel;

  const ResistenciaJogador({
    required this.id,
    required this.nome,
    this.assento,
    this.papel,
  });

  bool get temPapel => papel != null;

  ResistenciaJogador copyWith({
    String? id,
    String? nome,
    int? assento,
    ResistenciaPapel? papel,
  }) {
    return ResistenciaJogador(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      assento: assento ?? this.assento,
      papel: papel ?? this.papel,
    );
  }
}
