import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/resistencia_estado_remoto.dart';
import '../../../data/models/resistencia_jogador_remoto.dart';
import '../../../data/models/resistencia_proposta_remota.dart';
import '../../providers/resistencia_sala_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/resistencia_abort_action.dart';
import 'resistencia_sala_router_screen.dart';

class ResistenciaVotacaoRemotaScreen extends StatefulWidget {
  const ResistenciaVotacaoRemotaScreen({super.key});

  @override
  State<ResistenciaVotacaoRemotaScreen> createState() =>
      _ResistenciaVotacaoRemotaScreenState();
}

class _ResistenciaVotacaoRemotaScreenState
    extends State<ResistenciaVotacaoRemotaScreen> {
  String? _proposalId;
  bool _votoEnviado = false;
  bool? _votoSelecionado;
  bool? _votoConfirmado;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Votação da Equipe'),
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

                  final currentProposalId =
                      estado.currentProposalId ?? estado.lastProposalId;
                  if (currentProposalId != null &&
                      currentProposalId != _proposalId) {
                    _proposalId = currentProposalId;
                    if (estado.currentProposalId == currentProposalId) {
                      _votoEnviado = false;
                      _votoSelecionado = null;
                      _votoConfirmado = null;
                    }
                  }

                  final proposalId = _proposalId;
                  if (proposalId == null) {
                    return _FaseSemProposta(estado: estado);
                  }

                  return StreamBuilder<List<ResistenciaJogadorRemoto>>(
                    stream: provider.observarJogadoresAtuais(),
                    initialData: provider.jogadores,
                    builder: (context, jogadoresSnapshot) {
                      final jogadores =
                          jogadoresSnapshot.data ?? provider.jogadores;
                      return StreamBuilder<ResistenciaPropostaRemota?>(
                        stream: provider.observarPropostaPorId(proposalId),
                        initialData: provider.proposta,
                        builder: (context, propostaSnapshot) {
                          final proposta = propostaSnapshot.data;
                          if (proposta == null) {
                            return _AguardandoProposta(estado: estado);
                          }

                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _CabecalhoVotacao(
                                estado: estado,
                                proposta: proposta,
                              ),
                              const SizedBox(height: 16),
                              _EquipeIndicada(
                                proposta: proposta,
                                jogadores: jogadores,
                              ),
                              const SizedBox(height: 16),
                              if (proposta.estaEmVotacao)
                                _ControleVoto(
                                  estado: estado,
                                  votoEnviado: _votoEnviado,
                                  votoSelecionado: _votoSelecionado,
                                  votoConfirmado: _votoConfirmado,
                                  isLoading: provider.isLoading,
                                  onSelecionar: (approve) {
                                    setState(() => _votoSelecionado = approve);
                                  },
                                  onConfirmar: () {
                                    final voto = _votoSelecionado;
                                    if (voto != null) {
                                      _votar(context, provider, voto);
                                    }
                                  },
                                )
                              else
                                _ResultadoVotacao(
                                  estado: estado,
                                  proposta: proposta,
                                  jogadores: jogadores,
                                  onContinuar: () => _continuar(
                                    context,
                                    provider,
                                    estado,
                                    proposta,
                                  ),
                                ),
                              if (provider.erro != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  provider.erro!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
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
          ),
        ),
      ),
    );
  }

  Future<void> _votar(
    BuildContext context,
    ResistenciaSalaProvider provider,
    bool approve,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.votarPropostaRemota(approve);
    if (!context.mounted) return;

    if (ok) {
      setState(() {
        _votoEnviado = true;
        _votoConfirmado = approve;
      });
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
    ResistenciaPropostaRemota proposta,
  ) async {
    await provider.marcarResultadoPropostaVisto(estado.gameId, proposta.id);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ResistenciaSalaRouterScreen()),
    );
  }
}

