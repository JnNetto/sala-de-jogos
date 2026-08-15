import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'quiz_configuracao_screen.dart';

class QuizResultadoScreen extends StatelessWidget {
  const QuizResultadoScreen({super.key});

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
            final ranking = partida.ranking;
            final vencedor = ranking.first;
            final cor = Theme.of(context).colorScheme.primary;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Icon(Icons.emoji_events, size: 80, color: cor),
                    const SizedBox(height: 16),
                    Text(
                      'Vencedor',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      vencedor.nome,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    Text(
                      '${vencedor.pontos} pontos',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: cor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ranking',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: ranking.length,
                        itemBuilder: (context, i) {
                          final j = ranking[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: i == 0 ? cor : null,
                                foregroundColor: i == 0 ? Colors.white : null,
                                child: Text('${i + 1}'),
                              ),
                              title: Text(j.nome),
                              trailing: Text(
                                '${j.pontos} pts',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    PrimaryButton(
                      text: 'Voltar ao início',
                      icon: Icons.home,
                      onPressed: () {
                        provider.encerrarPartida();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const QuizConfiguracaoScreen(),
                          ),
                          (r) => r.isFirst,
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
