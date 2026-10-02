import '../../core/enums/so_uma_fase.dart';
import 'so_uma_carta.dart';
import 'so_uma_jogador.dart';
import 'so_uma_rodada.dart';

class SoUmaPartida {
  final List<SoUmaJogador> jogadores;
  final List<SoUmaCarta> baralho;
  final int adivinhadorIndex;
  final int cartasGanhas;
  final List<SoUmaRodada> historico;
  final SoUmaFase fase;
  final SoUmaRodada? rodadaAtual;

  const SoUmaPartida({
    required this.jogadores,
    required this.baralho,
    this.adivinhadorIndex = 0,
    this.cartasGanhas = 0,
    this.historico = const [],
    this.fase = SoUmaFase.escolhendoNumero,
    this.rodadaAtual,
  });

  SoUmaJogador get adivinhadorAtual => jogadores[adivinhadorIndex];
  int get quantidadeJogadores => jogadores.length;
  int get cartasRestantesBaralho => baralho.length;
  int get numeroRodadaAtual => historico.length + 1;

  List<SoUmaJogador> get escritores => jogadores
      .where((jogador) => jogador.id != adivinhadorAtual.id)
      .toList(growable: false);

  int get pistasEsperadas =>
      quantidadeJogadores == 3 ? escritores.length * 2 : escritores.length;

  SoUmaPartida copyWith({
    List<SoUmaCarta>? baralho,
    int? adivinhadorIndex,
    int? cartasGanhas,
    List<SoUmaRodada>? historico,
    SoUmaFase? fase,
    SoUmaRodada? rodadaAtual,
    bool limparRodadaAtual = false,
  }) {
    return SoUmaPartida(
      jogadores: jogadores,
      baralho: baralho ?? this.baralho,
      adivinhadorIndex: adivinhadorIndex ?? this.adivinhadorIndex,
      cartasGanhas: cartasGanhas ?? this.cartasGanhas,
      historico: historico ?? this.historico,
      fase: fase ?? this.fase,
      rodadaAtual: limparRodadaAtual ? null : rodadaAtual ?? this.rodadaAtual,
    );
  }
}
