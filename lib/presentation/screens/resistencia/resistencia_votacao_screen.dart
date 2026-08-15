import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/resistencia_fase.dart';
import '../../../data/models/resistencia_jogador.dart';
import '../../../data/models/resistencia_partida.dart';
import '../../providers/resistencia_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'resistencia_missao_screen.dart';
import 'resistencia_proposta_screen.dart';
import 'resistencia_resultado_screen.dart';

class ResistenciaVotacaoScreen extends StatefulWidget {
  const ResistenciaVotacaoScreen({super.key});

  @override
  State<ResistenciaVotacaoScreen> createState() =>
      _ResistenciaVotacaoScreenState();
}

class _ResistenciaVotacaoScreenState extends State<ResistenciaVotacaoScreen> {
  int _jogadorAtualIndex = 0;
  bool _resultadoRevelado = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Votação da Equipe')),
        body: SafeArea(
          child: Consumer<ResistenciaPartidaProvider>(
            builder: (context, provider, _) {
              final partida = provider.partida;
              if (partida == null) {
                return const Center(child: Text('Partida não iniciada'));
              }

              if (_resultadoRevelado) {
                return _ResultadoVotacao(
                  partida: partida,
                  onContinuar: () => _continuarAposResultado(context, provider),
                );
              }

              final todosVotaram =
                  _jogadorAtualIndex >= partida.jogadores.length;
              if (todosVotaram) {
                return _AguardandoRevelacao(
                  partida: partida,
                  onRevelar: () {
                    provider.resolverVotacaoProposta();
                    setState(() => _resultadoRevelado = true);
                  },
                );
              }

              final jogador = partida.jogadores[_jogadorAtualIndex];
              return _ColetaVoto(
                partida: partida,
                jogador: jogador,
                indice: _jogadorAtualIndex,
                onVotar: (aprovar) {
                  provider.registrarVotoProposta(jogador.id, aprovar);
                  setState(() => _jogadorAtualIndex++);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _continuarAposResultado(
    BuildContext context,
    ResistenciaPartidaProvider provider,
  ) {
    final partida = provider.partida;
    if (partida == null) return;

    if (partida.fase == ResistenciaFase.propondo) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResistenciaPropostaScreen()),
      );
      return;
    }

    if (partida.fase == ResistenciaFase.missao) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResistenciaMissaoScreen()),
      );
      return;
    }

    if (partida.fase == ResistenciaFase.finalizada) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResistenciaResultadoScreen()),
      );
    }
  }
}

class _ColetaVoto extends StatelessWidget {
  final ResistenciaPartida partida;
  final ResistenciaJogador jogador;
  final int indice;
  final ValueChanged<bool> onVotar;

  const _ColetaVoto({
    required this.partida,
    required this.jogador,
    required this.indice,
    required this.onVotar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: indice / partida.jogadores.length,
            backgroundColor: Colors.grey[200],
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Text(
            'Voto ${indice + 1} de ${partida.jogadores.length}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Icon(
            Icons.how_to_vote,
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            jogador.nome,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Vote secretamente na equipe proposta.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _EquipeProposta(partida: partida),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onVotar(false),
                  icon: const Icon(Icons.close),
                  label: const Text('Rejeitar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: 'Aprovar',
                  icon: Icons.check,
                  backgroundColor: Colors.green,
                  onPressed: () => onVotar(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AguardandoRevelacao extends StatelessWidget {
  final ResistenciaPartida partida;
  final VoidCallback onRevelar;

  const _AguardandoRevelacao({required this.partida, required this.onRevelar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.lock, size: 96, color: Colors.orange),
          const SizedBox(height: 32),
          Text(
            'Todos votaram',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Revele a votação para saber se a equipe foi aprovada.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _EquipeProposta(partida: partida),
          const Spacer(),
          PrimaryButton(
            text: 'Revelar Votos',
            icon: Icons.visibility,
            onPressed: onRevelar,
          ),
        ],
      ),
    );
  }
}

class _ResultadoVotacao extends StatelessWidget {
  final ResistenciaPartida partida;
  final VoidCallback onContinuar;

  const _ResultadoVotacao({required this.partida, required this.onContinuar});

  @override
  Widget build(BuildContext context) {
    final aprovada = partida.ultimaPropostaAprovada == true;
    final finalizada = partida.fase == ResistenciaFase.finalizada;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          aprovada ? Icons.check_circle : Icons.cancel,
          size: 96,
          color: aprovada ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 24),
        Text(
          finalizada
              ? 'Espiões venceram'
              : aprovada
              ? 'Equipe aprovada'
              : 'Equipe rejeitada',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '${partida.votosAprovacao} aprovaram · ${partida.votosRejeicao} rejeitaram',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _EquipeProposta(partida: partida),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final jogador in partida.jogadores)
                  _LinhaVoto(
                    nome: jogador.nome,
                    aprovou: partida.votosProposta[jogador.id] == true,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: finalizada
              ? 'Fim da Partida'
              : aprovada
              ? 'Ir para Missão'
              : 'Nova Proposta',
          icon: Icons.arrow_forward,
          onPressed: onContinuar,
        ),
      ],
    );
  }
}

class _EquipeProposta extends StatelessWidget {
  final ResistenciaPartida partida;

  const _EquipeProposta({required this.partida});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipe', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final jogador in partida.equipeProposta)
                  Chip(
                    avatar: const Icon(Icons.person, size: 18),
                    label: Text(jogador.nome),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaVoto extends StatelessWidget {
  final String nome;
  final bool aprovou;

  const _LinhaVoto({required this.nome, required this.aprovou});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            aprovou ? Icons.thumb_up : Icons.thumb_down,
            color: aprovou ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(nome, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            aprovou ? 'Aprovou' : 'Rejeitou',
            style: TextStyle(
              color: aprovou ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
