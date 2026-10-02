import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/so_uma_partida_provider.dart';
import 'so_uma_escrever_pista_screen.dart';
import 'so_uma_passar_dispositivo_screen.dart';

class SoUmaEscolhaNumeroScreen extends StatefulWidget {
  const SoUmaEscolhaNumeroScreen({super.key});

  @override
  State<SoUmaEscolhaNumeroScreen> createState() =>
      _SoUmaEscolhaNumeroScreenState();
}

class _SoUmaEscolhaNumeroScreenState extends State<SoUmaEscolhaNumeroScreen> {
  bool _pronto = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SoUmaPartidaProvider>();
    final partida = provider.partida;
    if (partida == null) {
      return const Scaffold(body: Center(child: Text('Partida não iniciada')));
    }

    if (!_pronto) {
      return SoUmaPassarDispositivoScreen(
        titulo: 'Passe o celular para\n${partida.adivinhadorAtual.nome}',
        subtitulo:
            'Rodada ${partida.numeroRodadaAtual} de ${partida.historico.length + partida.cartasRestantesBaralho}. '
            'Ninguém mais pode ver a tela agora.',
        icone: Icons.person_pin_circle,
        onConfirmar: () => setState(() => _pronto = true),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Escolha às cegas'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Icons.style,
                  size: 96,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  '${partida.adivinhadorAtual.nome}, escolha um número de 1 a 5.',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Você não sabe o que vai encontrar. É às cegas mesmo.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (var numero = 1; numero <= 5; numero++)
                      _BotaoNumero(
                        numero: numero,
                        onTap: () => _escolher(context, numero),
                      ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _escolher(BuildContext context, int numero) {
    final provider = context.read<SoUmaPartidaProvider>();
    final ok = provider.escolherNumero(numero);
    if (!ok) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SoUmaEscreverPistaScreen()),
    );
  }
}

class _BotaoNumero extends StatelessWidget {
  final int numero;
  final VoidCallback onTap;

  const _BotaoNumero({required this.numero, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$numero',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
