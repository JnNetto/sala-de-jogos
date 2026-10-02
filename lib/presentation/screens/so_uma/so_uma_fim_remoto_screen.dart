import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../../data/models/so_uma_estado_remoto.dart';
import '../../../data/models/so_uma_jogador_remoto.dart';
import '../../../data/models/so_uma_sala.dart';
import '../../providers/so_uma_sala_provider.dart';
import '../../widgets/primary_button.dart';
import 'so_uma_lobby_remoto_screen.dart';

class SoUmaFimRemotoScreen extends StatelessWidget {
  const SoUmaFimRemotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fim de Jogo'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Consumer<SoUmaSalaProvider>(
            builder: (context, provider, _) {
              return StreamBuilder<SoUmaSala?>(
                stream: provider.observarSalaAtual(),
                initialData: provider.sala,
                builder: (context, salaSnapshot) {
                  final sala = salaSnapshot.data;
                  _navegarSeVoltouAoLobby(context, sala);

                  return StreamBuilder<SoUmaEstadoRemoto?>(
                    stream: provider.observarEstadoAtual(),
                    initialData: provider.estado,
                    builder: (context, estadoSnapshot) {
                      final estado = estadoSnapshot.data;
                      if (estado == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return StreamBuilder<List<SoUmaJogadorRemoto>>(
                        stream: provider.observarJogadoresAtuais(),
                        initialData: provider.jogadores,
                        builder: (context, jogadoresSnapshot) {
                          final jogadores =
                              jogadoresSnapshot.data ?? provider.jogadores;
                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _PlacarFinal(estado: estado),
                              const SizedBox(height: 16),
                              _RodadaARodada(
                                estado: estado,
                                jogadores: jogadores,
                              ),
                              const SizedBox(height: 16),
                              _VoltarLobbyCard(provider: provider),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _navegarSeVoltouAoLobby(BuildContext context, SoUmaSala? sala) {
    if (sala?.status != 'lobby') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SoUmaLobbyRemotoScreen()),
      );
    });
  }
}

class _PlacarFinal extends StatelessWidget {
  final SoUmaEstadoRemoto estado;

  const _PlacarFinal({required this.estado});

  @override
  Widget build(BuildContext context) {
    final faixa = SoUmaConstants.faixaDesempenho(estado.cartasGanhas);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '${estado.cartasGanhas} / ${SoUmaConstants.totalCartasPartida}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              faixa,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RodadaARodada extends StatelessWidget {
  final SoUmaEstadoRemoto estado;
  final List<SoUmaJogadorRemoto> jogadores;

  const _RodadaARodada({required this.estado, required this.jogadores});

  @override
  Widget build(BuildContext context) {
    final nomes = {
      for (final jogador in jogadores) jogador.uid: jogador.displayName,
    };
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rodada a rodada',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final rodada in estado.historico)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  switch (rodada.resultado) {
                    'acerto' => Icons.check_circle,
                    'erro' => Icons.cancel,
                    _ => Icons.skip_next,
                  },
                  color: switch (rodada.resultado) {
                    'acerto' => Colors.green,
                    'erro' => Colors.red,
                    _ => Colors.orange,
                  },
                ),
                title: Text(
                  '${nomes[rodada.guesserUid] ?? 'Jogador'} — "${rodada.palavraAlvo}"',
                ),
                subtitle: Text(
                  rodada.palpite != null
                      ? 'Respondeu "${rodada.palpite}"'
                      : 'Passou',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VoltarLobbyCard extends StatelessWidget {
  final SoUmaSalaProvider provider;

  const _VoltarLobbyCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: provider.souHost
            ? PrimaryButton(
                text: 'Voltar ao Lobby',
                icon: Icons.groups,
                isLoading: provider.isLoading,
                onPressed: () => _voltar(context, provider),
              )
            : Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Aguardando o host voltar ao lobby.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _voltar(BuildContext context, SoUmaSalaProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.voltarAoLobbyRemoto();
    if (!context.mounted) return;
    if (!ok && provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }
}
