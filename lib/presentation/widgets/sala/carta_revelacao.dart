import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import 'jogador_sala.dart';

/// Monta a frente da carta. [esconder] vira a carta de volta e só então
/// avisa a tela; [efeito] corre de 0 a 1 logo depois da virada, para as
/// faíscas do civil.
typedef FrenteDaCarta =
    Widget Function(VoidCallback esconder, Animation<double> efeito);

/// A carta de revelação de papel. O jogador segura o botão por 600 ms (o
/// anel enche; soltar antes desfaz), a carta vira e mostra a frente.
/// Segurar exige intenção: um toque sem querer não revela nada para quem
/// está do lado.
class CartaRevelacao extends StatefulWidget {
  const CartaRevelacao({
    super.key,
    required this.nome,
    required this.indice,
    required this.total,
    required this.espiao,
    required this.frente,
    required this.aoEsconder,
    this.aoMudarFace,
  });

  final String nome;

  /// Posição do jogador na mesa (0 é o primeiro).
  final int indice;
  final int total;

  /// Muda o háptico da virada e o efeito da frente.
  final bool espiao;
  final FrenteDaCarta frente;

  /// A carta já voltou para o verso: a tela pode passar para o próximo.
  final VoidCallback aoEsconder;

  /// `true` quando a frente termina de aparecer; `false` ao começar a
  /// esconder.
  final ValueChanged<bool>? aoMudarFace;

  @override
  State<CartaRevelacao> createState() => _CartaRevelacaoState();
}

class _CartaRevelacaoState extends State<CartaRevelacao>
    with TickerProviderStateMixin {
  late final AnimationController _segurar;
  late final AnimationController _virar;
  late final AnimationController _efeito;
  bool _hapticoDoMeio = false;

  @override
  void initState() {
    super.initState();
    _segurar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener(_aoSegurar);
    _virar = AnimationController(vsync: this, duration: Movimento.dramatica)
      ..addListener(_meioDaVirada);
    _efeito = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _segurar.dispose();
    _virar.dispose();
    _efeito.dispose();
    super.dispose();
  }

  bool get _revelada => _virar.value > .5;

  void _comecar() {
    if (_virar.value > 0) return;
    HapticFeedback.lightImpact();
    _segurar.forward();
  }

  void _soltar() {
    if (_segurar.isCompleted || _virar.value > 0) return;
    _segurar.animateBack(0, duration: Movimento.base, curve: Movimento.padrao);
  }

  void _aoSegurar(AnimationStatus status) {
    if (status == AnimationStatus.completed) _revelar();
  }

  Future<void> _revelar() async {
    _hapticoDoMeio = false;
    final reduzido = Movimento.reduzido(context);
    if (reduzido) {
      // Sem virada: troca de face com fade.
      widget.espiao
          ? HapticFeedback.heavyImpact()
          : HapticFeedback.mediumImpact();
      await _virar.animateTo(1, duration: const Duration(milliseconds: 120));
    } else {
      await _virar.animateTo(1, curve: Movimento.padrao);
      if (mounted) _efeito.forward(from: 0);
    }
    if (mounted) widget.aoMudarFace?.call(true);
  }

  void _meioDaVirada() {
    if (_hapticoDoMeio ||
        _virar.status != AnimationStatus.forward ||
        _virar.value < .5) {
      return;
    }
    _hapticoDoMeio = true;
    widget.espiao
        ? HapticFeedback.heavyImpact()
        : HapticFeedback.mediumImpact();
  }

  Future<void> _esconder() async {
    widget.aoMudarFace?.call(false);
    _efeito.stop();
    await _virar.animateBack(
      0,
      duration: Movimento.d(context, Movimento.media),
      curve: Movimento.padrao,
    );
    _segurar.value = 0;
    if (mounted) widget.aoEsconder();
  }

  @override
  Widget build(BuildContext context) {
    final reduzido = Movimento.reduzido(context);
    return LayoutBuilder(
      builder: (context, limites) {
        final largura = math.min(300.0, limites.maxWidth * .8);
        final altura = math.min(largura * 4 / 3, limites.maxHeight);
        return SizedBox(
          width: largura,
          height: altura,
          child: AnimatedBuilder(
            animation: Listenable.merge([_virar, _efeito]),
            builder: (context, _) {
              final t = _virar.value;
              if (reduzido) {
                return Stack(
                  children: [
                    Opacity(opacity: 1 - t, child: _verso(context)),
                    if (t > 0) Opacity(opacity: t, child: _frente(context)),
                  ],
                );
              }
              final angulo = t * math.pi;
              final mostrandoFrente = angulo > math.pi / 2;
              // Espião: um glitch rápido logo depois da virada.
              final glitch = widget.espiao && _efeito.value > 0
                  ? 3 *
                        math.sin(_efeito.value * math.pi * 4) *
                        (1 - _efeito.value)
                  : 0.0;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, .0012)
                  ..rotateY(angulo),
                child: mostrandoFrente
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: Transform.translate(
                          offset: Offset(glitch, 0),
                          child: _frente(context),
                        ),
                      )
                    : _verso(context),
              );
            },
          ),
        );
      },
    );
  }

  BoxDecoration _cartao(SalaCores c, {Gradient? brilho}) => BoxDecoration(
    color: c.superficie,
    gradient: brilho,
    borderRadius: BorderRadius.circular(Raio.xxl),
    border: Border.all(
      color: c.ehDia ? c.contorno : c.linha,
      width: c.bordaControle,
    ),
    boxShadow: c.sombraFlutuante,
  );

  Widget _verso(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return Container(
      decoration: _cartao(
        c,
        brilho: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.superficie, Color.lerp(c.superficie, c.ceuBrilho, .7)!],
        ),
      ),
      padding: const EdgeInsets.all(Espaco.e5),
      child: _CabeNaCarta(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarJogador(
              nome: widget.nome,
              indice: widget.indice,
              tamanho: 64,
            ),
            const SizedBox(height: Espaco.e4),
            Text(
              'JOGADOR ${widget.indice + 1} DE ${widget.total}',
              style: texto.labelSmall?.copyWith(color: c.texto3),
            ),
            const SizedBox(height: Espaco.e2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(widget.nome, maxLines: 1, style: texto.displayMedium),
            ),
            const SizedBox(height: Espaco.e3),
            Text(
              'Só você olhando? Segure o botão.',
              textAlign: TextAlign.center,
              style: texto.bodyMedium?.copyWith(color: c.texto2),
            ),
            const SizedBox(height: Espaco.e6),
            _BotaoSegurar(
              progresso: _segurar,
              aoComecar: _comecar,
              aoSoltar: _soltar,
              aoRevelarDireto: _revelar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _frente(BuildContext context) {
    final c = context.cores;
    final luz = widget.espiao ? c.papelEspiao : c.papelCivil;
    return Semantics(
      liveRegion: _revelada,
      child: Container(
        decoration: _cartao(
          c,
          brilho: RadialGradient(
            center: const Alignment(0, -.35),
            radius: .9,
            colors: [
              Color.lerp(c.superficie, luz.cor, c.ehDia ? .10 : .16)!,
              c.superficie,
            ],
          ),
        ),
        padding: const EdgeInsets.all(Espaco.e5),
        child: _CabeNaCarta(child: widget.frente(_esconder, _efeito)),
      ),
    );
  }
}

/// Centraliza a face na carta e, se não couber (fonte grande do sistema,
/// palavra longa), encolhe tudo junto em vez de estourar.
class _CabeNaCarta extends StatelessWidget {
  const _CabeNaCarta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limites) => Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(width: limites.maxWidth, child: child),
      ),
    ),
  );
}

