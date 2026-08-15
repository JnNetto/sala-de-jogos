import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'pergunta_discussao_screen.dart';

class PerguntaRevelacaoRespostasScreen extends StatelessWidget {
  const PerguntaRevelacaoRespostasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Respostas'),
          automaticallyImplyLeading: false,
        ),
        body: Consumer<PerguntaPartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            if (partida == null) {
              return const Center(child: Text('Erro: partida não encontrada'));
            }

            return SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    child: Column(
                      children: [
                        Icon(
                          Icons.forum,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quem respondeu fora do tom?',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A pergunta oficial ainda é secreta',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: partida.jogadores.length,
                      itemBuilder: (context, index) {
                        final jogador = partida.jogadores[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${jogador.id}')),
                            title: Text(
                              jogador.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              jogador.resposta ?? '—',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: 'Revelar Pergunta',
                        icon: Icons.visibility,
                        onPressed: () {
                          provider.iniciarDiscussao();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PerguntaDiscussaoScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
