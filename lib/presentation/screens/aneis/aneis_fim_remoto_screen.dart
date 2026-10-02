import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/aneis_constants.dart';
import '../../../data/models/aneis_estado_remoto.dart';
import '../../../data/models/aneis_sala.dart';
import '../../providers/aneis_sala_provider.dart';
import '../../widgets/aneis_regiao_sheet.dart';
import '../../widgets/aneis_venn_board.dart';
import '../../widgets/primary_button.dart';
import 'aneis_lobby_remoto_screen.dart';

class AneisFimRemotoScreen extends StatelessWidget {
  const AneisFimRemotoScreen({super.key});

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
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Consumer<AneisSalaProvider>(
            builder: (context, provider, _) {
              return StreamBuilder<AneisSala?>(
                stream: provider.observarSalaAtual(),
                initialData: provider.sala,
                builder: (context, salaSnapshot) {
                  final sala = salaSnapshot.data;
                  _navegarSeVoltouAoLobby(context, sala);

                  return StreamBuilder<AneisEstadoRemoto?>(
                    stream: provider.observarEstadoAtual(),
                    initialData: provider.estado,
                    builder: (context, estadoSnapshot) {
                      final estado = estadoSnapshot.data;
                      if (estado == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: _PlacarFinal(estado: estado),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _RegrasReveladas(estado: estado),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                              child: AneisVennBoard(
                                cartas: estado.tabuleiro,
                                onVerRegiao: (regiao) => mostrarCartasDaRegiao(
                                  context: context,
                                  regiao: regiao,
                                  cartas: estado.tabuleiro,
                                  aneis: estado.aneis,
                                  regraSecreta: estado.regrasReveladas
                                      .where((regra) => regra.anel == regiao.id)
                                      .firstOrNull,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: _VoltarLobbyCard(provider: provider),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          ),
        ),
      ),
    );
  }

  void _navegarSeVoltouAoLobby(BuildContext context, AneisSala? sala) {
    if (sala?.status != 'lobby') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AneisLobbyRemotoScreen()),
      );
    });
  }
}

class _PlacarFinal extends StatelessWidget {
  final AneisEstadoRemoto estado;

  const _PlacarFinal({required this.estado});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.emoji_events,
              size: 56,
              color: AneisConstants.corAtributo,
            ),
            const SizedBox(height: 8),
            Text(
              estado.vencedorNome ?? 'Alguém',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'esvaziou a mão e venceu',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegrasReveladas extends StatelessWidget {
  final AneisEstadoRemoto estado;

  const _RegrasReveladas({required this.estado});

  @override
  Widget build(BuildContext context) {
    if (estado.regrasReveladas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'As regras secretas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final regra in estado.regrasReveladas)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: regra.cor.withValues(alpha: 0.2),
                  child: Icon(Icons.circle, color: regra.cor, size: 18),
                ),
                title: Text(regra.nome),
                subtitle: Text(regra.texto),
              ),
          ],
        ),
      ),
    );
  }
}

class _VoltarLobbyCard extends StatelessWidget {
  final AneisSalaProvider provider;

  const _VoltarLobbyCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return provider.souHost
        ? PrimaryButton(
            text: 'Voltar ao Lobby',
            icon: Icons.groups,
            isLoading: provider.isLoading,
            onPressed: () => _voltar(context, provider),
          )
        : Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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

  Future<void> _voltar(BuildContext context, AneisSalaProvider provider) async {
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
