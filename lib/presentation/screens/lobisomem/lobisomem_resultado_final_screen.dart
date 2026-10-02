import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/lobisomem_vencedor.dart';
import '../../providers/lobisomem_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'lobisomem_configuracao_screen.dart';

class LobisomemResultadoFinalScreen extends StatelessWidget {
  const LobisomemResultadoFinalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LobisomemPartidaProvider>();
    final partida = provider.partida;
    if (partida == null) {
      return const Scaffold(body: Center(child: Text('Partida não iniciada')));
    }

    final vencedor = partida.vencedor;
    final titulo = switch (vencedor) {
      LobisomemVencedor.aldeia => 'A Aldeia venceu',
      LobisomemVencedor.lobisomens => 'Os Lobisomens venceram',
      LobisomemVencedor.empate => 'Sem vencedores',
      LobisomemVencedor.bobo => 'O Bobo da Corte venceu',
      null => 'Fim de jogo',
    };
    final cor = switch (vencedor) {
      LobisomemVencedor.aldeia => Colors.blue,
      LobisomemVencedor.lobisomens => Colors.red,
      LobisomemVencedor.empate => Colors.grey,
      LobisomemVencedor.bobo => Colors.purple,
      null => Theme.of(context).colorScheme.primary,
    };

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fim de Jogo'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.emoji_events, size: 72, color: cor),
                      const SizedBox(height: 16),
                      Text(
                        titulo,
                        style: Theme.of(
                          context,
                        ).textTheme.displaySmall?.copyWith(color: cor),
                        textAlign: TextAlign.center,
                      ),
                      if (partida.boboVenceu &&
                          vencedor != LobisomemVencedor.bobo) ...[
                        const SizedBox(height: 12),
                        Text(
                          'O Bobo da Corte também venceu individualmente ao ser eliminado na votação.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Narrador: ${partida.narrador.nome}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Papéis da mesa',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      for (final jogador in partida.jogadores)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            jogador.ehLobisomem
                                ? Icons.nightlight_round
                                : jogador.ehBobo
                                ? Icons.theater_comedy
                                : Icons.cottage_outlined,
                            color: jogador.ehLobisomem
                                ? Colors.red
                                : jogador.ehBobo
                                ? Colors.purple
                                : Colors.blue,
                          ),
                          title: Text(jogador.nome),
                          subtitle: Text(
                            [
                              jogador.papel.nome,
                              jogador.equipe.nome,
                              if (jogador.ehNarrador) 'Narrador',
                              jogador.vivo ? 'vivo' : 'morto',
                            ].join(' · '),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Jogar novamente',
                icon: Icons.replay,
                onPressed: () {
                  provider.limparPartida();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LobisomemConfiguracaoScreen(),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  provider.limparPartida();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Voltar ao início'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
