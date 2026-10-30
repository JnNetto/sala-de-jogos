import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/resistencia_constants.dart';
import '../../../core/enums/resistencia_papel.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../navegacao.dart';
import '../../providers/resistencia_partida_provider.dart';
import '../../widgets/expedicao/pecas_expedicao.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/dialogo.dart';
import '../../widgets/sala/tela_da_sala.dart';
import '../../widgets/sala/tela_de_revelacao.dart';
import 'expedicao_partida_screen.dart';

/// A revelação dos papéis: o celular passa de mão em mão e cada um segura
/// a carta para ver se é explorador ou saqueador.
class ExpedicaoDistribuicaoScreen extends StatelessWidget {
  const ExpedicaoDistribuicaoScreen({super.key});

  Future<void> _sair(BuildContext context, {required bool tudo}) async {
    final sair = await mostrarDialogo(
      context,
      matiz: matizExpedicao,
      perigo: true,
      icone: Symbols.logout_rounded,
      barra: 'ATENÇÃO',
      titulo: tudo ? 'Abortar a expedição?' : 'Voltar para os nomes?',
      corpo: 'Os papéis sorteados se perdem.',
      acao: tudo ? 'Abortar' : 'Voltar',
      escape: 'Continuar revelando',
    );
    if (sair != true || !context.mounted) return;
    context.read<ResistenciaPartidaProvider>().limparPartida();
    if (tudo) {
      Navigator.of(context).popUntil(ehBaseDosJogos);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final partida = context.watch<ResistenciaPartidaProvider>().partida;
    if (partida == null) {
      return const TelaDaSala(corpo: SizedBox.shrink());
    }
    final jogadores = partida.jogadores;
    final saqueadores = [
      for (final j in jogadores)
        if (j.papel == ResistenciaPapel.espiao) j,
    ];

    return TelaDeRevelacao(
      nomeDoJogo: ResistenciaConstants.jogoNome,
      matiz: matizExpedicao,
      nomes: [for (final j in jogadores) j.nome],
      espiao: (i) => jogadores[i].papel == ResistenciaPapel.espiao,
      dicaDoUltimo: 'Último da roda. Depois, a primeira câmara.',
      aoVoltar: () => _sair(context, tudo: false),
      aoAbortar: () => _sair(context, tudo: true),
      frente: (context, i, esconder, efeito) {
        final eu = jogadores[i];
        final saqueador = eu.papel == ResistenciaPapel.espiao;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FrenteDoPapel(
              saqueador: saqueador,
              outrosSaqueadores: [
                for (final s in saqueadores)
                  if (s.id != eu.id) s.nome,
              ],
            ),
            const SizedBox(height: Espaco.e4),
            BotaoSala(
              rotulo: 'Esconder e passar',
              icone: Symbols.visibility_rounded,
              variante: VarianteBotao.secundario,
              onPressed: esconder,
            ),
          ],
        );
      },
      fim: (context) => PainelTodosViram(
        titulo: 'Todos viram!',
        texto:
            'Celular no meio da mesa. ${partida.liderAtual.nome} é o primeiro '
            'guia.',
        acao: 'Começar a expedição',
        icone: Symbols.explore_rounded,
        matiz: matizExpedicao,
        aoContinuar: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ExpedicaoPartidaScreen()),
        ),
      ),
    );
  }
}
