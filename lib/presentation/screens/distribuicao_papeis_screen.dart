import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/theme/sala_tokens.dart';
import '../../data/models/jogador_partida.dart';
import '../../data/models/partida_atual.dart';
import '../navegacao.dart';
import '../providers/partida_provider.dart';
import '../widgets/sala/botao_sala.dart';
import '../widgets/sala/dialogo.dart';
import '../widgets/sala/selo_papel.dart';
import '../widgets/sala/carta_revelacao.dart';
import '../widgets/sala/tela_da_sala.dart';
import '../widgets/sala/tela_de_revelacao.dart';
import 'inicio_discussao_screen.dart';

/// A revelação dos papéis: o celular passa de mão em mão e cada um segura
/// a carta para ver o próprio papel. O varal do topo acende uma lâmpada
/// por jogador que já viu.
class DistribuicaoPapeisScreen extends StatefulWidget {
  const DistribuicaoPapeisScreen({super.key});

  @override
  State<DistribuicaoPapeisScreen> createState() =>
      _DistribuicaoPapeisScreenState();
}

class _DistribuicaoPapeisScreenState extends State<DistribuicaoPapeisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartidaProvider>().iniciarDistribuicaoPapeis();
    });
  }

  Future<void> _voltar() async {
    final sair = await mostrarDialogo(
      context,
      matiz: Matiz.violeta,
      barra: 'ATENÇÃO',
      icone: Symbols.arrow_back_rounded,
      titulo: 'Voltar para as categorias?',
      corpo:
          'Os papéis já sorteados se perdem. Uma nova palavra sai '
          'quando vocês começarem de novo.',
      acao: 'Voltar',
      escape: 'Continuar revelando',
      perigo: true,
    );
    if (sair != true || !mounted) return;
    context.read<PartidaProvider>().encerrarPartida();
    Navigator.of(context).pop();
  }

  Future<void> _abortar() async {
    final abortar = await mostrarDialogo(
      context,
      matiz: Matiz.violeta,
      barra: 'ATENÇÃO',
      icone: Symbols.stop_circle_rounded,
      titulo: 'Abortar a partida?',
      corpo:
          'A palavra e os papéis sorteados se perdem. Vocês voltam para '
          'a escolha de jogadores.',
      acao: 'Abortar',
      escape: 'Continuar jogando',
      perigo: true,
    );
    if (abortar != true || !mounted) return;
    context.read<PartidaProvider>().encerrarPartida();
    Navigator.of(context).popUntil(ehInicioDoEspiao);
  }

  @override
  Widget build(BuildContext context) {
    final partida = context.watch<PartidaProvider>().partida;
    if (partida == null) {
      return const TelaDaSala(
        corpo: Center(child: Text('A partida não começou.')),
      );
    }
    final jogadores = partida.jogadores;
    return TelaDeRevelacao(
      nomeDoJogo: 'Quem é o Espião?',
      matiz: Matiz.violeta,
      nomes: [for (final j in jogadores) j.nome],
      espiao: (i) => jogadores[i].isEspiao,
      dicaDoUltimo: 'Último da roda. Depois, a conversa.',
      aoVoltar: _voltar,
      aoAbortar: _abortar,
      frente: (context, i, esconder, efeito) => _FrenteDoPapel(
        jogador: jogadores[i],
        partida: partida,
        esconder: esconder,
        efeito: efeito,
      ),
      fim: (context) => PainelTodosViram(
        titulo: 'Todos viram!',
        texto: 'Celular no meio da mesa. Hora de descobrir quem é o espião.',
        acao: 'Começar a conversa',
        icone: Symbols.forum_rounded,
        matiz: Matiz.violeta,
        aoContinuar: () {
          context.read<PartidaProvider>().iniciarDiscussao();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const InicioDiscussaoScreen(),
            ),
          );
        },
      ),
    );
  }
}

/// A frente da carta: selo do papel, ícone com brilho e a palavra (ou a
/// falta dela), mais "Esconder e passar".
class _FrenteDoPapel extends StatelessWidget {
  const _FrenteDoPapel({
    required this.jogador,
    required this.partida,
    required this.esconder,
    required this.efeito,
  });

  final JogadorPartida jogador;
  final PartidaAtual partida;
  final VoidCallback esconder;
  final Animation<double> efeito;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final espiao = jogador.isEspiao;
    final luz = espiao ? c.papelEspiao : c.papelCivil;
    final pista = partida.palavraRelacionada;

    final icone = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: c.brilho(luz.cor, alpha: .4, blur: 48),
      ),
      child: Icon(
        espiao ? Symbols.visibility_off_rounded : Symbols.key_rounded,
        size: 60,
        fill: 1,
        color: luz.tinta,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        espiao
            ? SeloPapel.espiao(context, texto: 'VOCÊ É O ESPIÃO')
            : SeloPapel.civil(context, texto: 'VOCÊ É CIVIL'),
        const SizedBox(height: Espaco.e4),
        espiao ? icone : Faiscas(efeito: efeito, child: icone),
        const SizedBox(height: Espaco.e4),
        if (!espiao) ...[
          Text(
            'A PALAVRA É',
            style: texto.labelSmall?.copyWith(color: c.texto3),
          ),
          const SizedBox(height: Espaco.e2),
          BlocoPalavra(palavra: partida.palavraSecreta.texto, luz: luz),
        ] else if (pista != null) ...[
          Text(
            'SUA PISTA É',
            style: texto.labelSmall?.copyWith(color: c.texto3),
          ),
          const SizedBox(height: Espaco.e2),
          BlocoPalavra(palavra: pista.texto, luz: luz),
          const SizedBox(height: Espaco.e2),
          Text(
            'Parecida, mas não é a dos outros.',
            textAlign: TextAlign.center,
            style: texto.bodySmall?.copyWith(color: c.texto2),
          ),
        ] else ...[
          Text(
            'Você não sabe a palavra.',
            textAlign: TextAlign.center,
            style: texto.titleLarge,
          ),
          const SizedBox(height: Espaco.e2),
          Text(
            'Escute as perguntas, finja que sabe e tente descobrir antes '
            'da votação.',
            textAlign: TextAlign.center,
            style: texto.bodyMedium?.copyWith(color: c.texto2),
          ),
        ],
        const SizedBox(height: Espaco.e4),
        BotaoSala(
          rotulo: 'Esconder e passar',
          icone: Symbols.visibility_rounded,
          variante: VarianteBotao.secundario,
          onPressed: esconder,
        ),
      ],
    );
  }
}
