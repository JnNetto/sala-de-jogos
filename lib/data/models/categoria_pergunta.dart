class CategoriaPergunta {
  final String id;
  final String nome;
  final bool ativa;

  const CategoriaPergunta({
    required this.id,
    required this.nome,
    this.ativa = true,
  });
}
