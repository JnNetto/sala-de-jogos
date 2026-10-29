import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/jogo_disponivel.dart';
import '../../../core/theme/sala_tokens.dart';
import 'pressionavel.dart';

/// O card de um jogo na home, em dois formatos:
/// - [CartaoJogo.destaque]: uma janela de sistema com barra em pixel, para o
///   jogo que acabou de chegar;
/// - [CartaoJogo.ladrilho]: o card enxuto da grade, como etiqueta de cartucho.
///
/// Os dois acendem a cor do jogo e crescem até virar a home dele
/// (container transform).
class CartaoJogo extends StatefulWidget {
  const CartaoJogo.destaque({
    super.key,
    required this.jogo,
    required this.telaDoJogo,
    this.aoIndisponivel,
  }) : destaque = true;

  const CartaoJogo.ladrilho({
    super.key,
    required this.jogo,
    required this.telaDoJogo,
    this.aoIndisponivel,
  }) : destaque = false;

  final JogoDisponivel jogo;
  final WidgetBuilder telaDoJogo;
  final bool destaque;

  /// Toque num jogo indisponível: o card treme e o chamador mostra um aviso.
  final VoidCallback? aoIndisponivel;

  @override
  State<CartaoJogo> createState() => _CartaoJogoState();
}

class _CartaoJogoState extends State<CartaoJogo> with TickerProviderStateMixin {
  bool _pressionado = false;

  /// Enquanto o container transform roda, a sombra externa some para não
  /// deixar um "fantasma" no lugar do card.
  bool _aberto = false;
  VoidCallback? _abrir;

  late final _balanco = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final _tremida = AnimationController(
    vsync: this,
    duration: Movimento.media,
  );

