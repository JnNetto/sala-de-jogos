import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/resistencia_estado_remoto.dart';
import '../../../data/models/resistencia_jogador_remoto.dart';
import '../../../data/models/resistencia_privado.dart';
import '../../../data/models/resistencia_proposta_remota.dart';
import '../../providers/resistencia_sala_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/resistencia_abort_action.dart';
import 'resistencia_sala_router_screen.dart';

class ResistenciaMissaoRemotaScreen extends StatefulWidget {
  const ResistenciaMissaoRemotaScreen({super.key});

  @override
  State<ResistenciaMissaoRemotaScreen> createState() =>
      _ResistenciaMissaoRemotaScreenState();
}

class _ResistenciaMissaoRemotaScreenState
    extends State<ResistenciaMissaoRemotaScreen> {
  String? _proposalId;
  bool _cartaEnviada = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Missão'),
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

                  final currentProposalId = estado.currentProposalId;
                  if (currentProposalId != null &&
                      currentProposalId != _proposalId) {
                    _proposalId = currentProposalId;
                    _cartaEnviada = false;
                  }

                  if (estado.phase != 'mission' &&
                      estado.missionResults.isNotEmpty) {
                    return _ResultadoMissao(
                      estado: estado,
                      onContinuar: () => _continuar(context, provider, estado),
                    );
                  }

                  final proposalId = _proposalId;
                  if (proposalId == null) {
                    return _SemMissao(estado: estado);
                  }

                  return StreamBuilder<List<ResistenciaJogadorRemoto>>(
                    stream: provider.observarJogadoresAtuais(),
                    initialData: provider.jogadores,
                    builder: (context, jogadoresSnapshot) {
                      final jogadores =
                          jogadoresSnapshot.data ?? provider.jogadores;
                      return StreamBuilder<ResistenciaPrivado?>(
                        stream: provider.observarMeuPrivadoAtual(),
                        initialData: provider.privado,
                        builder: (context, privadoSnapshot) {
                          final privado = privadoSnapshot.data;
                          return StreamBuilder<ResistenciaPropostaRemota?>(
                            stream: provider.observarPropostaPorId(proposalId),
                            initialData: provider.proposta,
                            builder: (context, propostaSnapshot) {
                              final proposta = propostaSnapshot.data;
                              if (estado.phase != 'mission') {
                                return _ResultadoMissao(
                                  estado: estado,
                                  onContinuar: () =>
                                      _continuar(context, provider, estado),
                                );
                              }

                              if (proposta == null || privado == null) {
                                return _AguardandoMissao(estado: estado);
                              }

                              final estouNaEquipe = proposta.memberUids
                                  .contains(provider.uid);
                              return ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  _CabecalhoMissao(
                                    estado: estado,
                                    proposta: proposta,
                                  ),
                                  const SizedBox(height: 16),
                                  _EquipeDaMissao(
                                    proposta: proposta,
                                    jogadores: jogadores,
                                  ),
                                  const SizedBox(height: 16),
                                  if (estouNaEquipe)
                                    _ControleMissao(
                                      privado: privado,
                                      estado: estado,
                                      cartaEnviada: _cartaEnviada,
                                      isLoading: provider.isLoading,
                                      onJogar: (success) => _jogarCarta(
                                        context,
                                        provider,
                                        success,
                                      ),
                                    )
                                  else
                                    _AguardandoEquipe(estado: estado),
                                  if (provider.erro != null) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      provider.erro!,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
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

  Future<void> _jogarCarta(
    BuildContext context,
    ResistenciaSalaProvider provider,
    bool success,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.jogarCartaMissaoRemota(success);
    if (!context.mounted) return;

    if (ok) {
      setState(() => _cartaEnviada = true);
    } else if (provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _continuar(
    BuildContext context,
    ResistenciaSalaProvider provider,
    ResistenciaEstadoRemoto estado,
  ) async {
    await provider.marcarResultadoMissaoVisto(
      estado.gameId,
      estado.missionResults.length,
    );
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ResistenciaSalaRouterScreen()),
    );
  }
}

class _CabecalhoMissao extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;
  final ResistenciaPropostaRemota proposta;

  const _CabecalhoMissao({required this.estado, required this.proposta});

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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.group, size: 18),
                  label: Text('${proposta.memberUids.length} na equipe'),
                ),
                Chip(
                  avatar: const Icon(Icons.style, size: 18),
                  label: Text(
                    '${estado.submittedCount}/${estado.expectedCount} cartas',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipeDaMissao extends StatelessWidget {
  final ResistenciaPropostaRemota proposta;
  final List<ResistenciaJogadorRemoto> jogadores;

  const _EquipeDaMissao({required this.proposta, required this.jogadores});

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
              'Equipe em missão',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final uid in proposta.memberUids)
                  Chip(
                    avatar: const Icon(Icons.person, size: 18),
                    label: Text(nomes[uid] ?? 'Jogador'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControleMissao extends StatelessWidget {
  final ResistenciaPrivado privado;
  final ResistenciaEstadoRemoto estado;
  final bool cartaEnviada;
  final bool isLoading;
  final ValueChanged<bool> onJogar;

  const _ControleMissao({
    required this.privado,
    required this.estado,
    required this.cartaEnviada,
    required this.isLoading,
    required this.onJogar,
  });

  @override
  Widget build(BuildContext context) {
    final aguardando =
        cartaEnviada || estado.submittedCount >= estado.expectedCount;
    final podeSabotar = privado.team == 'evil';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              aguardando
                  ? 'Aguardando as outras cartas.'
                  : 'Escolha sua carta.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (podeSabotar)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: aguardando || isLoading
                          ? null
                          : () => onJogar(false),
                      icon: const Icon(Icons.close),
                      label: const Text('Fracasso'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Sucesso',
                      icon: Icons.check,
                      isLoading: isLoading,
                      onPressed: aguardando ? null : () => onJogar(true),
                    ),
                  ),
                ],
              )
            else
              PrimaryButton(
                text: 'Enviar Sucesso',
                icon: Icons.check,
                isLoading: isLoading,
                onPressed: aguardando ? null : () => onJogar(true),
              ),
          ],
        ),
      ),
    );
  }
}

class _AguardandoEquipe extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;

  const _AguardandoEquipe({required this.estado});

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
                'Aguardando a equipe enviar as cartas. ${estado.submittedCount}/${estado.expectedCount}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultadoMissao extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;
  final VoidCallback onContinuar;

  const _ResultadoMissao({required this.estado, required this.onContinuar});

  @override
  Widget build(BuildContext context) {
    final index = estado.missionResults.length - 1;
    final temResultado = index >= 0;
    final sucesso = temResultado && estado.missionResults[index];
    final falhas = temResultado && estado.failCounts.length > index
        ? estado.failCounts[index]
        : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  sucesso ? Icons.verified : Icons.cancel,
                  color: sucesso ? Colors.blue : Colors.red,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  sucesso ? 'Missão bem-sucedida' : 'Missão sabotada',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '$falhas carta${falhas == 1 ? '' : 's'} de fracasso.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '${estado.successes} sucessos, ${estado.failures} sabotagens.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: estado.phase == 'over' ? 'Ver Fim' : 'Nova Proposta',
                  icon: Icons.arrow_forward,
                  onPressed: onContinuar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SemMissao extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;

  const _SemMissao({required this.estado});

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

class _AguardandoMissao extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;

  const _AguardandoMissao({required this.estado});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Carregando missão ${estado.round}...',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
