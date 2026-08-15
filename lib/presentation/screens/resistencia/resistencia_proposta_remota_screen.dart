import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/resistencia_estado_remoto.dart';
import '../../../data/models/resistencia_jogador_remoto.dart';
import '../../providers/resistencia_sala_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/resistencia_abort_action.dart';
import 'resistencia_fim_remoto_screen.dart';
import 'resistencia_missao_remota_screen.dart';
import 'resistencia_votacao_remota_screen.dart';

class ResistenciaPropostaRemotaScreen extends StatefulWidget {
  const ResistenciaPropostaRemotaScreen({super.key});

  @override
  State<ResistenciaPropostaRemotaScreen> createState() =>
      _ResistenciaPropostaRemotaScreenState();
}

class _ResistenciaPropostaRemotaScreenState
    extends State<ResistenciaPropostaRemotaScreen> {
  final Set<String> _selecionados = {};
  bool _navegouVotacao = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Propor Equipe'),
          automaticallyImplyLeading: false,
          actions: const [ResistenciaAbortAction()],
        ),
        body: SafeArea(
          child: Consumer<ResistenciaSalaProvider>(
            builder: (context, provider, _) {
              return StreamBuilder<ResistenciaEstadoRemoto?>(
                stream: provider.observarEstadoAtual(),
                initialData: provider.estado,
                builder: (context, estadoSnapshot) {
                  final estado = estadoSnapshot.data;
                  if (estado == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  _navegarSeNecessario(context, estado);

                  return StreamBuilder<List<ResistenciaJogadorRemoto>>(
                    stream: provider.observarJogadoresAtuais(),
                    initialData: provider.jogadores,
                    builder: (context, jogadoresSnapshot) {
                      final jogadores =
                          jogadoresSnapshot.data ?? provider.jogadores;
                      final lider = _buscarJogador(estado.leaderUid, jogadores);
                      final souLider = provider.uid == estado.leaderUid;

                      if (estado.phase != 'proposing') {
                        return _AguardandoProximaFase(estado: estado);
                      }

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _PlacarRemoto(estado: estado),
                          const SizedBox(height: 16),
                          _ResumoProposta(
                            estado: estado,
                            liderNome: lider?.displayName ?? 'Líder',
                            souLider: souLider,
                          ),
                          const SizedBox(height: 16),
                          if (souLider)
                            _SelecaoEquipeRemota(
                              jogadores: jogadores,
                              selecionados: _selecionados,
                              limite: estado.teamSize,
                              onToggle: _alternarJogador,
                            )
                          else
                            _AguardandoLider(
                              liderNome: lider?.displayName ?? 'líder',
                            ),
                          const SizedBox(height: 24),
                          if (souLider)
                            PrimaryButton(
                              text: 'Confirmar Equipe',
                              icon: Icons.how_to_vote,
                              isLoading: provider.isLoading,
                              onPressed: _selecionados.length == estado.teamSize
                                  ? () => _confirmar(context, provider)
                                  : null,
                            ),
                          const SizedBox(height: 24),
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
    );
  }

  void _alternarJogador(String uid, int limite) {
    setState(() {
      if (_selecionados.contains(uid)) {
        _selecionados.remove(uid);
      } else if (_selecionados.length < limite) {
        _selecionados.add(uid);
      }
    });
  }

  Future<void> _confirmar(
    BuildContext context,
    ResistenciaSalaProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.proporEquipeRemota(_selecionados.toList());
    if (!context.mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ResistenciaVotacaoRemotaScreen(),
        ),
      );
    } else if (provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }

  void _navegarSeNecessario(
    BuildContext context,
    ResistenciaEstadoRemoto estado,
  ) {
    if (_navegouVotacao || estado.currentProposalId == null) {
      return;
    }
    if (estado.phase != 'voting' &&
        estado.phase != 'mission' &&
        estado.phase != 'over') {
      return;
    }

    _navegouVotacao = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => estado.phase == 'mission'
              ? const ResistenciaMissaoRemotaScreen()
              : estado.phase == 'over'
              ? const ResistenciaFimRemotoScreen()
              : const ResistenciaVotacaoRemotaScreen(),
        ),
      );
    });
  }

  ResistenciaJogadorRemoto? _buscarJogador(
    String uid,
    List<ResistenciaJogadorRemoto> jogadores,
  ) {
    for (final jogador in jogadores) {
      if (jogador.uid == uid) return jogador;
    }
    return null;
  }
}

class _PlacarRemoto extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;

  const _PlacarRemoto({required this.estado});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Placar', style: Theme.of(context).textTheme.titleLarge),
                Text('${estado.successes} x ${estado.failures}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 4 ? 0 : 8),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _cor(context, i).withValues(alpha: 0.14),
                          border: Border.all(color: _cor(context, i)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: _cor(context, i),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _cor(BuildContext context, int index) {
    if (index < estado.missionResults.length) {
      return estado.missionResults[index] ? Colors.blue : Colors.red;
    }
    if (index + 1 == estado.round) return Theme.of(context).colorScheme.primary;
    return Colors.grey;
  }
}

class _ResumoProposta extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;
  final String liderNome;
  final bool souLider;

  const _ResumoProposta({
    required this.estado,
    required this.liderNome,
    required this.souLider,
  });

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
              'Missão ${estado.round}',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              souLider ? 'Você e o líder' : 'Líder: $liderNome',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.group, size: 18),
                  label: Text('${estado.teamSize} na equipe'),
                ),
                Chip(
                  avatar: const Icon(Icons.refresh, size: 18),
                  label: Text('Tentativa ${estado.attempt}/5'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelecaoEquipeRemota extends StatelessWidget {
  final List<ResistenciaJogadorRemoto> jogadores;
  final Set<String> selecionados;
  final int limite;
  final void Function(String uid, int limite) onToggle;

  const _SelecaoEquipeRemota({
    required this.jogadores,
    required this.selecionados,
    required this.limite,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Equipe proposta',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('${selecionados.length}/$limite'),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final jogador in jogadores)
                  ChoiceChip(
                    label: Text(jogador.displayName),
                    selected: selecionados.contains(jogador.uid),
                    onSelected:
                        selecionados.contains(jogador.uid) ||
                            selecionados.length < limite
                        ? (_) => onToggle(jogador.uid, limite)
                        : null,
                    avatar: selecionados.contains(jogador.uid)
                        ? const Icon(Icons.check, size: 18)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AguardandoLider extends StatelessWidget {
  final String liderNome;

  const _AguardandoLider({required this.liderNome});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Aguardando $liderNome propor a equipe.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AguardandoProximaFase extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;

  const _AguardandoProximaFase({required this.estado});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Fase atual: ${estado.phase}.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
