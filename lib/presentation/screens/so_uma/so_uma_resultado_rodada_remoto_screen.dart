import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/so_uma_estado_remoto.dart';
import '../../../data/models/so_uma_historico_entrada.dart';
import '../../providers/so_uma_sala_provider.dart';
import '../../widgets/primary_button.dart';
import 'so_uma_sala_router_screen.dart';

class SoUmaResultadoRodadaRemotoScreen extends StatelessWidget {
  const SoUmaResultadoRodadaRemotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resultado da Rodada'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Consumer<SoUmaSalaProvider>(
            builder: (context, provider, _) {
              return StreamBuilder<SoUmaEstadoRemoto?>(
                stream: provider.observarEstadoAtual(),
                initialData: provider.estado,
                builder: (context, estadoSnapshot) {
                  final estado = estadoSnapshot.data;
                  if (estado == null || estado.historico.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final rodada = estado.historico.last;
                  final cor = switch (rodada.resultado) {
                    'acerto' => Colors.green,
                    'erro' => Colors.red,
                    _ => Colors.orange,
                  };
                  final icone = switch (rodada.resultado) {
                    'acerto' => Icons.emoji_events,
                    'erro' => Icons.close,
                    _ => Icons.skip_next,
                  };
                  final titulo = switch (rodada.resultado) {
                    'acerto' => 'Acertou!',
                    'erro' => 'Errou',
                    _ => 'Passou',
                  };

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(icone, size: 64, color: cor),
                              const SizedBox(height: 12),
                              Text(
                                titulo,
                                style: Theme.of(context).textTheme.displaySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'A palavra era "${rodada.palavraAlvo}".',
                                textAlign: TextAlign.center,
                              ),
                              if (rodada.palpite != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'A resposta foi "${rodada.palpite}".',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CartaRevelada(rodada: rodada),
                      const SizedBox(height: 16),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Placar',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '${estado.cartasGanhas} carta${estado.cartasGanhas == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: estado.phase == 'over'
                            ? 'Ver Resultado Final'
                            : 'Próxima Carta',
                        icon: Icons.arrow_forward,
                        onPressed: () => _continuar(context, provider, estado),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _continuar(
    BuildContext context,
    SoUmaSalaProvider provider,
    SoUmaEstadoRemoto estado,
  ) async {
    final sala = provider.sala;
    if (sala == null) return;
    await provider.marcarResultadoRodadaVisto(
      roomId: sala.id,
      gameId: estado.gameId,
      quantidadeHistorico: estado.historico.length,
    );
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SoUmaSalaRouterScreen()),
    );
  }
}

class _CartaRevelada extends StatelessWidget {
  final SoUmaHistoricoEntrada rodada;

  const _CartaRevelada({required this.rodada});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A carta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (var i = 0; i < rodada.palavras.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${i + 1}. ${rodada.palavras[i]}',
                  style: rodada.palavras[i] == rodada.palavraAlvo
                      ? Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Theme.of(context).textTheme.bodyLarge,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
