import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/dialogo.dart';
import '../../widgets/sala/tela_da_sala.dart';
import '../../widgets/sala/tela_de_revelacao.dart';
import 'pergunta_cartas.dart';
import 'pergunta_coleta_respostas_screen.dart';

/// Primeira roda: cada um segura a carta e só olha a sua pergunta. As
/// respostas vêm na segunda roda.
class PerguntaDistribuicaoScreen extends StatefulWidget {
  const PerguntaDistribuicaoScreen({super.key});

  @override
  State<PerguntaDistribuicaoScreen> createState() =>
      _PerguntaDistribuicaoScreenState();
}

class _PerguntaDistribuicaoScreenState
    extends State<PerguntaDistribuicaoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerguntaPartidaProvider>().iniciarDistribuicao();
    });
  }

  Future<void> _voltar() async {
    final sair = await mostrarDialogo(
      context,
      matiz: Matiz.rosa,
      barra: 'ATENÇÃO',
      icone: Symbols.arrow_back_rounded,
      titulo: 'Voltar para os ajustes?',
      corpo:
          'As perguntas já sorteadas se perdem. Um novo par sai quando '
          'vocês começarem de novo.',
      acao: 'Voltar',
      escape: 'Continuar olhando',
      perigo: true,
    );
    if (sair != true || !mounted) return;
    context.read<PerguntaPartidaProvider>().encerrarPartida();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final partida = context.watch<PerguntaPartidaProvider>().partida;
    if (partida == null) {
      return const TelaDaSala(
        corpo: Center(child: Text('A partida não começou.')),
      );
    }
    final jogadores = partida.jogadores;
    return TelaDeRevelacao(
      nomeDoJogo: 'Pergunta Impostora',
      matiz: Matiz.rosa,
      sobretitulo: 'AS PERGUNTAS',
      nomes: [for (final j in jogadores) j.nome],
      dicaDoUltimo: 'Último da roda. Depois, as respostas.',
      aoVoltar: _voltar,
      aoAbortar: () => abortarPerguntaImpostora(
        context,
        corpo:
            'As perguntas sorteadas se perdem. Vocês voltam para a escolha '
            'de jogadores.',
      ),
      frente: (context, i, esconder, efeito) => FrentePergunta(
        pergunta: partida.perguntaPara(jogadores[i]),
        efeito: efeito,
        dica: 'Guarde de cabeça. Ainda não é hora de responder.',
        acao: BotaoSala(
          rotulo: 'Esconder e passar',
          icone: Symbols.visibility_rounded,
          variante: VarianteBotao.secundario,
          onPressed: esconder,
        ),
      ),
      fim: (context) => PainelTodosViram(
        titulo: 'Todos viram!',
        texto:
            'Agora o celular roda de novo: cada um revê a pergunta e '
            'escreve a resposta.',
        acao: 'Começar as respostas',
        icone: Symbols.edit_note_rounded,
        matiz: Matiz.rosa,
        aoContinuar: () {
          context.read<PerguntaPartidaProvider>().iniciarColetaRespostas();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const PerguntaColetaRespostasScreen(),
            ),
          );
        },
      ),
    );
  }
}