class _BotaoSegurar extends StatelessWidget {
  const _BotaoSegurar({
    required this.progresso,
    required this.aoComecar,
    required this.aoSoltar,
    required this.aoRevelarDireto,
  });

  final Animation<double> progresso;
  final VoidCallback aoComecar, aoSoltar, aoRevelarDireto;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final cor = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: 'Segure para revelar seu papel',
      // O toque duplo longo do TalkBack chega como long press.
      onLongPress: aoRevelarDireto,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => aoComecar(),
        onPointerUp: (_) => aoSoltar(),
        onPointerCancel: (_) => aoSoltar(),
        child: AnimatedBuilder(
          animation: progresso,
          builder: (_, _) => SizedBox(
            width: 112,
            height: 112,
            child: CustomPaint(
              painter: _Anel(
                progresso: progresso.value,
                trilho: c.superficieFunda,
                cor: cor,
              ),
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(c.superficieElevada, cor, .14),
                    boxShadow: c.brilho(
                      cor,
                      alpha: .15 + .35 * progresso.value,
                      blur: 24,
                    ),
                  ),
                  child: Transform.scale(
                    scale: 1 - .12 * progresso.value,
                    child: Icon(
                      Symbols.fingerprint_rounded,
                      size: 44,
                      color: cor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Anel extends CustomPainter {
  _Anel({required this.progresso, required this.trilho, required this.cor});

  final double progresso;
  final Color trilho, cor;

  @override
  void paint(Canvas canvas, Size s) {
    const traco = 6.0;
    final r = Rect.fromLTWH(
      traco / 2,
      traco / 2,
      s.width - traco,
      s.height - traco,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = traco
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = trilho);
    if (progresso > 0) {
      canvas.drawArc(
        r,
        -math.pi / 2,
        math.pi * 2 * progresso,
        false,
        p..color = cor,
      );
    }
  }

  @override
  bool shouldRepaint(_Anel o) =>
      o.progresso != progresso || o.cor != cor || o.trilho != trilho;
}

/// Oito estrelas pixel saindo do centro e sumindo: o "acerto" do civil.
class Faiscas extends StatelessWidget {
  const Faiscas({super.key, required this.efeito, required this.child});

  final Animation<double> efeito;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final cores = [
      c.luz(Matiz.lampada).cor,
      c.luz(Matiz.rosa).cor,
      c.luz(Matiz.menta).cor,
      c.luz(Matiz.ceu).cor,
    ];
    return CustomPaint(
      foregroundPainter: _Faiscas(efeito, cores),
      child: child,
    );
  }
}

class _Faiscas extends CustomPainter {
  _Faiscas(this.efeito, this.cores) : super(repaint: efeito);

  final Animation<double> efeito;
  final List<Color> cores;

  @override
  void paint(Canvas canvas, Size s) {
    final t = efeito.value;
    if (t == 0 || t == 1) return;
    final centro = s.center(Offset.zero);
    final p = Paint();
    final ida = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 8; i++) {
      final angulo = i * math.pi / 4 + math.pi / 8;
      final distancia = s.shortestSide * (.35 + .45 * ida);
      final o = centro + Offset(math.cos(angulo), math.sin(angulo)) * distancia;
      p.color = cores[i % cores.length].withValues(alpha: 1 - t);
      // Cruz pixel 9 × 9.
      canvas.drawRect(Rect.fromLTWH(o.dx - 1.5, o.dy - 4.5, 3, 9), p);
      canvas.drawRect(Rect.fromLTWH(o.dx - 4.5, o.dy - 1.5, 9, 3), p);
    }
  }

  @override
  bool shouldRepaint(_Faiscas o) => false;
}