  static final _rotacao = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 30),
    TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 35),
  ]).chain(CurveTween(curve: Movimento.padrao));

  @override
  void dispose() {
    _balanco.dispose();
    _tremida.dispose();
    super.dispose();
  }

  void _aoMudar(bool baixo) {
    setState(() => _pressionado = baixo);
    if (baixo && !Movimento.reduzido(context)) _balanco.forward(from: 0);
  }

  void _tocar() {
    if (widget.jogo.disponivel) {
      setState(() => _aberto = true);
      _abrir?.call();
      return;
    }
    HapticFeedback.mediumImpact();
    if (!Movimento.reduzido(context)) _tremida.forward(from: 0);
    widget.aoIndisponivel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final jogo = widget.jogo;
    final raio = BorderRadius.circular(Raio.xl);

    final cartao = Pressionavel(
      onTap: _tocar,
      aoMudar: _aoMudar,
      escala: widget.destaque ? .98 : .97,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: raio,
          boxShadow: _aberto ? null : c.sombraCard,
        ),
        child: OpenContainer(
          tappable: false,
          transitionDuration: Movimento.d(context, Movimento.lenta),
          transitionType: ContainerTransitionType.fadeThrough,
          closedElevation: 0,
          openElevation: 0,
          closedColor: c.superficie,
          openColor: Colors.transparent,
          middleColor: c.superficie,
          closedShape: RoundedRectangleBorder(borderRadius: raio),
          onClosed: (_) {
            if (mounted) setState(() => _aberto = false);
          },
          openBuilder: (ctx, _) => widget.telaDoJogo(ctx),
          closedBuilder: (ctx, abrir) {
            _abrir = abrir;
            return AnimatedContainer(
              duration: _pressionado ? Movimento.instante : Movimento.rapida,
              curve: Movimento.padrao,
              decoration: BoxDecoration(
                color: _pressionado ? c.superficieElevada : c.superficie,
                borderRadius: raio,
                border: Border.all(
                  color: c.ehDia ? c.contorno : c.linha,
                  width: c.bordaControle,
                ),
              ),
              child: widget.destaque
                  ? _janela(context, c)
                  : _ladrilho(context, c),
            );
          },
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: jogo.disponivel,
      label:
          '${jogo.nome}. ${jogo.descricao} '
          'De ${jogo.minJogadores} a ${jogo.maxJogadores} jogadores, '
          '${jogo.duracaoMinutos} minutos.'
          '${jogo.novo ? ' Novo.' : ''}'
          '${jogo.disponivel ? '' : ' Em breve.'}',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _tremida,
        builder: (_, filho) => Transform.translate(
          offset: Offset(4 * math.sin(_tremida.value * math.pi * 4), 0),
          child: filho,
        ),
        child: Opacity(
          opacity: jogo.disponivel ? 1 : Opacidade.desabilitado,
          child: cartao,
        ),
      ),
    );
  }

  /// "4–12 · 10 MIN": a etiqueta do cartucho, em pixel.
  Widget _etiqueta(
    BuildContext context,
    SalaCores c,
    Luz luz, {
    bool longa = false,
  }) {
    final jogo = widget.jogo;
    final estilo = Theme.of(context).textTheme.labelSmall;
    final jogadores = '${jogo.minJogadores}–${jogo.maxJogadores}';
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: longa ? '$jogadores JOGADORES' : jogadores,
            style: TextStyle(color: luz.tinta),
          ),
          TextSpan(text: '  ·  ${jogo.duracaoMinutos} MIN'),
          if (!jogo.disponivel) const TextSpan(text: '  ·  EM BREVE'),
        ],
      ),
      style: estilo?.copyWith(color: c.texto3),
    );
  }

  Widget _janela(BuildContext context, SalaCores c) {
    final jogo = widget.jogo;
    final luz = c.luz(jogo.matiz);
    final texto = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra de título da janela, com as três luzinhas.
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: Espaco.e4),
          decoration: BoxDecoration(
            color: c.janelaBarra,
            border: c.ehDia
                ? Border(bottom: BorderSide(color: c.contorno, width: 2))
                : null,
          ),
          child: Row(
            children: [
              for (final m in const [Matiz.lampada, Matiz.rosa, Matiz.menta])
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: Espaco.e1),
                  decoration: BoxDecoration(
                    color: c.luz(m).cor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: Espaco.e2),
              Text(
                'NOVO NA SALA',
                style: texto.labelMedium?.copyWith(color: c.janelaBarraTexto),
              ),
            ],
          ),
        ),
        // Corpo, com a luz do jogo vazando por trás do poço.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-.75, -.2),
              radius: 1.1,
              colors: [
                luz.cor.withValues(alpha: c.ehDia ? .10 : .18),
                luz.cor.withValues(alpha: 0),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Espaco.e5,
              Espaco.e5,
              Espaco.e5,
              Espaco.e4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _poco(c, luz, lado: 72, icone: 40),
                    const SizedBox(width: Espaco.e4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(jogo.nome, style: texto.headlineMedium),
                          const SizedBox(height: Espaco.e1),
                          Text(
                            jogo.descricao,
                            style: texto.bodyMedium?.copyWith(color: c.texto2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Espaco.e4),
                Row(
                  children: [
                    Expanded(child: _etiqueta(context, c, luz, longa: true)),
                    _chamada(context, c, luz),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// "Jogar" desenhado como tecla, só visual: o card inteiro é o alvo.
  Widget _chamada(BuildContext context, SalaCores c, Luz luz) {
    return AnimatedContainer(
      duration: _pressionado ? Movimento.instante : Movimento.rapida,
      curve: _pressionado ? Movimento.padrao : Movimento.pulo,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: Espaco.e4),
      transform: Matrix4.translationValues(0, _pressionado ? 2 : 0, 0),
      decoration: BoxDecoration(
        color: luz.cor,
        borderRadius: BorderRadius.circular(Raio.md),
        border: c.ehDia ? Border.all(color: c.contorno, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: c.ehDia
                ? c.contorno
                : Color.lerp(luz.cor, const Color(0xFF05061A), .38)!,
            offset: Offset(0, _pressionado ? 1 : 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'Jogar',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: c.sobreCor),
      ),
    );
  }

  Widget _ladrilho(BuildContext context, SalaCores c) {
    final jogo = widget.jogo;
    final luz = c.luz(jogo.matiz);
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(Espaco.e4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _poco(c, luz, lado: 48, icone: 26),
          const SizedBox(height: Espaco.e3),
          Text(jogo.nome, style: texto.titleMedium),
          const SizedBox(height: 2),
          Text(
            jogo.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: texto.bodySmall?.copyWith(color: c.texto2),
          ),
          const Spacer(),
          const SizedBox(height: Espaco.e3),
          _etiqueta(context, c, luz),
        ],
      ),
    );
  }

  Widget _poco(
    SalaCores c,
    Luz luz, {
    required double lado,
    required double icone,
  }) {
    final raio = lado >= 64 ? Raio.lg : Raio.md;
    return AnimatedContainer(
      duration: Movimento.base,
      curve: Movimento.padrao,
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        color: luz.suave,
        borderRadius: BorderRadius.circular(raio),
        border: c.ehDia ? Border.all(color: c.contorno, width: 2) : null,
        boxShadow: c.brilho(
          luz.cor,
          alpha: _pressionado ? .55 : .32,
          blur: lado * (_pressionado ? .5 : .4),
        ),
      ),
      child: CustomPaint(
        painter: _LinhasCrt(luz.cor.withValues(alpha: .10), raio),
        child: Center(
          child: AnimatedBuilder(
            animation: _balanco,
            builder: (_, filho) => Transform.rotate(
              angle: _rotacao.evaluate(_balanco) * math.pi / 180,
              child: filho,
            ),
            child: Icon(widget.jogo.icone, size: icone, color: luz.tinta),
          ),
        ),
      ),
    );
  }
}

/// Linhas de tela antiga: 1 px de cor a cada 4 px.
class _LinhasCrt extends CustomPainter {
  _LinhasCrt(this.cor, this.raio);

  final Color cor;
  final double raio;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(raio)),
    );
    final p = Paint()..color = cor;
    for (var y = 3.0; y < s.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, s.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(_LinhasCrt o) => o.cor != cor || o.raio != raio;
}
