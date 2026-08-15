import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'pergunta_resposta_jogador_screen.dart';
import 'pergunta_revelacao_respostas_screen.dart';

class PerguntaColetaRespostasScreen extends StatefulWidget {
  const PerguntaColetaRespostasScreen({super.key});

  @override
  State<PerguntaColetaRespostasScreen> createState() =>
      _PerguntaColetaRespostasScreenState();
}

class _PerguntaColetaRespostasScreenState
    extends State<PerguntaColetaRespostasScreen> {
  int _jogadorAtualIndex = 0;

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

            final todosResponderam =
                _jogadorAtualIndex >= partida.jogadores.length;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: _jogadorAtualIndex / partida.jogadores.length,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    if (!todosResponderam)
                      Text(
                        'Jogador ${_jogadorAtualIndex + 1} de ${partida.jogadores.length}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    const Spacer(),
                    if (!todosResponderam) ...[
                      Center(
                        child: Icon(
                          Icons.edit_note,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        partida.jogadores[_jogadorAtualIndex].nome,
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Passe o celular para este jogador responder',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      const Center(
                        child: Icon(
                          Icons.check_circle,
                          size: 100,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Todos responderam!',
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: todosResponderam
                          ? PrimaryButton(
                              text: 'Ver Respostas',
                              icon: Icons.visibility,
                              onPressed: () {
                                provider.iniciarRevelacaoRespostas();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PerguntaRevelacaoRespostasScreen(),
                                  ),
                                );
                              },
                            )
                          : PrimaryButton(
                              text: 'Escrever Resposta',
                              icon: Icons.edit,
                              onPressed: () async {
                                final jogador =
                                    partida.jogadores[_jogadorAtualIndex];
                                final resposta = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PerguntaRespostaJogadorScreen(
                                          jogador: jogador,
                                          pergunta: partida.perguntaPara(
                                            jogador,
                                          ),
                                        ),
                                  ),
                                );
                                if (resposta != null && mounted) {
                                  provider.registrarResposta(
                                    jogador.id,
                                    resposta,
                                  );
                                  setState(() => _jogadorAtualIndex++);
                                }
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
