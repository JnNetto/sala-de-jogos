import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/sala_tokens.dart';
import 'relogio_ambiente.dart';
import 'vento.dart';

/// A ordem das cores no varal decorativo.
const _roda = [
  Matiz.lampada,
  Matiz.rosa,
  Matiz.menta,
  Matiz.violeta,
  Matiz.brasa,
  Matiz.luar,
  Matiz.ceu,
];

/// Na splash, o varal acende devagar da esquerda para a direita: cada
/// lâmpada esquenta até a cor cheia em vez de estalar.
const _atrasoSequencia = Duration(milliseconds: 250);
const _passoSequencia = Duration(milliseconds: 120);
const _esquentar = Duration(milliseconds: 600);

/// O varal de luzes, assinatura do app. Três modos:
/// - [Varal.decorativo]: todas acesas, cintilando (home e splash);
/// - [Varal.progresso]: uma lâmpada por jogador, acende quando ele termina;
/// - [Varal.carregando]: duas lâmpadas acesas correm pelo fio.
class Varal extends StatefulWidget {
  /// Com [acenderEmSequencia], as lâmpadas acendem uma a uma ao aparecer.
  /// Com [vento], as lâmpadas balançam quando passa uma rajada.
  const Varal.decorativo({
    super.key,
    this.acenderEmSequencia = false,
    this.vento,
  }) : cores = null,
       acesas = null,
       carregando = false,
       barriga = 12;

  const Varal.progresso({
    super.key,
    required List<Color> this.cores,
    required int this.acesas,
    this.vento,
  }) : carregando = false,
       acenderEmSequencia = false,
       barriga = 8;

  const Varal.carregando({super.key})
    : cores = null,
      acesas = null,
      carregando = true,
      acenderEmSequencia = false,
      vento = null,
      barriga = 6;

  final List<Color>? cores;
  final int? acesas;
  final bool carregando, acenderEmSequencia;
  final double barriga;
  final Vento? vento;

  static const altura = 44.0;

  /// Quantas lâmpadas cabem no varal decorativo nessa largura.
  static int lampadasPara(double largura) =>
      math.max(8, (largura / 28).round());

  /// Quanto a sequência de acender leva para terminar com [n] lâmpadas.
  static Duration duracaoSequencia(int n) =>
      _atrasoSequencia + _passoSequencia * (n - 1) + _esquentar;

  @override
  State<Varal> createState() => _VaralState();
}

class _VaralState extends State<Varal> with SingleTickerProviderStateMixin {
  late final _relogio = RelogioAmbiente(this);

  /// Quando cada lâmpada acendeu, para o pulo de acender.
  final _acendeuEm = <int, Duration>{};

  @override
  void initState() {
    super.initState();
    if (widget.acenderEmSequencia) {
      // 14 lâmpadas é o máximo de um celular em pé; sobra não custa nada.
      _relogio.fluidoAte = Varal.duracaoSequencia(16);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _relogio.ligado = !Movimento.reduzido(context);
  }

  @override
  void didUpdateWidget(Varal antigo) {
    super.didUpdateWidget(antigo);
    final antes = antigo.acesas ?? 0, agora = widget.acesas ?? 0;
    if (agora > antes) {
      for (var i = antes; i < agora; i++) {
        _acendeuEm[i] = _relogio.agora;
      }
      _relogio.fluidoAte = _relogio.agora + Movimento.media;
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _relogio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final reduzido = Movimento.reduzido(context);
    final varal = RepaintBoundary(
      child: SizedBox(
        height: Varal.altura,
        width: double.infinity,
        child: CustomPaint(
          painter: _VaralPintor(
            c: c,
            cores: widget.cores,
            acesas: widget.acesas,
            carregando: widget.carregando,
            sequencia: widget.acenderEmSequencia && !reduzido,
            barriga: widget.barriga,
            relogio: _relogio,
            acendeuEm: _acendeuEm,
            parado: reduzido,
            vento: widget.vento,
          ),
        ),
      ),
    );

    if (widget.carregando) {
      return Semantics(
        label: 'Carregando',
        child: reduzido
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  varal,
                  Text(
                    'CARREGANDO',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: c.texto3),
                  ),
                ],
              )
            : varal,
      );
    }
    return ExcludeSemantics(child: varal);
  }
}

class _VaralPintor extends CustomPainter {
  _VaralPintor({
    required this.c,
    required this.cores,
    required this.acesas,
    required this.carregando,
    required this.sequencia,
    required this.barriga,
    required this.relogio,
    required this.acendeuEm,
    required this.parado,
    this.vento,
  }) : super(repaint: Listenable.merge([relogio, ?vento]));

