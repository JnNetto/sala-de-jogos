import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/enums/vencedor.dart';
import '../providers/partida_provider.dart';
import '../widgets/primary_button.dart';
import 'resultado_screen.dart';

class VotacaoScreen extends StatefulWidget {
  const VotacaoScreen({super.key});

  @override
  State<VotacaoScreen> createState() => _VotacaoScreenState();
}

class _VotacaoScreenState extends State<VotacaoScreen> {
  int? _jogadorSelecionado;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Votação'),
          automaticallyImplyLeading: false,
        ),
        body: Consumer<PartidaProvider>(
          builder: (context, provider, _) {
            final partida = provider.partida;
            if (partida == null) {
              return const Center(child: Text('Erro: partida não encontrada'));
            }

            final jogadoresAtivos = partida.jogadoresAtivos;

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
                          Icons.how_to_vote,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Quem é o espião?',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: jogadoresAtivos.length,
                      itemBuilder: (context, index) {
                        final jogador = jogadoresAtivos[index];
                        final isSelecionado = _jogadorSelecionado == jogador.id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isSelecionado ? 8 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelecionado
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _jogadorSelecionado = jogador.id;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isSelecionado
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        jogador.id.toString(),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isSelecionado
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      jogador.nome,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: isSelecionado
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ),
                                  if (isSelecionado)
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 28,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: 'Confirmar Voto',
                        icon: Icons.check,
                        onPressed: _jogadorSelecionado != null
                            ? () => _confirmarVoto(context, provider)
                            : null,
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

  void _confirmarVoto(BuildContext context, PartidaProvider provider) {
    if (_jogadorSelecionado == null) return;

    final partida = provider.partida;
    if (partida == null) return;

    final jogadorVotado = partida.jogadores.firstWhere(
      (j) => j.id == _jogadorSelecionado,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Voto'),
        content: Text('Vocês votaram em ${jogadorVotado.nome}. Confirmar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.votarJogador(_jogadorSelecionado!);

              final partidaAtualizada = provider.partida!;

              _mostrarResultadoVotacao(
                context,
                jogadorVotado,
                partidaAtualizada.vencedor,
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _mostrarResultadoVotacao(
    BuildContext context,
    dynamic jogadorVotado,
    Vencedor vencedor,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_remove, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${jogadorVotado.nome} foi eliminado!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              if (vencedor != Vencedor.emAndamento) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ResultadoScreen(),
                  ),
                );
              } else {
                setState(() {
                  _jogadorSelecionado = null;
                });
              }
            },
            child: const Text(
              'Continuar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
