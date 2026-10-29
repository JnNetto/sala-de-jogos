import 'package:flutter/material.dart';

import '../../../core/constants/jogos_disponiveis.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../navegacao.dart';
import '../../widgets/sala/dialogo.dart';
import '../../widgets/sala/home_do_jogo.dart';
import 'pergunta_configuracao_screen.dart';
import 'pergunta_estatisticas_screen.dart';

class PerguntaHomeScreen extends StatelessWidget {
  const PerguntaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeDoJogo(
      jogo: JogosDisponiveis.todos.firstWhere(
        (j) => j.id == JogosDisponiveis.idPergunta,
      ),
      resumo:
          'Todos recebem a mesma pergunta, menos o impostor, que recebe '
          'outra parecida. Respondam e descubram quem destoou.',
      passos: const [
        'Passem o celular. Cada um vê a pergunta em segredo.',
        'Passem de novo. Cada um escreve a resposta.',
        'Leiam as respostas e votem no impostor.',
      ],
      aoJogar: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: rotaImpostoraInicio),
          builder: (_) => const PerguntaConfiguracaoScreen(),
        ),
      ),
      aoVerRegras: () => mostrarDialogo(
        context,
        matiz: Matiz.rosa,
        barra: 'REGRAS',
        titulo: 'Como se joga',
        corpo:
            'Todos recebem a mesma pergunta, menos o impostor: ele recebe '
            'outra, parecida. Ninguém sabe quem é o impostor, nem ele '
            'mesmo.\n\n'
            'Cada um responde a sua em segredo. Depois as respostas são '
            'lidas e a pergunta de verdade é revelada.\n\n'
            'Na conversa, procurem a resposta que não combina e votem. Os '
            'civis vencem quando todos os impostores saem da mesa.',
        acao: 'Entendi',
      ),
      aoVerEstatisticas: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const PerguntaEstatisticasScreen(),
        ),
      ),
    );
  }
}
