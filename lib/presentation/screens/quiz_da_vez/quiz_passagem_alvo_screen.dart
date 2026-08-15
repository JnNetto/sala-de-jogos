import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'quiz_pergunta_screen.dart';

class QuizPassagemAlvoScreen extends StatelessWidget {
  const QuizPassagemAlvoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Consumer<QuizPartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            final alvo = partida?.alvoDoPasse;
            if (partida == null || alvo == null) {
              return const Center(child: Text('Erro'));
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Center(
                      child: Icon(
                        Icons.swap_horiz,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${partida.jogadorDaRodada.nome} passou para',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      alvo.nome,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Passe o celular — o tempo será reiniciado',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    PrimaryButton(
                      text: 'Estou pronto',
                      icon: Icons.check,
                      onPressed: () {
                        provider.iniciarPerguntaAlvo();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QuizPerguntaScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
