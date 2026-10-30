import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/resistencia_constants.dart';
import '../../../data/models/resistencia_jogador_remoto.dart';
import '../../../data/models/resistencia_sala.dart';
import '../../providers/resistencia_sala_provider.dart';
import '../../widgets/expedicao/pecas_expedicao.dart';
import '../../widgets/sala/sala_online.dart';
import 'expedicao_sala_router_screen.dart';

class ExpedicaoEntradaSalaScreen extends StatelessWidget {
  const ExpedicaoEntradaSalaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntradaSalaOnline(
      nomeDoJogo: ResistenciaConstants.jogoNome,
      matiz: matizExpedicao,
      sala: context.read<ResistenciaSalaProvider>(),
      chaveUltimaSala: ResistenciaSalaProvider.chaveUltimaSala,
      abrirSala: (restaurar) =>
          ExpedicaoSalaRouterScreen(restaurarUltimaSala: restaurar),
    );
  }
}

class ExpedicaoLobbyRemotoScreen extends StatelessWidget {
  const ExpedicaoLobbyRemotoScreen({
    super.key,
    required this.sala,
    required this.jogadores,
  });

  final ResistenciaSala sala;
  final List<ResistenciaJogadorRemoto> jogadores;

  @override
  Widget build(BuildContext context) {
    return LobbyOnline(
      nomeDoJogo: ResistenciaConstants.jogoNome,
      matiz: matizExpedicao,
      sala: context.watch<ResistenciaSalaProvider>(),
      codigo: sala.codigo,
      hostUid: sala.hostUid,
      jogadores: [
        for (final (i, j) in jogadores.indexed)
          (uid: j.uid, nome: j.displayName, indice: j.seat ?? i),
      ],
      minimo: ResistenciaConstants.minJogadores,
      maximo: ResistenciaConstants.maxJogadores,
      enquantoEspera:
          'Cada um recebe um papel em segredo: explorador ou saqueador. A '
          'cada câmara, o guia monta a equipe e todos votam. Quem entra '
          'joga Avançar ou Armadilha. Três câmaras decidem a partida.',
    );
  }
}
