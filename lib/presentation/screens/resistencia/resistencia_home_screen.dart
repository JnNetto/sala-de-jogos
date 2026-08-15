import 'package:flutter/material.dart';

import '../../../core/constants/resistencia_constants.dart';
import '../../widgets/primary_button.dart';
import 'resistencia_configuracao_screen.dart';
import 'resistencia_entrada_sala_screen.dart';
import 'resistencia_sala_router_screen.dart';

class ResistenciaHomeScreen extends StatelessWidget {
  const ResistenciaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ResistenciaConstants.jogoNome)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Icon(
                  Icons.shield_outlined,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                ResistenciaConstants.jogoNome,
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                ResistenciaConstants.jogoDescricao,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Jogar neste celular',
                icon: Icons.add,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResistenciaConfiguracaoScreen(),
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
                          const ResistenciaEntradaSalaScreen(criarSala: true),
                    ),
                  );
                },
                icon: const Icon(Icons.cloud),
                label: const Text('Criar sala online'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ResistenciaEntradaSalaScreen(criarSala: false),
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
                      builder: (_) => const ResistenciaSalaRouterScreen(
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
