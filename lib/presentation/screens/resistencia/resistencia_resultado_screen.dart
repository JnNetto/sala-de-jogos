import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/resistencia_papel.dart';
import '../../../core/enums/resistencia_vencedor.dart';
import '../../../data/models/resistencia_jogador.dart';
import '../../../data/models/resistencia_partida.dart';
import '../../providers/resistencia_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'resistencia_configuracao_screen.dart';

class ResistenciaResultadoScreen extends StatelessWidget {
  const ResistenciaResultadoScreen({super.key});

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
          child: Consumer<ResistenciaPartidaProvider>(
            builder: (context, provider, _) {
              final partida = provider.partida;
              if (partida == null) {
                return const Center(child: Text('Partida não iniciada'));
              }

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _CabecalhoResultado(partida: partida),
                  const SizedBox(height: 24),
                  _ResumoMissoes(partida: partida),
                  const SizedBox(height: 16),
                  _PapeisRevelados(partida: partida),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Nova Partida',
                    icon: Icons.refresh,
                    onPressed: () {
                      provider.limparPartida();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResistenciaConfiguracaoScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      provider.limparPartida();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Voltar ao Início'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CabecalhoResultado extends StatelessWidget {
  final ResistenciaPartida partida;

  const _CabecalhoResultado({required this.partida});

  @override
  Widget build(BuildContext context) {
    final vencedor = partida.vencedor ?? ResistenciaVencedor.espioes;
    final resistenciaVenceu = vencedor == ResistenciaVencedor.resistencia;

    return Column(
      children: [
        Icon(
          resistenciaVenceu ? Icons.shield_outlined : Icons.visibility_off,
          size: 104,
          color: resistenciaVenceu ? Colors.blue : Colors.red,
        ),
        const SizedBox(height: 24),
        Text(
          '${vencedor.nome} venceram',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '${partida.sucessos} missões da Resistência · ${partida.fracassos} sabotagens',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ResumoMissoes extends StatelessWidget {
  final ResistenciaPartida partida;

  const _ResumoMissoes({required this.partida});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Missões', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (var i = 0; i < partida.resultadosMissoes.length; i++)
              _LinhaMissao(
                numero: i + 1,
                sucesso: partida.resultadosMissoes[i],
                fracassos: i < partida.fracassosPorMissao.length
                    ? partida.fracassosPorMissao[i]
                    : 0,
              ),
          ],
        ),
      ),
    );
  }
}

class _LinhaMissao extends StatelessWidget {
  final int numero;
  final bool sucesso;
  final int fracassos;

  const _LinhaMissao({
    required this.numero,
    required this.sucesso,
    required this.fracassos,
  });

  @override
  Widget build(BuildContext context) {
    final color = sucesso ? Colors.blue : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            foregroundColor: color,
            child: Text('$numero'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sucesso ? 'Sucesso da Resistência' : 'Missão sabotada',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            '$fracassos F',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PapeisRevelados extends StatelessWidget {
  final ResistenciaPartida partida;

  const _PapeisRevelados({required this.partida});

  @override
  Widget build(BuildContext context) {
    final jogadores = [...partida.jogadores]
      ..sort((a, b) => (a.assento ?? 0).compareTo(b.assento ?? 0));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Papéis', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final jogador in jogadores) _LinhaPapel(jogador: jogador),
          ],
        ),
      ),
    );
  }
}

class _LinhaPapel extends StatelessWidget {
  final ResistenciaJogador jogador;

  const _LinhaPapel({required this.jogador});

  @override
  Widget build(BuildContext context) {
    final espiao = jogador.papel == ResistenciaPapel.espiao;
    final color = espiao ? Colors.red : Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            espiao ? Icons.visibility_off : Icons.shield_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              jogador.nome,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            espiao ? 'Espião' : 'Resistência',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
