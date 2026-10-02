import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/resistencia_estado_remoto.dart';
import '../../../data/models/resistencia_sala.dart';
import '../../providers/resistencia_sala_provider.dart';
import 'resistencia_fim_remoto_screen.dart';
import 'resistencia_lobby_remoto_screen.dart';
import 'resistencia_missao_remota_screen.dart';
import 'resistencia_proposta_remota_screen.dart';
import 'resistencia_revelacao_remota_screen.dart';
import 'resistencia_votacao_remota_screen.dart';

class ResistenciaSalaRouterScreen extends StatefulWidget {
  final bool restaurarUltimaSala;

  const ResistenciaSalaRouterScreen({
    super.key,
    this.restaurarUltimaSala = false,
  });

  @override
  State<ResistenciaSalaRouterScreen> createState() =>
      _ResistenciaSalaRouterScreenState();
}

class _ResistenciaSalaRouterScreenState
    extends State<ResistenciaSalaRouterScreen> {
  late final Future<bool> _restauracaoFuture;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ResistenciaSalaProvider>();
    _restauracaoFuture = widget.restaurarUltimaSala
        ? provider.restaurarUltimaSala()
        : Future.value(provider.sala != null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restauracaoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final provider = context.watch<ResistenciaSalaProvider>();
        if (provider.sala == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sala Online')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhuma sala online encontrada.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return StreamBuilder<ResistenciaSala?>(
          stream: provider.observarSalaAtual(),
          initialData: provider.sala,
          builder: (context, salaSnapshot) {
            final sala = salaSnapshot.data ?? provider.sala;
            if (sala == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (sala.status == 'lobby') {
              return const ResistenciaLobbyRemotoScreen();
            }

            return StreamBuilder<ResistenciaEstadoRemoto?>(
              stream: provider.observarEstadoAtual(),
              initialData: provider.estado,
              builder: (context, estadoSnapshot) {
                final estado = estadoSnapshot.data ?? provider.estado;
                if (estado == null) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                return _telaComResultadosPendentes(provider, estado);
              },
            );
          },
        );
      },
    );
  }

  Widget _telaComResultadosPendentes(
    ResistenciaSalaProvider provider,
    ResistenciaEstadoRemoto estado,
  ) {
    final gameId = estado.gameId;

    if (estado.phase != 'over') {
      final papelVisto = provider.papelReveladoSync(gameId);
      if (papelVisto == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.garantirPapelReveladoCarregado(gameId);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!papelVisto) {
        return ResistenciaRevelacaoRemotaScreen(gameId: gameId);
      }
    }

    final lastProposalId = estado.lastProposalId;
    if (lastProposalId != null) {
      final propostaVista = provider.resultadoPropostaVistoSync(
        gameId,
        lastProposalId,
      );
      if (propostaVista == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.garantirResultadoPropostaCarregado(gameId, lastProposalId);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!propostaVista) {
        return const ResistenciaVotacaoRemotaScreen();
      }
    }

    final missionCount = estado.missionResults.length;
    if (missionCount > 0) {
      final missaoVista = provider.resultadoMissaoVistoSync(
        gameId,
        missionCount,
      );
      if (missaoVista == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.garantirResultadoMissaoCarregado(gameId, missionCount);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!missaoVista) {
        return const ResistenciaMissaoRemotaScreen();
      }
    }

    return _telaDaFase(estado.phase);
  }

  Widget _telaDaFase(String phase) {
    switch (phase) {
      case 'proposing':
        return const ResistenciaPropostaRemotaScreen();
      case 'voting':
        return const ResistenciaVotacaoRemotaScreen();
      case 'mission':
        return const ResistenciaMissaoRemotaScreen();
      case 'over':
        return const ResistenciaFimRemotoScreen();
      default:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
