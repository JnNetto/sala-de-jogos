import '../../core/enums/aneis_regiao.dart';

class AneisUltimaJogada {
  final String uid;
  final String nome;
  final String texto;
  final AneisRegiao regiaoEscolhida;
  final AneisRegiao regiaoCerta;
  final bool acertou;
  final int cartasRestantes;

  /// "carta" (posicionou uma carta) ou "regra" (tentou desvendar um anel).
  final String tipo;

  /// No "regra": o anel e o palpite.
  final String? anel;
  final String? palpite;

  bool get desvendar => tipo == 'regra';

  const AneisUltimaJogada({
    required this.uid,
    required this.nome,
    required this.texto,
    required this.regiaoEscolhida,
    required this.regiaoCerta,
    required this.acertou,
    required this.cartasRestantes,
    this.tipo = 'carta',
    this.anel,
    this.palpite,
  });

  factory AneisUltimaJogada.fromMap(Map<String, dynamic> data) {
    return AneisUltimaJogada(
      uid: data['uid'] as String? ?? '',
      nome: data['nome'] as String? ?? 'Jogador',
      texto: data['texto'] as String? ?? '',
      regiaoEscolhida: AneisRegiao.fromId(data['regiaoEscolhida'] as String?),
      regiaoCerta: AneisRegiao.fromId(data['regiaoCerta'] as String?),
      acertou: data['acertou'] as bool? ?? false,
      cartasRestantes: data['cartasRestantes'] as int? ?? 0,
      tipo: data['tipo'] as String? ?? 'carta',
      anel: data['anel'] as String?,
      palpite: data['palpite'] as String?,
    );
  }
}
