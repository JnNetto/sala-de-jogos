class AneisPendingJogada {
  final String uid;
  final String nome;
  final String coisaId;
  final String texto;
  final String regiaoEscolhida;

  const AneisPendingJogada({
    required this.uid,
    required this.nome,
    required this.coisaId,
    required this.texto,
    required this.regiaoEscolhida,
  });

  factory AneisPendingJogada.fromMap(Map<String, dynamic> data) {
    return AneisPendingJogada(
      uid: data['uid'] as String? ?? '',
      nome: data['nome'] as String? ?? 'Jogador',
      coisaId: data['coisaId'] as String? ?? '',
      texto: data['texto'] as String? ?? '',
      regiaoEscolhida: data['regiaoEscolhida'] as String? ?? 'nenhum',
    );
  }
}
