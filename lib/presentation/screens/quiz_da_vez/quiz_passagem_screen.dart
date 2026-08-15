import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'quiz_categoria_screen.dart';
import 'quiz_configuracao_screen.dart';

class QuizPassagemScreen extends StatelessWidget {
  const QuizPassagemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Consumer<QuizPartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            if (partida == null) {
              return const Center(child: Text('Erro'));
            }
            final jogador = partida.jogadorDaRodada;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _sair(context, provider),
                      ),
                    ),
                    Text(
                      'Rodada ${partida.rodadaExibicao} de ${partida.totalRodadas}',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Center(
                      child: Icon(
                        Icons.phone_android,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Passe o celular para',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      jogador.nome,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const Spacer(),
                    PrimaryButton(
                      text: 'Estou pronto',
                      icon: Icons.check,
                      isLoading: provider.isLoading,
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await provider.prepararRodada();
                        if (ok && context.mounted) {
                          nav.pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const QuizCategoriaScreen(),
                            ),
                          );
                        } else if (provider.erro != null && context.mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(provider.erro!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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

  Future<void> _sair(BuildContext context, QuizPartidaProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da partida?'),
        content: const Text('O progresso será perdido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      provider.encerrarPartida();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const QuizConfiguracaoScreen()),
        (r) => r.isFirst,
      );
    }
  }
}
