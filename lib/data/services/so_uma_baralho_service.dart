import 'dart:math';

import '../../core/constants/so_uma_constants.dart';
import '../models/so_uma_carta.dart';
import '../models/so_uma_jogador.dart';

class SoUmaBaralho {
  final List<SoUmaJogador> jogadores;
  final List<SoUmaCarta> cartas;

  const SoUmaBaralho({required this.jogadores, required this.cartas});
}

class SoUmaBaralhoService {
  final Random _random;

  SoUmaBaralhoService({Random? random}) : _random = random ?? Random();

  SoUmaBaralho montar({
    required List<SoUmaJogador> jogadores,
    required List<SoUmaCarta> banco,
  }) {
    if (jogadores.length < SoUmaConstants.minJogadores ||
        jogadores.length > SoUmaConstants.maxJogadores) {
      throw ArgumentError('Só uma! precisa de 3 a 7 jogadores');
    }
    if (banco.length < SoUmaConstants.totalCartasPartida) {
      throw ArgumentError('O banco de cartas precisa ter pelo menos 13 cartas');
    }

    final jogadoresEmbaralhados = List<SoUmaJogador>.from(jogadores)
      ..shuffle(_random);
    final bancoEmbaralhado = List<SoUmaCarta>.from(banco)..shuffle(_random);
    final cartasDaPartida = bancoEmbaralhado
        .take(SoUmaConstants.totalCartasPartida)
        .toList(growable: false);

    return SoUmaBaralho(
      jogadores: List.unmodifiable(jogadoresEmbaralhados),
      cartas: List.unmodifiable(cartasDaPartida),
    );
  }
}
