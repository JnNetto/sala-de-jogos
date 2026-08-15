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
  final bool revelarPapelAoEntrar;

  const ResistenciaSalaRouterScreen({
    super.key,
    this.restaurarUltimaSala = false,
    this.revelarPapelAoEntrar = false,
  });

  @override
  State<ResistenciaSalaRouterScreen> createState() =>
      _ResistenciaSalaRouterScreenState();
}

class _ResistenciaSalaRouterScreenState
    extends State<ResistenciaSalaRouterScreen> {
  late final Future<bool> _restauracaoFuture;
  final Map<String, bool> _papelReveladoCache = {};
  final Map<String, bool> _resultadoPropostaCache = {};
  final Map<String, bool> _resultadoMissaoCache = {};

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

                final gameId = estado.gameId;
                if (estado.phase != 'over') {
                  final cached = _papelReveladoCache[gameId];
                  if (cached != null) {
                    if (!cached) {
                      return ResistenciaRevelacaoRemotaScreen(gameId: gameId);
                    }

                    return _telaComResultadosPendentes(provider, estado);
                  }

                  _carregarPapelRevelado(provider, gameId);
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

  Future<void> _carregarPapelRevelado(
    ResistenciaSalaProvider provider,
    String gameId,
  ) async {
    if (_papelReveladoCache.containsKey(gameId)) return;
    final revelado = await provider.papelReveladoNestaPartida(gameId);
    if (!mounted) return;
    setState(() => _papelReveladoCache[gameId] = revelado);
  }

  Future<void> _carregarResultadoProposta(
    ResistenciaSalaProvider provider,
    String gameId,
    String proposalId,
  ) async {
    final key = '$gameId:$proposalId';
    if (_resultadoPropostaCache.containsKey(key)) return;
    final visto = await provider.resultadoPropostaVisto(gameId, proposalId);
    if (!mounted) return;
    setState(() => _resultadoPropostaCache[key] = visto);
  }

  Future<void> _carregarResultadoMissao(
    ResistenciaSalaProvider provider,
    String gameId,
    int missionCount,
  ) async {
    final key = '$gameId:$missionCount';
    if (_resultadoMissaoCache.containsKey(key)) return;
    final visto = await provider.resultadoMissaoVisto(gameId, missionCount);
    if (!mounted) return;
    setState(() => _resultadoMissaoCache[key] = visto);
  }

  Widget _telaComResultadosPendentes(
    ResistenciaSalaProvider provider,
    ResistenciaEstadoRemoto estado,
  ) {
    final gameId = estado.gameId;
    final lastProposalId = estado.lastProposalId;
    if (lastProposalId != null) {
      final proposalKey = '$gameId:$lastProposalId';
      final proposalSeen = _resultadoPropostaCache[proposalKey];
      if (proposalSeen == null) {
        _carregarResultadoProposta(provider, gameId, lastProposalId);
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!proposalSeen) {
        return const ResistenciaVotacaoRemotaScreen();
      }
    }

    final missionCount = estado.missionResults.length;
    if (missionCount > 0) {
      final missionKey = '$gameId:$missionCount';
      final missionSeen = _resultadoMissaoCache[missionKey];
      if (missionSeen == null) {
        _carregarResultadoMissao(provider, gameId, missionCount);
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!missionSeen) {
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
        return const ResistenciaRevelacaoRemotaScreen();
    }
  }
}
