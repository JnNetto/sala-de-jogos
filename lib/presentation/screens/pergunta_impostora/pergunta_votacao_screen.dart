import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/enums/vencedor.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'pergunta_resultado_screen.dart';

class PerguntaVotacaoScreen extends StatefulWidget {
  const PerguntaVotacaoScreen({super.key});

  @override
  State<PerguntaVotacaoScreen> createState() => _PerguntaVotacaoScreenState();
}

class _PerguntaVotacaoScreenState extends State<PerguntaVotacaoScreen> {
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
        body: Consumer<PerguntaPartidaProvider>(
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
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quem é o impostor?',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'A pergunta era:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          partida.par.principal,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          textAlign: TextAlign.center,
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
                              setState(() => _jogadorSelecionado = jogador.id);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isSelecionado
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[200],
                                    child: Text(
                                      '${jogador.id}',
                                      style: TextStyle(
                                        color: isSelecionado
                                            ? Colors.white
                                            : Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          jogador.nome,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                        if (jogador.resposta != null)
                                          Text(
                                            '"${jogador.resposta}"',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelecionado)
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
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
                    padding: const EdgeInsets.all(16),
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

  void _confirmarVoto(BuildContext context, PerguntaPartidaProvider provider) {
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
              final vencedor = provider.partida!.vencedor;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (resultContext) => AlertDialog(
                  title: Text('${jogadorVotado.nome} foi eliminado!'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(resultContext);
                        if (vencedor != Vencedor.emAndamento) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PerguntaResultadoScreen(),
                            ),
                          );
                        } else {
                          setState(() => _jogadorSelecionado = null);
                        }
                      },
                      child: const Text('Continuar'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
