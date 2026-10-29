import 'package:flutter/material.dart';

import '../../core/constants/jogos_disponiveis.dart';
import '../../core/theme/sala_tokens.dart';
import '../navegacao.dart';
import '../widgets/sala/dialogo.dart';
import '../widgets/sala/home_do_jogo.dart';
import 'configuracao_screen.dart';
import 'estatisticas_screen.dart';

class ImpostorHomeScreen extends StatelessWidget {
  const ImpostorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeDoJogo(
      jogo: JogosDisponiveis.todos.firstWhere(
        (j) => j.id == JogosDisponiveis.idEspiao,
      ),
      resumo:
          'Todos recebem a mesma palavra, menos o espião. '
          'Perguntem, desconfiem e descubram quem está perdido.',
      passos: const [
        'Passem o celular. Cada um vê a palavra em segredo.',
        'Façam perguntas sobre a palavra, uma por vez.',
        'Votem no suspeito antes que o espião se safe.',
      ],
      aoJogar: () => Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: rotaEspiaoInicio),
          builder: (context) => const ConfiguracaoScreen(),
        ),
      ),
      aoVerRegras: () => mostrarDialogo(
        context,
        matiz: Matiz.violeta,
        barra: 'REGRAS',
        titulo: 'Como se joga',
        corpo:
            'Todos recebem a mesma palavra secreta, menos o espião. Ele '
            'recebe uma pista parecida, ou nada, conforme os ajustes.\n\n'
            'Na discussão, cada um pergunta algo sobre a palavra para '
            'alguém da roda. Responda sem entregá-la.\n\n'
            'Na votação, eliminem quem parece perdido. Os civis vencem '
            'quando todos os espiões saem da mesa. Os espiões vencem se '
            'sobrarem só dois civis.',
        acao: 'Entendi',
      ),
      aoVerEstatisticas: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EstatisticasScreen()),
      ),
    );
  }
}
