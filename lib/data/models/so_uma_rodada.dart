import '../../core/enums/so_uma_resultado_rodada.dart';
import 'so_uma_carta.dart';
import 'so_uma_jogador.dart';
import 'so_uma_pista.dart';

class SoUmaRodada {
  final int numero;
  final SoUmaJogador adivinhador;
  final SoUmaCarta carta;
  final int numeroEscolhido;
  final String palavraAlvo;
  final List<SoUmaPista> pistas;
  final String? palpite;
  final SoUmaResultadoRodada? resultado;

  const SoUmaRodada({
    required this.numero,
    required this.adivinhador,
    required this.carta,
    required this.numeroEscolhido,
    required this.palavraAlvo,
    this.pistas = const [],
    this.palpite,
    this.resultado,
  });

  List<SoUmaPista> get pistasSobreviventes =>
      pistas.where((pista) => !pista.anulada).toList(growable: false);

  SoUmaRodada copyWith({
    List<SoUmaPista>? pistas,
    String? palpite,
    SoUmaResultadoRodada? resultado,
  }) {
    return SoUmaRodada(
      numero: numero,
      adivinhador: adivinhador,
      carta: carta,
      numeroEscolhido: numeroEscolhido,
      palavraAlvo: palavraAlvo,
      pistas: pistas ?? this.pistas,
      palpite: palpite ?? this.palpite,
      resultado: resultado ?? this.resultado,
    );
  }
}
