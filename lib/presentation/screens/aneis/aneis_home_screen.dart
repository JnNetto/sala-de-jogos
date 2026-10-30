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
          'Três anéis, três regras secretas. Descubra onde cada carta '
          'cabe e esvazie a mão antes de todo mundo.',
      passos: const [
        'Um cria a sala e passa o código. Cada um joga no seu celular.',
        'Na sua vez, coloque uma carta na região que achar certa.',
        'Acertou, joga de novo. Ou arrisque dizer a regra de um anel.',
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
            'Cada anel tem uma regra secreta: a Letra (como a palavra se '
            'escreve ou soa), o Jeito (o que a coisa é ou tem) e o Lugar '
            '(onde aparece ou para que se usa).\n\n'
            'Uma carta entra em todos os anéis cuja regra ela cumpre, '
            'inclusive nas interseções. Se não cumpre nenhuma, fica fora.\n\n'
            'O Guardião conhece as regras: pode ser uma pessoa ou o próprio '
            'jogo. Ele começa com uma pista em cada anel e uma fora.\n\n'
            'Na sua vez, jogue uma carta numa região. Acertou, joga de novo; '
            'errou, a carta vai para o lugar certo e você compra outra.\n\n'
            'Ou tente desvendar a regra de um anel: acertando, descarta duas '
            'cartas e o anel fica aberto para todos; errando, compra uma.',
        acao: 'Entendi',
      ),
    );
  }
}
