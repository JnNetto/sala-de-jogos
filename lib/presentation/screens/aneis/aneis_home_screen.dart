import 'package:flutter/material.dart';

import '../../../core/constants/aneis_constants.dart';
import '../../widgets/primary_button.dart';
import 'aneis_entrada_sala_screen.dart';
import 'aneis_sala_router_screen.dart';

class AneisHomeScreen extends StatelessWidget {
  const AneisHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AneisConstants.jogoNome)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(
                child: Icon(
                  Icons.filter_tilt_shift,
                  size: 100,
                  color: AneisConstants.corPalavra,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AneisConstants.jogoNome,
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AneisConstants.jogoDescricao,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Criar sala online',
                icon: Icons.cloud,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AneisEntradaSalaScreen(criarSala: true),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AneisEntradaSalaScreen(criarSala: false),
                    ),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Entrar com código'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AneisSalaRouterScreen(
                        restaurarUltimaSala: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.restore),
                label: const Text('Continuar sala online'),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
