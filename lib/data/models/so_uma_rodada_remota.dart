import 'so_uma_pista_remota.dart';

class SoUmaRodadaRemota {
  final String id;
  final String guesserUid;
  final List<String> palavras;
  final int mysteryIndex;
  final String palavraAlvo;
  final List<SoUmaPistaRemota> clues;

  const SoUmaRodadaRemota({
    required this.id,
    required this.guesserUid,
    required this.palavras,
    required this.mysteryIndex,
    required this.palavraAlvo,
    required this.clues,
  });

  factory SoUmaRodadaRemota.fromMap(String id, Map<String, dynamic> data) {
    final rawClues = data['clues'] as List<dynamic>? ?? const [];
    return SoUmaRodadaRemota(
      id: id,
      guesserUid: data['guesserUid'] as String? ?? '',
      palavras: (data['palavras'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      mysteryIndex: data['mysteryIndex'] as int? ?? 0,
      palavraAlvo: data['palavraAlvo'] as String? ?? '',
      clues: rawClues
          .whereType<Map>()
          .map(
            (item) => SoUmaPistaRemota.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }

  List<SoUmaPistaRemota> get sobreviventes =>
      clues.where((clue) => !clue.anulada).toList(growable: false);
}
