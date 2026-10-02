import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../../core/enums/so_uma_resultado_rodada.dart';
import '../../providers/so_uma_partida_provider.dart';
import '../../widgets/primary_button.dart';

class SoUmaResultadoFinalScreen extends StatelessWidget {
  const SoUmaResultadoFinalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SoUmaPartidaProvider>();
    final partida = provider.partida;
    if (partida == null) {
      return const Scaffold(body: Center(child: Text('Partida não iniciada')));
    }

    final faixa = SoUmaConstants.faixaDesempenho(partida.cartasGanhas);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fim de Jogo'),
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
                      Icon(
                        Icons.emoji_events,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${partida.cartasGanhas} / ${SoUmaConstants.totalCartasPartida}',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        faixa,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rodada a rodada',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      for (final rodada in partida.historico)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            switch (rodada.resultado) {
                              SoUmaResultadoRodada.acerto => Icons.check_circle,
                              SoUmaResultadoRodada.erro => Icons.cancel,
                              SoUmaResultadoRodada.passou => Icons.skip_next,
                              null => Icons.help_outline,
                            },
                            color: switch (rodada.resultado) {
                              SoUmaResultadoRodada.acerto => Colors.green,
                              SoUmaResultadoRodada.erro => Colors.red,
                              SoUmaResultadoRodada.passou => Colors.orange,
                              null => Colors.grey,
                            },
                          ),
                          title: Text(
                            '${rodada.adivinhador.nome} — "${rodada.palavraAlvo}"',
                          ),
                          subtitle: Text(
                            rodada.palpite != null
                                ? 'Respondeu "${rodada.palpite}"'
                                : 'Passou',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Voltar ao Início',
                icon: Icons.home,
                onPressed: () {
                  provider.limparPartida();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
