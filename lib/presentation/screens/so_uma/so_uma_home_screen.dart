import 'package:flutter/material.dart';

import '../../../core/constants/jogos_disponiveis.dart';
import '../../widgets/sala/dialogo.dart';
import '../../widgets/sala/home_do_jogo.dart';
import '../../widgets/so_uma/pecas_so_uma.dart';
import 'so_uma_modo_screen.dart';

class SoUmaHomeScreen extends StatelessWidget {
  const SoUmaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeDoJogo(
      jogo: JogosDisponiveis.todos.firstWhere(
        (j) => j.id == JogosDisponiveis.idSoUma,
      ),
      resumo:
          'Um adivinha, os outros dão pistas de uma palavra só. Pistas '
          'repetidas se anulam, então combinem sem combinar.',
      passos: const [
        'Quem adivinha escolhe, às cegas, uma das cinco palavras da carta.',
        'Os outros escrevem uma pista cada. As iguais são anuladas.',
        'Com o que sobrou, é hora de chutar. Juntos, ganhem 13 cartas.',
      ],
      aoJogar: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SoUmaModoScreen()),
      ),
      aoVerRegras: () => mostrarDialogo(
        context,
        matiz: matizSoUma,
        barra: 'REGRAS',
        titulo: 'Como se joga',
        corpo:
            'O jogo é cooperativo: o grupo tenta ganhar as 13 cartas do '
            'baralho.\n\n'
            'A cada rodada, uma pessoa adivinha. Ela escolhe um número de 1 '
            'a 5 sem ver a carta, e os outros veem qual palavra saiu.\n\n'
            'Cada um escreve uma pista de uma palavra só (com 3 pessoas, '
            'duas cada). Pistas iguais ou da mesma família se anulam, e '
            'quem adivinha só vê as que sobraram.\n\n'
            'Acertou: o grupo ganha a carta. Passou: a carta sai. Errou: '
            'a carta sai e a próxima do baralho também.',
        acao: 'Entendi',
      ),
    );
  }
}
