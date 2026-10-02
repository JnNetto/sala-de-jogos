import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/so_uma_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'so_uma_resultado_rodada_screen.dart';

class SoUmaAdivinharScreen extends StatefulWidget {
  const SoUmaAdivinharScreen({super.key});

  @override
  State<SoUmaAdivinharScreen> createState() => _SoUmaAdivinharScreenState();
}

class _SoUmaAdivinharScreenState extends State<SoUmaAdivinharScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SoUmaPartidaProvider>();
    final partida = provider.partida;
    final rodada = partida?.rodadaAtual;
    if (partida == null || rodada == null) {
      return const Scaffold(body: Center(child: Text('Rodada não iniciada')));
    }

    final sobreviventes = rodada.pistasSobreviventes;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sua vez de adivinhar'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${partida.adivinhadorAtual.nome}, essas são as pistas que sobraram:',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (sobreviventes.isEmpty)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Todas as pistas foram anuladas. Melhor passar.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final pista in sobreviventes)
                        Chip(label: Text(pista.texto)),
                    ],
                  ),
                const SizedBox(height: 32),
                TextField(
                  controller: _controller,
                  autofocus: sobreviventes.isNotEmpty,
                  decoration: const InputDecoration(
                    labelText: 'Sua resposta',
                    prefixIcon: Icon(Icons.lightbulb_outline),
                  ),
                  onSubmitted: (_) => _adivinhar(context),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Adivinhar',
                  icon: Icons.check,
                  onPressed: () => _adivinhar(context),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _passar(context),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Passar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _adivinhar(BuildContext context) {
    final palpite = _controller.text.trim();
    if (palpite.isEmpty) return;
    context.read<SoUmaPartidaProvider>().responderRodada(palpite: palpite);
    _irParaResultado(context);
  }

  void _passar(BuildContext context) {
    context.read<SoUmaPartidaProvider>().responderRodada(passar: true);
    _irParaResultado(context);
  }

  void _irParaResultado(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SoUmaResultadoRodadaScreen()),
    );
  }
}