class _CabecalhoVotacao extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;
  final ResistenciaPropostaRemota proposta;

  const _CabecalhoVotacao({required this.estado, required this.proposta});

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
              'Missão ${proposta.round}',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.refresh, size: 18),
                  label: Text('Tentativa ${proposta.attempt}/5'),
                ),
                Chip(
                  avatar: const Icon(Icons.how_to_vote, size: 18),
                  label: Text(
                    '${estado.submittedCount}/${estado.expectedCount} votos',
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

class _EquipeIndicada extends StatelessWidget {
  final ResistenciaPropostaRemota proposta;
  final List<ResistenciaJogadorRemoto> jogadores;

  const _EquipeIndicada({required this.proposta, required this.jogadores});

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
              'Equipe indicada',
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

class _ControleVoto extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;
  final bool votoEnviado;
  final bool? votoSelecionado;
  final bool? votoConfirmado;
  final bool isLoading;
  final ValueChanged<bool> onSelecionar;
  final VoidCallback onConfirmar;

  const _ControleVoto({
    required this.estado,
    required this.votoEnviado,
    required this.votoSelecionado,
    required this.votoConfirmado,
    required this.isLoading,
    required this.onSelecionar,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final aguardando =
        votoEnviado || estado.submittedCount >= estado.expectedCount;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              aguardando
                  ? 'Seu voto foi registrado.'
                  : 'Você aprova esta equipe?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (aguardando)
              _VotoRegistrado(voto: votoConfirmado ?? votoSelecionado)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      avatar: const Icon(Icons.close, size: 18),
                      label: const Text('Reprovar'),
                      selected: votoSelecionado == false,
                      onSelected: isLoading ? null : (_) => onSelecionar(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      avatar: const Icon(Icons.check, size: 18),
                      label: const Text('Aprovar'),
                      selected: votoSelecionado == true,
                      onSelected: isLoading ? null : (_) => onSelecionar(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: votoSelecionado == null
                    ? 'Selecione seu voto'
                    : votoSelecionado!
                    ? 'Confirmar Aprovar'
                    : 'Confirmar Reprovar',
                icon: Icons.how_to_vote,
                isLoading: isLoading,
                onPressed: votoSelecionado == null ? null : onConfirmar,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VotoRegistrado extends StatelessWidget {
  final bool? voto;

  const _VotoRegistrado({required this.voto});

  @override
  Widget build(BuildContext context) {
    final aprovou = voto == true;
    return Chip(
      avatar: Icon(aprovou ? Icons.check : Icons.close, size: 18),
      label: Text(aprovou ? 'Você aprovou' : 'Você reprovou'),
    );
  }
}

class _ResultadoVotacao extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;
  final ResistenciaPropostaRemota proposta;
  final List<ResistenciaJogadorRemoto> jogadores;
  final VoidCallback onContinuar;

  const _ResultadoVotacao({
    required this.estado,
    required this.proposta,
    required this.jogadores,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    final aprovada = proposta.aprovada;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              aprovada ? Icons.verified : Icons.cancel,
              color: aprovada ? Colors.blue : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              aprovada ? 'Equipe aprovada' : 'Equipe rejeitada',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${proposta.aprovacoes} aprovaram, ${proposta.rejeicoes} reprovaram.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _ListaVotos(proposta: proposta, jogadores: jogadores),
            const SizedBox(height: 16),
            PrimaryButton(
              text: estado.phase == 'proposing' ? 'Nova Proposta' : 'Continuar',
              icon: Icons.arrow_forward,
              onPressed: onContinuar,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaVotos extends StatelessWidget {
  final ResistenciaPropostaRemota proposta;
  final List<ResistenciaJogadorRemoto> jogadores;

  const _ListaVotos({required this.proposta, required this.jogadores});

  @override
  Widget build(BuildContext context) {
    final votos = proposta.votes ?? const <String, bool>{};
    final nomes = {
      for (final jogador in jogadores) jogador.uid: jogador.displayName,
    };
    final aprovaram =
        votos.entries
            .where((entry) => entry.value)
            .map((entry) => nomes[entry.key] ?? 'Jogador')
            .toList()
          ..sort();
    final reprovaram =
        votos.entries
            .where((entry) => !entry.value)
            .map((entry) => nomes[entry.key] ?? 'Jogador')
            .toList()
          ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GrupoVotos(
          titulo: 'Aprovaram',
          nomes: aprovaram,
          icon: Icons.check,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _GrupoVotos(
          titulo: 'Reprovaram',
          nomes: reprovaram,
          icon: Icons.close,
          color: Colors.red,
        ),
      ],
    );
  }
}

class _GrupoVotos extends StatelessWidget {
  final String titulo;
  final List<String> nomes;
  final IconData icon;
  final Color color;

  const _GrupoVotos({
    required this.titulo,
    required this.nomes,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (nomes.isEmpty) const Chip(label: Text('Ninguém')),
            for (final nome in nomes)
              Chip(
                avatar: Icon(icon, size: 16, color: color),
                label: Text(nome),
              ),
          ],
        ),
      ],
    );
  }
}

class _FaseSemProposta extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;

  const _FaseSemProposta({required this.estado});

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

class _AguardandoProposta extends StatelessWidget {
  final ResistenciaEstadoRemoto estado;

  const _AguardandoProposta({required this.estado});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Carregando proposta da missão ${estado.round}...',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
