import 'package:flutter/material.dart';

import '../../../core/constants/lobisomem_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import 'lobisomem_configuracao_screen.dart';

class LobisomemHomeScreen extends StatelessWidget {
  const LobisomemHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(LobisomemConstants.jogoNome)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(
                child: Icon(
                  Icons.nightlight_round,
                  size: 100,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                LobisomemConstants.jogoNome,
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                LobisomemConstants.jogoDescricao,
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
                      builder: (_) => const LobisomemConfiguracaoScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
