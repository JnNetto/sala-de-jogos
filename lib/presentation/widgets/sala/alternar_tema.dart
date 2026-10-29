import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../providers/theme_provider.dart';
import 'pressionavel.dart';
import 'troca_de_tema.dart';

/// Pílula 76 × 40 com um céu dentro: lua à esquerda no Noite, sol à direita
/// no Dia. O app troca junto, com o círculo de [TrocaDeTema] saindo daqui.
class AlternarTema extends StatelessWidget {
  const AlternarTema({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<ThemeProvider>();
    final noite = tema.isDarkMode;
    final c = context.cores;
    final dur = Movimento.d(context, Movimento.media);

    return Semantics(
      button: true,
      label: noite ? 'Trocar para tema Dia' : 'Trocar para tema Noite',
      excludeSemantics: true,
      child: Pressionavel(
        haptico: false,
        onTap: () {
          HapticFeedback.selectionClick();
          final caixa = context.findRenderObject() as RenderBox?;
          TrocaDeTema.alternar(
            context,
            origem: caixa?.localToGlobal(caixa.size.center(Offset.zero)),
          );
        },
        child: SizedBox(
          width: 76,
          height: Espaco.alvoToque,
          child: Center(
            child: Container(
              width: 76,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.superficieFunda,
                borderRadius: BorderRadius.circular(Raio.pill),
                border: Border.all(
                  color: c.ehDia ? c.contorno : c.linhaForte,
                  width: c.bordaControle,
                ),
              ),
              child: Stack(
                children: [
                  AnimatedOpacity(
                    opacity: noite ? 1 : 0,
                    duration: dur,
                    curve: Movimento.padrao,
                    child: Stack(
                      children: [
                        _estrela(c, 44, 10, 3),
                        _estrela(c, 58, 22, 3),
                        _estrela(c, 50, 28, 2),
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: dur,
                    curve: Movimento.pulo,
                    // A borda já ocupa parte dos 4 px de folga.
                    left: noite ? 4 - c.bordaControle : 40 - c.bordaControle,
                    top: 4 - c.bordaControle,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: noite
                            ? c.superficieElevada
                            : c.luz(Matiz.lampada).cor,
                        border: c.ehDia
                            ? Border.all(color: c.contorno, width: 2)
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _astro(
                            Symbols.dark_mode_rounded,
                            visivel: noite,
                            cor: c.luz(Matiz.lampada).tinta,
                            dur: dur,
                          ),
                          _astro(
                            Symbols.light_mode_rounded,
                            visivel: !noite,
                            cor: c.sobreCor,
                            dur: dur,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _estrela(SalaCores c, double x, double y, double lado) => Positioned(
    left: x - c.bordaControle,
    top: y - c.bordaControle,
    child: Container(width: lado, height: lado, color: c.estrela),
  );

  Widget _astro(
    IconData icone, {
    required bool visivel,
    required Color cor,
    required Duration dur,
  }) {
    return AnimatedRotation(
      turns: visivel ? 0 : .25,
      duration: dur,
      curve: Movimento.pulo,
      child: AnimatedScale(
        scale: visivel ? 1 : .5,
        duration: dur,
        curve: Movimento.pulo,
        child: AnimatedOpacity(
          opacity: visivel ? 1 : 0,
          duration: Movimento.base,
          curve: Movimento.padrao,
          child: Icon(icone, size: 20, fill: 1, color: cor),
        ),
      ),
    );
  }
}
