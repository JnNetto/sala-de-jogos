import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/resistencia_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'resistencia_proposta_screen.dart';
import 'resistencia_revelacao_papel_screen.dart';

class ResistenciaDistribuicaoScreen extends StatefulWidget {
  const ResistenciaDistribuicaoScreen({super.key});

  @override
  State<ResistenciaDistribuicaoScreen> createState() =>
      _ResistenciaDistribuicaoScreenState();
}

class _ResistenciaDistribuicaoScreenState
    extends State<ResistenciaDistribuicaoScreen> {
  int _jogadorAtualIndex = 0;

  Future<void> _confirmarSaida() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair da partida?'),
          content: const Text('A partida atual da Resistência será cancelada.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<ResistenciaPartidaProvider>().limparPartida();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Revelação de Papéis'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _confirmarSaida,
            tooltip: 'Cancelar partida',
          ),
        ),
        body: Consumer<ResistenciaPartidaProvider>(
          builder: (context, provider, _) {
            final sorteio = provider.sorteio;
            if (sorteio == null) {
              return const Center(child: Text('Partida não iniciada'));
            }

            final jogadores = sorteio.jogadores;
            final todosViram = _jogadorAtualIndex >= jogadores.length;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _jogadorAtualIndex / jogadores.length,
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    if (!todosViram)
                      Text(
                        'Jogador ${_jogadorAtualIndex + 1} de ${jogadores.length}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    const Spacer(),
                    if (!todosViram) ...[
                      Icon(
                        Icons.person,
                        size: 100,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        jogadores[_jogadorAtualIndex].nome,
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Passe o celular para esta pessoa. Ela deve segurar para revelar.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      const Icon(
                        Icons.check_circle,
                        size: 100,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Todos viram seus papéis',
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'O líder inicial e ${jogadores.first.nome}.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: todosViram
                          ? PrimaryButton(
                              text: 'Propor Primeira Equipe',
                              icon: Icons.arrow_forward,
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ResistenciaPropostaScreen(),
                                  ),
                                );
                              },
                            )
                          : PrimaryButton(
                              text: 'Revelar Papel',
                              icon: Icons.visibility,
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ResistenciaRevelacaoPapelScreen(
                                          jogador:
                                              jogadores[_jogadorAtualIndex],
                                          jogadores: jogadores,
                                        ),
                                  ),
                                );
                                if (!mounted) return;
                                setState(() => _jogadorAtualIndex++);
                              },
                            ),
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
