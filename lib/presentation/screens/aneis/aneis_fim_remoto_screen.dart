import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/aneis_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/aneis_estado_remoto.dart';
import '../../../data/models/aneis_jogador_remoto.dart';
import '../../providers/aneis_sala_provider.dart';
import '../../widgets/aneis/cores_dos_aneis.dart';
import '../../widgets/aneis/folha_regiao.dart';
import '../../widgets/aneis/pecas_aneis.dart';
import '../../widgets/aneis/tabuleiro_aneis.dart';
import '../../widgets/sala/fim_de_jogo.dart';
import '../../widgets/sala/janela.dart';
import '../../widgets/sala/jogador_sala.dart';
import '../../widgets/sala/sala_online.dart';
import '../../widgets/sala/tela_da_sala.dart';

/// O fim de uma partida: quem esvaziou a mão, as regras que estavam
/// escondidas e o tabuleiro como ficou. O host leva a sala de volta ao lobby.
class AneisFimRemotoScreen extends StatelessWidget {
  const AneisFimRemotoScreen({
    super.key,
    required this.estado,
    required this.jogadores,
  });

  final AneisEstadoRemoto estado;
  final List<AneisJogadorRemoto> jogadores;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final provider = context.watch<AneisSalaProvider>();
    final venci =
        estado.vencedorUid != null && estado.vencedorUid == provider.uid;
    final vencedor = estado.vencedorNome ?? 'Alguém';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) {
          sairDaMesa(
            context,
            nomeDoJogo: AneisConstants.jogoNome,
            matiz: Matiz.ceu,
          );
        }
      },
      child: TelaDaSala(
        sobretitulo: 'NOS ANÉIS',
        titulo: 'Fim de jogo',
        matiz: Matiz.ceu,
        inicio: const BotaoSairDaMesa(
          nomeDoJogo: AneisConstants.jogoNome,
          matiz: Matiz.ceu,
        ),
        corpo: ListView(
          padding: const EdgeInsets.fromLTRB(
            Espaco.margemTela,
            Espaco.e4,
            Espaco.margemTela,
            Espaco.e6,
          ),
          children: [
            Janela(
              titulo: 'FIM DE JOGO',
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topRight,
                    children: [
                      AvatarJogador(
                        nome: vencedor,
                        indice: indiceDoJogador(jogadores, estado.vencedorUid),
                        tamanho: 80,
                        brilho: true,
                      ),
                      Positioned(
                        top: -14,
                        right: -14,
                        child: Icon(
                          Symbols.trophy_rounded,
                          fill: 1,
                          size: 32,
                          color: c.luz(Matiz.lampada).cor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Espaco.e4),
                  Text(
                    venci ? 'Você venceu!' : vencedor,
                    textAlign: TextAlign.center,
                    style: texto.displaySmall,
                  ),
                  const SizedBox(height: Espaco.e1),
                  Text(
                    venci
                        ? 'Sua mão ficou vazia primeiro.'
                        : 'esvaziou a mão primeiro e venceu.',
                    textAlign: TextAlign.center,
                    style: texto.bodyLarge?.copyWith(color: c.texto2),
                  ),
                ],
              ),
            ),
            if (estado.regrasReveladas.isNotEmpty) ...[
              const SizedBox(height: Espaco.e8),
              Text('As regras eram', style: texto.headlineSmall),
              const SizedBox(height: Espaco.e3),
              for (final (i, regra) in estado.regrasReveladas.indexed) ...[
                if (i > 0) const SizedBox(height: Espaco.e2),
                FatoDoFim(
                  poco: _PocoDoAnel(luz: c.luzDoAnel(regra.anel)),
                  texto: comDestaque(context, '${regra.nome}: ', regra.texto),
                ),
              ],
            ],
            const SizedBox(height: Espaco.e8),
            Text('O tabuleiro', style: texto.headlineSmall),
            const SizedBox(height: Espaco.e1),
            Text(
              'Toque numa região para ver as cartas.',
              style: texto.bodyMedium?.copyWith(color: c.texto2),
            ),
            const SizedBox(height: Espaco.e3),
            SizedBox(
              height: 360,
              child: TabuleiroAneis(
                cartas: estado.tabuleiro,
                aoVerRegiao: (regiao) => mostrarCartasDaRegiao(
                  context,
                  regiao: regiao,
                  cartas: estado.tabuleiro,
                  aneis: estado.aneis,
                  regraSecreta: estado.regrasReveladas
                      .where((r) => r.anel == regiao.id)
                      .firstOrNull,
                ),
              ),
            ),
          ],
        ),
        rodape: RodapeDoFimOnline(sala: provider, matiz: Matiz.ceu),
      ),
    );
  }
}

/// Poço com um anel desenhado, na luz da regra.
class _PocoDoAnel extends StatelessWidget {
  const _PocoDoAnel({required this.luz});

  final Luz luz;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: luz.suave,
        borderRadius: BorderRadius.circular(Raio.sm),
      ),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: luz.cor.withValues(alpha: .2),
          border: Border.all(color: c.ehDia ? luz.tinta : luz.cor, width: 3),
        ),
      ),
    );
  }
}
