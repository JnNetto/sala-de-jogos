import '../../core/enums/aneis_regiao.dart';

class AneisCartaTabuleiro {
  final String coisaId;
  final String texto;
  final AneisRegiao regiao;

  const AneisCartaTabuleiro({
    required this.coisaId,
    required this.texto,
    required this.regiao,
  });

  factory AneisCartaTabuleiro.fromMap(Map<String, dynamic> data) {
    return AneisCartaTabuleiro(
      coisaId: data['coisaId'] as String? ?? '',
      texto: data['texto'] as String? ?? '',
      regiao: AneisRegiao.fromId(data['regiao'] as String?),
    );
  }
}
