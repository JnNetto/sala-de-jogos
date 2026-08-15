import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_partida_provider.dart';
import 'quiz_passagem_alvo_screen.dart';

class QuizEscolhaAlvoScreen extends StatelessWidget {
  const QuizEscolhaAlvoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Passar para quem?'),
          automaticallyImplyLeading: false,
        ),
        body: Consumer<QuizPartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            if (partida == null) {
              return const Center(child: Text('Erro'));
            }
            final donoId = partida.jogadorDaRodada.id;
            final elegiveis = partida.jogadores
                .where((j) => j.id != donoId)
                .toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: elegiveis.length,
              itemBuilder: (context, index) {
                final j = elegiveis[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${j.id}')),
                    title: Text(j.nome),
                    subtitle: Text('${j.pontos} pts'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      provider.selecionarAlvo(j.id);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QuizPassagemAlvoScreen(),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
