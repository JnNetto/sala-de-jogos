import 'package:flutter/material.dart';

import '../../../core/theme/sala_tokens.dart';
import 'pressionavel.dart';

enum VarianteBotao {
  /// A ação da tela fora de um jogo; com [BotaoSala.luz], a ação de um jogo.
  primario,

  /// Ação de apoio, abaixo ou ao lado da principal.
  secundario,

  /// Ação terciária, link, "Cancelar".
  fantasma,

  /// Confirmação destrutiva.
  perigo,
}

/// O botão chunky com lábio. O lábio "cai" de graça: o [Pressionavel]
/// desce 3 px e a sombra fica parada, então o lábio visível encolhe.
class BotaoSala extends StatelessWidget {
  const BotaoSala({
    super.key,
    required this.rotulo,
    this.onPressed,
    this.icone,
    this.luz,
    this.variante = VarianteBotao.primario,
    this.bloco = false,
    this.carregando = false,
    this.iconeNoFim = false,
  });

  final String rotulo;
  final VoidCallback? onPressed;
  final IconData? icone;

  /// Luz do jogo; `null` usa a primária (âmbar). No fantasma, tinge o texto.
  final Luz? luz;
  final VarianteBotao variante;
  final bool bloco, carregando;

  /// O ícone depois do texto, para "Continuar →".
  final bool iconeNoFim;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final desabilitado = onPressed == null;
    final ativo = !desabilitado && !carregando;

    final cheio =
        variante == VarianteBotao.primario || variante == VarianteBotao.perigo;
    final corCheia = variante == VarianteBotao.perigo
        ? c.erro.cor
        : (luz?.cor ?? c.primaria);

    final Color fundo;
    final Color tinta;
    final Color? labio;
    if (desabilitado) {
      fundo = c.ehDia ? c.superficieFunda : c.superficieElevada;
      tinta = c.texto3;
      labio = null;
    } else {
      switch (variante) {
        case VarianteBotao.primario || VarianteBotao.perigo:
          fundo = corCheia;
          tinta = c.sobreCor;
          labio = c.ehDia
              ? c.contorno
              : (luz == null && variante == VarianteBotao.primario
                    ? c.primariaLabio
                    : Color.lerp(corCheia, const Color(0xFF05061A), .38)!);
        case VarianteBotao.secundario:
          fundo = c.superficie;
          tinta = c.texto;
          labio = c.ehDia ? c.contorno : c.linha;
        case VarianteBotao.fantasma:
          fundo = Colors.transparent;
          tinta = luz?.tinta ?? c.primariaTinta;
          labio = null;
      }
    }

    final Border? borda;
    if (variante == VarianteBotao.fantasma && !desabilitado) {
      borda = null;
    } else if (desabilitado) {
      borda = Border.all(color: c.linha, width: c.bordaControle);
    } else if (c.ehDia) {
      borda = Border.all(color: c.contorno, width: 2);
    } else if (variante == VarianteBotao.secundario) {
      borda = Border.all(color: c.linhaForte, width: 1.5);
    } else {
      borda = null;
    }

    return Semantics(
      button: true,
      enabled: !desabilitado,
      label: carregando ? '$rotulo, carregando' : null,
      child: Pressionavel(
        onTap: ativo ? onPressed : null,
        escala: .985,
        descida: variante == VarianteBotao.fantasma ? 0 : 3,
        child: Container(
          height: 56,
          width: bloco ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: variante == VarianteBotao.fantasma
                ? Espaco.e4
                : Espaco.e6,
          ),
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: BorderRadius.circular(Raio.lg),
            border: borda,
            boxShadow: labio == null
                ? null
                : [
                    BoxShadow(color: labio, offset: const Offset(0, 4)),
                    if (cheio && !c.ehDia)
                      BoxShadow(
                        color: fundo.withValues(alpha: .28),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Reflexo de lâmpada no topo dos botões cheios.
              if (cheio && !desabilitado)
                Positioned(
                  left: 14 - Espaco.e6,
                  right: 14 - Espaco.e6,
                  top: c.ehDia ? 3 : 5,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .28),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              Row(
                mainAxisSize: bloco ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: carregando
                    ? [BolinhasCarregando(cor: tinta)]
                    : [
                        if (icone != null && !iconeNoFim) ...[
                          Icon(icone, size: 22, color: tinta),
                          const SizedBox(width: Espaco.e2),
                        ],
                        Flexible(
                          child: Text(
                            rotulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(color: tinta),
                          ),
                        ),
                        if (icone != null && iconeNoFim) ...[
                          const SizedBox(width: Espaco.e2),
                          Icon(icone, size: 22, color: tinta),
                        ],
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão quadrado 48 × 48 para navegação e barra: voltar, fechar, abortar.
/// Sem texto visível, então [rotulo] é obrigatório (tooltip e leitor de tela).
class BotaoIcone extends StatelessWidget {
  const BotaoIcone({
    super.key,
    required this.icone,
    required this.rotulo,
    this.onPressed,
    this.perigo = false,
  });

  final IconData icone;
  final String rotulo;
  final VoidCallback? onPressed;
  final bool perigo;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Tooltip(
      message: rotulo,
      child: Semantics(
        button: true,
        label: rotulo,
        excludeSemantics: true,
        child: Pressionavel(
          onTap: onPressed,
          escala: .9,
          child: Container(
            width: Espaco.alvoToque,
            height: Espaco.alvoToque,
            decoration: BoxDecoration(
              color: c.superficie,
              borderRadius: BorderRadius.circular(Raio.md),
              border: Border.all(
                color: c.ehDia ? c.contorno : c.linha,
                width: c.bordaControle,
              ),
              boxShadow: c.ehDia
                  ? [BoxShadow(color: c.contorno, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Icon(
              icone,
              size: 24,
              color: perigo ? c.erro.tinta : c.texto,
            ),
          ),
        ),
      ),
    );
  }
}

/// Três bolinhas que acendem em sequência (ciclo de 900 ms).
class BolinhasCarregando extends StatefulWidget {
  const BolinhasCarregando({super.key, required this.cor});

  final Color cor;

  @override
  State<BolinhasCarregando> createState() => _BolinhasState();
}

class _BolinhasState extends State<BolinhasCarregando>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _aceso(int i) {
    final f = (_c.value - i * .166) % 1.0;
    return f < .35
        ? Curves.easeOut.transform(f / .35)
        : 1 - Curves.easeIn.transform(((f - .35) / .65).clamp(0, 1));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.cor.withValues(alpha: .25 + .75 * _aceso(i)),
            ),
          ),
      ],
    ),
  );
}