  final SalaCores c;
  final List<Color>? cores;
  final int? acesas;
  final bool carregando, sequencia, parado;
  final double barriga;
  final RelogioAmbiente relogio;
  final Map<int, Duration> acendeuEm;
  final Vento? vento;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final agora = relogio.value;
    final n = cores?.length ?? (carregando ? 5 : Varal.lampadasPara(w));

    final fio = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = c.ehDia ? c.contorno : c.linhaForte;
    // A rajada empurra o meio do fio um pouco para o lado e para cima.
    final sopro = vento?.empurrao(.5) ?? 0;
    final cx = w / 2 + 2.5 * sopro, cy = 6 + barriga * 2 - .8 * sopro;
    canvas.drawPath(
      Path()
        ..moveTo(0, 6)
        ..quadraticBezierTo(cx, cy, w, 6),
      fio,
    );

    final soquete = Paint()..color = c.ehDia ? c.contorno : c.linhaForte;
    final bulbo = Paint();
    final borda = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final halo = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // No carregando, duas lâmpadas acesas andam uma casa a cada 160 ms.
    final passo = agora.inMilliseconds ~/ 160;
    final ciclo = agora.inMilliseconds / Movimento.ambiente.inMilliseconds;

    for (var i = 0; i < n; i++) {
      final t = (i + .5) / n;
      final x = 2 * (1 - t) * t * cx + t * t * w;
      final y = math.pow(1 - t, 2) * 6 + 2 * (1 - t) * t * cy + t * t * 6;

      final cor =
          cores?[i] ??
          (carregando
              ? c.luz(Matiz.lampada).cor
              : c.luz(_roda[i % _roda.length]).cor);
      final acendeu = sequencia
          ? _atrasoSequencia + _passoSequencia * i
          : acendeuEm[i];
      // Quanto a lâmpada já esquentou, de 0 a 1. Fora da sequência é seco.
      final brilho = sequencia
          ? Movimento.padrao.transform(
              ((agora - acendeu!).inMicroseconds / _esquentar.inMicroseconds)
                  .clamp(0.0, 1.0),
            )
          : 1.0;
      final acesa = carregando
          ? (parado || i == passo % n || i == (passo - 1) % n)
          : sequencia
          ? brilho > 0
          : (acesas == null || i < acesas!);

      // A lâmpada inteira balança presa ao fio, girando no soquete.
      final angulo = vento?.angulo(x / w, i) ?? 0;
      canvas.save();
      if (angulo != 0) {
        canvas
          ..translate(x, y)
          ..rotate(angulo)
          ..translate(-x, -y);
      }

      // Halo: só no Noite. Cintila entre 25% e 60% com fase por lâmpada.
      if (acesa && !c.ehDia) {
        var alpha = .45;
        if (!parado && acesas == null && !carregando) {
          final fase = (i * 370 % 1900) / Movimento.ambiente.inMilliseconds;
          alpha =
              .25 + .35 * (.5 - .5 * math.cos(2 * math.pi * (ciclo + fase)));
        }
        halo.color = cor.withValues(alpha: alpha * brilho);
        canvas.drawCircle(Offset(x, y + 12), 10, halo);
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 3, y - 1, 6, 5),
          const Radius.circular(1.5),
        ),
        soquete,
      );

      // Pulo de acender: cresce e volta, preso pelo soquete. Na sequência
      // é só um respiro, que acompanha o esquentar.
      var escala = 1.0;
      if (sequencia) {
        escala = 1 + .12 * math.sin(math.pi * brilho);
      } else if (acendeu != null && !parado) {
        final p =
            (agora - acendeu).inMicroseconds / Movimento.media.inMicroseconds;
        if (p >= 0 && p < 1) escala = 1 + .35 * math.sin(math.pi * p);
      }
      final oval = Rect.fromCenter(
        center: Offset(x, y + 4 + 7 * escala),
        width: 10 * escala,
        height: 14 * escala,
      );
      bulbo.color = acesa
          ? Color.lerp(c.superficieElevada, cor, brilho)!
          : c.superficieElevada;
      canvas.drawOval(oval, bulbo);
      if (!acesa || c.ehDia || brilho < 1) {
        borda.color = acesa
            ? Color.lerp(c.linha, c.ehDia ? c.contorno : cor, brilho)!
            : c.linha;
        canvas.drawOval(oval, borda);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_VaralPintor o) =>
      o.c != c ||
      o.cores != cores ||
      o.acesas != acesas ||
      o.carregando != carregando ||
      o.sequencia != sequencia ||
      o.parado != parado ||
      o.vento != vento;
}
