import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/resistencia_estado_remoto.dart';
import '../../../data/models/resistencia_jogador_remoto.dart';
import '../../../data/models/resistencia_sala.dart';
import '../../providers/resistencia_sala_provider.dart';
import '../../widgets/primary_button.dart';
import 'resistencia_lobby_remoto_screen.dart';

class ResistenciaFimRemotoScreen extends StatelessWidget {
  const ResistenciaFimRemotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fim da Partida'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Consumer<ResistenciaSalaProvider>(
            builder: (context, provider, _) {
              return StreamBuilder<ResistenciaSala?>(
                stream: provider.observarSalaAtual(),
                initialData: provider.sala,
                builder: (context, salaSnapshot) {
                  final sala = salaSnapshot.data;
                  _navegarSeVoltouAoLobby(context, sala);

                  return StreamBuilder<ResistenciaEstadoRemoto?>(
                    stream: provider.observarEstadoAtual(),
                    initialData: provider.estado,
                    builder: (context, estadoSnapshot) {
                      final estado = estadoSnapshot.data;
                      if (estado == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return StreamBuilder<List<ResistenciaJogadorRemoto>>(
                        stream: provider.observarJogadoresAtuais(),
                        initialData: provider.jogadores,
                        builder: (context, jogadoresSnapshot) {
                          final jogadores =
                              jogadoresSnapshot.data ?? provider.jogadores;
                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _ResumoFinal(estado: estado),
                              const SizedBox(height: 16),
                              _PlacarFinal(estado: estado),
                              const SizedBox(height: 16),
                              _RevelacaoPapeis(jogadores: jogadores),
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

  void _navegarSeVoltouAoLobby(BuildContext context, ResistenciaSala? sala) {
    if (sala?.status != 'lobby') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResistenciaLobbyRemotoScreen()),
      );
    });
  }
}

class _ResumoFinal extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;

  const _ResumoFinal({required this.estado});

  @override
  Widget build(BuildContext context) {
    final resistenciaVenceu = estado.winner == 'resistance';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              resistenciaVenceu ? Icons.shield : Icons.visibility,
              color: resistenciaVenceu ? Colors.blue : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              resistenciaVenceu ? 'Resistência venceu' : 'Espiões venceram',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${estado.successes} missões bem-sucedidas, ${estado.failures} sabotadas.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacarFinal extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;

  const _PlacarFinal({required this.estado});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Placar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (var i = 0; i < estado.missionResults.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  estado.missionResults[i] ? Icons.check_circle : Icons.cancel,
                  color: estado.missionResults[i] ? Colors.blue : Colors.red,
                ),
                title: Text('Missão ${i + 1}'),
                subtitle: Text(
                  '${estado.failCounts.length > i ? estado.failCounts[i] : 0} carta${estado.failCounts.length > i && estado.failCounts[i] == 1 ? '' : 's'} de fracasso',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RevelacaoPapeis extends StatelessWidget {
  final List<ResistenciaJogadorRemoto> jogadores;

  const _RevelacaoPapeis({required this.jogadores});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Papéis revelados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final jogador in jogadores)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _cor(jogador).withValues(alpha: 0.14),
                  foregroundColor: _cor(jogador),
                  child: Icon(_icone(jogador), size: 20),
                ),
                title: Text(jogador.displayName),
                subtitle: Text(_papel(jogador)),
              ),
          ],
        ),
      ),
    );
  }

  Color _cor(ResistenciaJogadorRemoto jogador) {
    return jogador.revealedTeam == 'evil' ? Colors.red : Colors.blue;
  }

  IconData _icone(ResistenciaJogadorRemoto jogador) {
    return jogador.revealedTeam == 'evil' ? Icons.visibility : Icons.shield;
  }

  String _papel(ResistenciaJogadorRemoto jogador) {
    switch (jogador.revealedRole) {
      case 'spy':
        return 'Espião';
      case 'resistance':
        return 'Resistência';
      case null:
        return 'Papel ainda não revelado';
      default:
        return jogador.revealedRole!;
    }
  }
}

class _VoltarLobbyCard extends StatelessWidget {
  final ResistenciaSalaProvider provider;

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

  Future<void> _voltar(
    BuildContext context,
    ResistenciaSalaProvider provider,
  ) async {
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
