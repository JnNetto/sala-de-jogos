import 'package:flutter/material.dart';

import '../../../core/constants/jogos_disponiveis.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../widgets/sala/dialogo.dart';
import '../../widgets/sala/home_do_jogo.dart';
import 'aneis_entrada_sala_screen.dart';

class AneisHomeScreen extends StatelessWidget {
  const AneisHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeDoJogo(
      jogo: JogosDisponiveis.todos.firstWhere(
        (j) => j.id == JogosDisponiveis.idAneis,
      ),
      offline: false,
      resumo:
          'Três anéis, três regras secretas. Encaixe suas cartas no lugar '
          'certo e descubra as regras antes de todo mundo.',
      passos: const [
        'Um cria a sala e passa o código. Cada um joga no seu celular.',
        'Na sua vez, coloque uma carta na região que achar certa.',
        'Acertou, joga de novo. Quem esvaziar a mão primeiro vence.',
      ],
      aoJogar: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AneisEntradaSalaScreen()),
      ),
      aoVerRegras: () => mostrarDialogo(
        context,
        matiz: Matiz.ceu,
        barra: 'REGRAS',
        titulo: 'Como se joga',
        corpo:
            'Cada anel tem uma regra secreta: um sobre a Palavra (escrita '
            'ou som), um sobre o Atributo (o que a coisa é) e um sobre o '
            'Contexto (onde se usa).\n\n'
            'Uma carta entra em todos os anéis cuja regra ela cumpre, '
            'inclusive nas interseções. Se não cumpre nenhuma, fica fora.\n\n'
            'Quem conhece as regras pode ser um jogador ou o próprio jogo. '
            'Na sua vez, escolha uma carta e uma região. Acertou, joga de '
            'novo; errou, a carta vai para o lugar certo e você compra '
            'outra.',
        acao: 'Entendi',
      ),
    );
  }
}
