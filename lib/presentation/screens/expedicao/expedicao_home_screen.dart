import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/jogos_disponiveis.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../widgets/expedicao/pecas_expedicao.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/cartao_config.dart';
import '../../widgets/sala/dialogo.dart';
import '../../widgets/sala/home_do_jogo.dart';
import '../../widgets/sala/tela_da_sala.dart';
import 'expedicao_configuracao_screen.dart';
import 'expedicao_entrada_sala_screen.dart';

class ExpedicaoHomeScreen extends StatelessWidget {
  const ExpedicaoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeDoJogo(
      jogo: JogosDisponiveis.todos.firstWhere(
        (j) => j.id == JogosDisponiveis.idResistencia,
      ),
      resumo:
          'Uma expedição por cinco câmaras de um templo. Alguns de vocês são '
          'saqueadores disfarçados, armando armadilhas pelo caminho.',
      passos: const [
        'O guia escolhe quem entra na câmara. Todos votam se a equipe segue.',
        'Quem entra joga em segredo: Avançar ou Armadilha.',
        'Três câmaras exploradas, os exploradores vencem. Três armadilhas, '
            'os saqueadores.',
      ],
      aoJogar: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExpedicaoModoScreen()),
      ),
      aoVerRegras: () => mostrarDialogo(
        context,
        matiz: matizExpedicao,
        barra: 'REGRAS',
        titulo: 'Como se joga',
        corpo:
            'Cada um recebe um papel em segredo: explorador ou saqueador. '
            'Os saqueadores sabem quem são os outros.\n\n'
            'A cada câmara, o guia da vez escolhe a equipe e todos votam. '
            'Com a maioria a favor, a equipe entra; senão, uma das cinco '
            'tochas se apaga e o próximo guia tenta. Se as cinco se '
            'apagarem na partida, os saqueadores vencem.\n\n'
            'Quem entra joga uma carta em segredo. Exploradores só '
            'avançam; saqueadores podem armar uma armadilha. Uma basta '
            'para a câmara cair (na 4ª câmara, com 7 ou mais, precisa de '
            'duas).\n\n'
            'A Lanterna: uma vez por partida, o guia de uma câmara pode ver '
            'a carta que alguém da equipe jogou nela.',
        acao: 'Entendi',
      ),
    );
  }
}

/// Como a turma vai jogar: passando um celular só ou cada um no seu.
class ExpedicaoModoScreen extends StatelessWidget {
  const ExpedicaoModoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(matizExpedicao);

    return TelaDaSala(
      titulo: 'Expedição',
      matiz: matizExpedicao,
      corpo: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espaco.margemTela,
          Espaco.e4,
          Espaco.margemTela,
          Espaco.e6,
        ),
        children: [
          Text('Como vão jogar?', style: texto.headlineLarge),
          const SizedBox(height: Espaco.e2),
          Text(
            'As regras são as mesmas. Muda só quem segura o celular.',
            style: texto.bodyLarge?.copyWith(color: c.texto2),
          ),
          const SizedBox(height: Espaco.e6),
          CartaoConfig(
            icone: Symbols.smartphone_rounded,
            titulo: 'Num celular só',
            subtitulo:
                'O celular passa de mão em mão para ver o papel e jogar as '
                'cartas. Os votos são abertos, na mesa. Sem internet.',
            luz: luz,
            controle: BotaoSala(
              rotulo: 'Passar o celular',
              icone: Symbols.arrow_forward_rounded,
              iconeNoFim: true,
              luz: luz,
              bloco: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExpedicaoConfiguracaoScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: Espaco.e3),
          CartaoConfig(
            icone: Symbols.devices_rounded,
            titulo: 'Cada um no seu',
            subtitulo:
                'Uma sala online com código. Cada um vê o papel, vota e '
                'joga as cartas no próprio celular.',
            luz: luz,
            controle: BotaoSala(
              rotulo: 'Sala online',
              icone: Symbols.wifi_rounded,
              variante: VarianteBotao.secundario,
              bloco: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExpedicaoEntradaSalaScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
