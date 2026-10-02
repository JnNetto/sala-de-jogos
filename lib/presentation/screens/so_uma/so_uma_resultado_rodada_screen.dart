import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/so_uma_fase.dart';
import '../../../core/enums/so_uma_resultado_rodada.dart';
import '../../../data/models/so_uma_rodada.dart';
import '../../providers/so_uma_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'so_uma_escolha_numero_screen.dart';
import 'so_uma_resultado_final_screen.dart';

class SoUmaResultadoRodadaScreen extends StatelessWidget {
  const SoUmaResultadoRodadaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SoUmaPartidaProvider>();
    final partida = provider.partida;
    if (partida == null || partida.historico.isEmpty) {
      return const Scaffold(body: Center(child: Text('Sem resultado ainda')));
    }

    final rodada = partida.historico.last;
    final resultado = rodada.resultado!;
    final cor = switch (resultado) {
      SoUmaResultadoRodada.acerto => Colors.green,
      SoUmaResultadoRodada.erro => Colors.red,
      SoUmaResultadoRodada.passou => Colors.orange,
    };
    final icone = switch (resultado) {
      SoUmaResultadoRodada.acerto => Icons.emoji_events,
      SoUmaResultadoRodada.erro => Icons.close,
      SoUmaResultadoRodada.passou => Icons.skip_next,
    };
    final titulo = switch (resultado) {
      SoUmaResultadoRodada.acerto => 'Acertou!',
      SoUmaResultadoRodada.erro => 'Errou',
      SoUmaResultadoRodada.passou => 'Passou',
    };

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resultado da Rodada'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(icone, size: 64, color: cor),
                      const SizedBox(height: 12),
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A palavra era "${rodada.palavraAlvo}".',
                        textAlign: TextAlign.center,
                      ),
                      if (rodada.palpite != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${rodada.adivinhador.nome} respondeu "${rodada.palpite}".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _CartaRevelada(rodada: rodada),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Placar',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${partida.cartasGanhas} carta${partida.cartasGanhas == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: partida.fase == SoUmaFase.finalizada
                    ? 'Ver Resultado Final'
                    : 'Próxima Carta',
                icon: Icons.arrow_forward,
                onPressed: () => _continuar(context, partida.fase),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _continuar(BuildContext context, SoUmaFase fase) {
    if (fase == SoUmaFase.finalizada) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SoUmaResultadoFinalScreen()),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SoUmaEscolhaNumeroScreen()),
    );
  }
}

class _CartaRevelada extends StatelessWidget {
  final SoUmaRodada rodada;

  const _CartaRevelada({required this.rodada});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A carta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (var i = 0; i < rodada.carta.palavras.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${i + 1}. ${rodada.carta.palavras[i]}',
                  style: i == rodada.numeroEscolhido - 1
                      ? Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            if (rodada.pistas.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Pistas dadas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final pista in rodada.pistas)
                    Chip(
                      label: Text(pista.texto),
                      backgroundColor: pista.anulada
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.14),
                      avatar: Icon(
                        pista.anulada ? Icons.block : Icons.check,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
