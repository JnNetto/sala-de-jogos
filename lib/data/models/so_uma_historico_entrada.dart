class SoUmaHistoricoEntrada {
  final int round;
  final List<String> palavras;
  final String palavraAlvo;
  final String guesserUid;
  final String? palpite;
  final String resultado;
  final int pontos;

  const SoUmaHistoricoEntrada({
    required this.round,
    required this.palavras,
    required this.palavraAlvo,
    required this.guesserUid,
    required this.palpite,
    required this.resultado,
    required this.pontos,
  });

  factory SoUmaHistoricoEntrada.fromMap(Map<String, dynamic> data) {
    return SoUmaHistoricoEntrada(
      round: data['round'] as int? ?? 0,
      palavras: (data['palavras'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      palavraAlvo: data['palavraAlvo'] as String? ?? '',
      guesserUid: data['guesserUid'] as String? ?? '',
      palpite: data['palpite'] as String?,
      resultado: data['resultado'] as String? ?? 'passou',
      pontos: data['pontos'] as int? ?? 0,
    );
  }
}
