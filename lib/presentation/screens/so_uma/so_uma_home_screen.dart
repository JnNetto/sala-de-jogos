import 'package:flutter/material.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../widgets/primary_button.dart';
import 'so_uma_configuracao_screen.dart';
import 'so_uma_entrada_sala_screen.dart';
import 'so_uma_sala_router_screen.dart';

class SoUmaHomeScreen extends StatelessWidget {
  const SoUmaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(SoUmaConstants.jogoNome)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Icon(
                  Icons.lightbulb_outline,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                SoUmaConstants.jogoNome,
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                SoUmaConstants.jogoDescricao,
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
                      builder: (_) => const SoUmaConfiguracaoScreen(),
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
                          const SoUmaEntradaSalaScreen(criarSala: true),
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
                          const SoUmaEntradaSalaScreen(criarSala: false),
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
                      builder: (_) => const SoUmaSalaRouterScreen(
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
