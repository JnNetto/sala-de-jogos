import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/tela_da_sala.dart';
import '../../widgets/sala/tela_de_revelacao.dart';
import 'pergunta_cartas.dart';
import 'pergunta_revelacao_respostas_screen.dart';

/// Segunda roda: o celular passa de novo, cada um segura a carta, revê a
/// pergunta e escreve a resposta numa folha. Ao guardar, a carta vira e
/// passa.
class PerguntaColetaRespostasScreen extends StatelessWidget {
  const PerguntaColetaRespostasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerguntaPartidaProvider>();
    final partida = provider.partida;
    if (partida == null) {
      return const TelaDaSala(
        corpo: Center(child: Text('A partida terminou.')),
      );
    }
    final jogadores = partida.jogadores;
    void abortar() => abortarPerguntaImpostora(
      context,
      corpo:
          'As respostas escritas até aqui se perdem. Vocês voltam para a '
          'escolha de jogadores.',
      escape: 'Continuar respondendo',
    );

    return TelaDeRevelacao(
      nomeDoJogo: 'Pergunta Impostora',
      matiz: Matiz.rosa,
      sobretitulo: 'AS RESPOSTAS',
      feito: 'JÁ RESPONDERAM',
      nomes: [for (final j in jogadores) j.nome],
      dicaDoUltimo: 'Último a responder.',
      // Voltar no meio das respostas é o mesmo que desistir da partida.
      aoVoltar: abortar,
      aoAbortar: abortar,
      frente: (context, i, esconder, efeito) {
        final jogador = jogadores[i];
        final pergunta = partida.perguntaPara(jogador);
        return FrentePergunta(
          pergunta: pergunta,
          efeito: efeito,
          dica: 'Responda com sinceridade, em poucas palavras.',
          acao: BotaoSala(
            rotulo: 'Escrever resposta',
            icone: Symbols.edit_rounded,
            luz: context.cores.luz(Matiz.rosa),
            onPressed: () async {
              final resposta = await escreverResposta(
                context,
                nome: jogador.nome,
                pergunta: pergunta,
              );
              if (resposta == null || !context.mounted) return;
              context.read<PerguntaPartidaProvider>().registrarResposta(
                jogador.id,
                resposta,
              );
              esconder();
            },
          ),
        );
      },
      fim: (context) => PainelTodosViram(
        titulo: 'Todos responderam!',
        texto: 'Celular no meio da mesa: hora de ler as respostas.',
        acao: 'Ver as respostas',
        icone: Symbols.forum_rounded,
        matiz: Matiz.rosa,
        aoContinuar: () {
          context.read<PerguntaPartidaProvider>().iniciarRevelacaoRespostas();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const PerguntaRevelacaoRespostasScreen(),
            ),
          );
        },
      ),
    );
  }
}
