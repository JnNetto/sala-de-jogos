import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../../data/models/so_uma_jogador_remoto.dart';
import '../../../data/models/so_uma_sala.dart';
import '../../providers/so_uma_sala_provider.dart';
import '../../widgets/sala/sala_online.dart';
import '../../widgets/so_uma/pecas_so_uma.dart';

class SoUmaLobbyRemotoScreen extends StatelessWidget {
  const SoUmaLobbyRemotoScreen({
    super.key,
    required this.sala,
    required this.jogadores,
  });

  final SoUmaSala sala;
  final List<SoUmaJogadorRemoto> jogadores;

  @override
  Widget build(BuildContext context) {
    return LobbyOnline(
      nomeDoJogo: SoUmaConstants.jogoNome,
      matiz: matizSoUma,
      sala: context.watch<SoUmaSalaProvider>(),
      codigo: sala.codigo,
      hostUid: sala.hostUid,
      jogadores: [
        for (final (i, j) in jogadores.indexed)
          (uid: j.uid, nome: j.displayName, indice: j.seat ?? i),
      ],
      minimo: SoUmaConstants.minJogadores,
      maximo: SoUmaConstants.maxJogadores,
      enquantoEspera:
          'A cada rodada, um adivinha e os outros mandam uma pista de uma '
          'palavra só, cada um do seu celular. Pistas iguais se anulam. '
          'Juntos, tentem ganhar as 13 cartas.',
    );
  }
}
