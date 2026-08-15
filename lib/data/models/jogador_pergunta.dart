import '../../core/enums/papel.dart';

class JogadorPergunta {
  final int id;
  final String nome;
  final Papel papel;
  final String? resposta;
  final bool foiEliminado;

  const JogadorPergunta({
    required this.id,
    required this.nome,
    required this.papel,
    this.resposta,
    this.foiEliminado = false,
  });

  bool get isEspiao => papel == Papel.espiao;
  bool get isCivil => papel == Papel.civil;
  bool get estaAtivo => !foiEliminado;
  bool get temResposta => resposta != null && resposta!.trim().isNotEmpty;

  JogadorPergunta copyWith({
    int? id,
    String? nome,
    Papel? papel,
    String? resposta,
    bool? foiEliminado,
    bool limparResposta = false,
  }) {
    return JogadorPergunta(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      papel: papel ?? this.papel,
      resposta: limparResposta ? null : (resposta ?? this.resposta),
      foiEliminado: foiEliminado ?? this.foiEliminado,
    );
  }
}
