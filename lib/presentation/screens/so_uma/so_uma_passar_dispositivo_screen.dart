import 'package:flutter/material.dart';

import '../../widgets/primary_button.dart';

class SoUmaPassarDispositivoScreen extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String textoBotao;
  final IconData icone;
  final VoidCallback onConfirmar;

  const SoUmaPassarDispositivoScreen({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.onConfirmar,
    this.textoBotao = 'Pronto',
    this.icone = Icons.phonelink_ring,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                icone,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                titulo,
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                subtitulo,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryButton(
                text: textoBotao,
                icon: Icons.check,
                onPressed: onConfirmar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
