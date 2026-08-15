import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/resistencia_partida.dart';
import '../../providers/resistencia_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'resistencia_votacao_screen.dart';

class ResistenciaPropostaScreen extends StatelessWidget {
  const ResistenciaPropostaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Propor Equipe'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Encerrar partida',
            onPressed: () => _confirmarSaida(context),
          ),
        ),
        body: SafeArea(
          child: Consumer<ResistenciaPartidaProvider>(
            builder: (context, provider, _) {
              final partida = provider.partida;
              if (partida == null) {
                return const Center(child: Text('Partida não iniciada'));
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Placar(partida: partida),
                  const SizedBox(height: 16),
                  _ResumoRodada(partida: partida),
                  const SizedBox(height: 16),
                  _SelecaoEquipe(partida: partida),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Confirmar Equipe',
                    icon: Icons.how_to_vote,
                    onPressed: partida.equipeCompleta
                        ? () {
                            final messenger = ScaffoldMessenger.of(context);
                            final ok = provider.confirmarProposta();
                            if (ok) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ResistenciaVotacaoScreen(),
                                ),
                              );
                            } else if (provider.erro != null) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(provider.erro!),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarSaida(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Encerrar partida?'),
          content: const Text('Você voltará para a tela inicial do app.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Encerrar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<ResistenciaPartidaProvider>().limparPartida();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _Placar extends StatelessWidget {
  final ResistenciaPartida partida;

  const _Placar({required this.partida});

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
                Text(
                  '${partida.sucessos} x ${partida.fracassos}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < partida.tamanhosEquipe.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == partida.tamanhosEquipe.length - 1 ? 0 : 8,
                      ),
                      child: _MissaoMarcador(
                        numero: i + 1,
                        concluida: i < partida.resultadosMissoes.length,
                        sucesso: i < partida.resultadosMissoes.length
                            ? partida.resultadosMissoes[i]
                            : null,
                        atual: i + 1 == partida.missaoAtual,
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
}

class _MissaoMarcador extends StatelessWidget {
  final int numero;
  final bool concluida;
  final bool? sucesso;
  final bool atual;

  const _MissaoMarcador({
    required this.numero,
    required this.concluida,
    required this.sucesso,
    required this.atual,
  });

  @override
  Widget build(BuildContext context) {
    final color = concluida
        ? (sucesso == true ? Colors.blue : Colors.red)
        : atual
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: concluida || atual ? 0.16 : 0.08),
        border: Border.all(color: color, width: atual ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        '$numero',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _ResumoRodada extends StatelessWidget {
  final ResistenciaPartida partida;

  const _ResumoRodada({required this.partida});

  @override
  Widget build(BuildContext context) {
    final falhasNecessarias =
        partida.missaoAtual == 4 && partida.quantidadeJogadores >= 7 ? 2 : 1;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Missão ${partida.missaoAtual}',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Líder: ${partida.liderAtual.nome}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.group, size: 18),
                  label: Text('${partida.tamanhoEquipeAtual} na equipe'),
                ),
                Chip(
                  avatar: const Icon(Icons.refresh, size: 18),
                  label: Text('Tentativa ${partida.tentativaAtual}/5'),
                ),
                Chip(
                  avatar: const Icon(Icons.warning_amber, size: 18),
                  label: Text('$falhasNecessarias falha(s) para sabotar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelecaoEquipe extends StatelessWidget {
  final ResistenciaPartida partida;

  const _SelecaoEquipe({required this.partida});

  @override
  Widget build(BuildContext context) {
    final selecionados = partida.equipePropostaIds.length;
    final limite = partida.tamanhoEquipeAtual;

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
                Text(
                  '$selecionados/$limite',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selecionados == limite
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Toque nos jogadores escolhidos pelo líder.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final jogador in partida.jogadores)
                  _JogadorChoiceChip(jogadorId: jogador.id),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JogadorChoiceChip extends StatelessWidget {
  final String jogadorId;

  const _JogadorChoiceChip({required this.jogadorId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResistenciaPartidaProvider>();
    final partida = provider.partida!;
    final jogador = partida.jogadores.firstWhere((j) => j.id == jogadorId);
    final selecionado = partida.jogadorEstaNaProposta(jogadorId);
    final limiteAtingido =
        !selecionado &&
        partida.equipePropostaIds.length >= partida.tamanhoEquipeAtual;

    return ChoiceChip(
      label: Text(jogador.nome),
      selected: selecionado,
      onSelected: limiteAtingido
          ? null
          : (_) => provider.alternarJogadorNaProposta(jogadorId),
      avatar: selecionado ? const Icon(Icons.check, size: 18) : null,
    );
  }
}
