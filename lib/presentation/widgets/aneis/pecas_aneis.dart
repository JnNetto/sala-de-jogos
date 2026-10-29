import '../../../data/models/aneis_jogador_remoto.dart';

/// O índice de cor de um jogador: o assento dele, ou a posição na lista.
int indiceDoJogador(List<AneisJogadorRemoto> jogadores, String? uid) {
  for (final (i, j) in jogadores.indexed) {
    if (j.uid == uid) return j.seat ?? i;
  }
  return 0;
}
