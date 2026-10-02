import '../../core/enums/aneis_regiao.dart';

class AneisUltimaJogada {
  final String uid;
  final String nome;
  final String texto;
  final AneisRegiao regiaoEscolhida;
  final AneisRegiao regiaoCerta;
  final bool acertou;
  final int cartasRestantes;

  const AneisUltimaJogada({
    required this.uid,
    required this.nome,
    required this.texto,
    required this.regiaoEscolhida,
    required this.regiaoCerta,
    required this.acertou,
    required this.cartasRestantes,
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
    );
  }
}
