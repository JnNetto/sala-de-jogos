import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/aneis_constants.dart';
import '../../core/enums/aneis_regiao.dart';
import '../../data/models/aneis_carta_tabuleiro.dart';

class AneisVennBoard extends StatefulWidget {
  final List<AneisCartaTabuleiro> cartas;
  final bool posicionando;
  final AneisRegiao? destaque;
  final ValueChanged<AneisRegiao>? onSelecionarRegiao;
  final ValueChanged<AneisRegiao>? onVerRegiao;

  const AneisVennBoard({
    super.key,
    required this.cartas,
    this.posicionando = false,
    this.destaque,
    this.onSelecionarRegiao,
    this.onVerRegiao,
  });

  @override
  State<AneisVennBoard> createState() => _AneisVennBoardState();
}

class _AneisVennBoardState extends State<AneisVennBoard> {
  OverlayEntry? _preview;
  bool _foiLongPress = false;

  @override
  void dispose() {
    _esconderPreview();
    super.dispose();
  }

  void _mostrarPreview(Offset global, AneisRegiao regiao) {
    _foiLongPress = true;
    _esconderPreview();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final daRegiao = widget.cartas
        .where((carta) => carta.regiao == regiao)
        .toList(growable: false);
    final media = MediaQuery.sizeOf(context);
    final left = (global.dx - 108).clamp(8.0, media.width - 228);
    final top = (global.dy - 140).clamp(8.0, media.height - 220);

    _preview = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: left,
          top: top,
          child: IgnorePointer(
            child: Material(
              elevation: 10,
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220, maxHeight: 200),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        regiao.rotulo,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: regiao.cor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (daRegiao.isEmpty)
                        Text(
                          'Nenhuma carta',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 140),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final carta in daRegiao)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      carta.texto,
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
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
      },
    );
    overlay.insert(_preview!);
  }

  void _esconderPreview() {
    _preview?.remove();
    _preview = null;
  }

  void _fecharPreview() {
    _esconderPreview();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _foiLongPress = false;
    });
  }

  void _aoToque(AneisRegiao regiao) {
    if (widget.posicionando) {
      widget.onSelecionarRegiao?.call(regiao);
    } else if (regiao != AneisRegiao.nenhum || widget.onVerRegiao != null) {
      widget.onVerRegiao?.call(regiao);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final area = AneisGeometria.areaUtil(constraints.biggest);
              final geom = AneisGeometria.caber(area);
              return Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: area.width,
                  height: area.height,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _VennPainter(
                            geometria: geom,
                            destaque: widget.posicionando ? widget.destaque : null,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) {
                            if (_foiLongPress) {
                              _foiLongPress = false;
                              return;
                            }
                            final regiao = geom.regiaoEm(details.localPosition);
                            if (widget.posicionando) {
                              widget.onSelecionarRegiao?.call(regiao);
                            } else if (regiao != AneisRegiao.nenhum) {
                              widget.onVerRegiao?.call(regiao);
                            }
                          },
                          onLongPressStart: (details) {
                            _foiLongPress = true;
                            final regiao = geom.regiaoEm(details.localPosition);
                            if (regiao == AneisRegiao.nenhum) return;
                            _mostrarPreview(details.globalPosition, regiao);
                          },
                          onLongPressEnd: (_) => _fecharPreview(),
                          onLongPressCancel: _fecharPreview,
                        ),
                      ),
                      for (final regiao in AneisRegiao.values)
                        if (regiao != AneisRegiao.nenhum)
                          _RegionMarker(
                            geometria: geom,
                            regiao: regiao,
                            cartas: widget.cartas
                                .where((carta) => carta.regiao == regiao)
                                .toList(growable: false),
                            posicionando: widget.posicionando,
                            onTap: () => _aoToque(regiao),
                            onLongPressStart: (global) =>
                                _mostrarPreview(global, regiao),
                            onLongPressEnd: _fecharPreview,
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _NenhumAnelBandeja(
          quantidade: widget.cartas
              .where((carta) => carta.regiao == AneisRegiao.nenhum)
              .length,
          selecionada:
              widget.posicionando && widget.destaque == AneisRegiao.nenhum,
          posicionando: widget.posicionando,
          onTap: () => _aoToque(AneisRegiao.nenhum),
          onLongPressStart: (global) =>
              _mostrarPreview(global, AneisRegiao.nenhum),
          onLongPressEnd: _fecharPreview,
        ),
      ],
    );
  }
}

class AneisGeometria {
  AneisGeometria._({
    required this.size,
    required this.radius,
    required this.palavra,
    required this.atributo,
    required this.contexto,
    required this.compacto,
  });

  static const double _k = 1.14;
  static const double _sin60 = 0.86602540378;
  static const double _labelTop = 22.0;
  static const double _labelBottom = 18.0;
  static const double _padX = 8.0;

  static Size areaUtil(Size disponivel) {
    final maxW = math.max(1.0, disponivel.width);
    final maxH = math.max(1.0, disponivel.height);
    final r = math.min(
      (maxW - _padX * 2) / (2 + _k),
      (maxH - _labelTop - _labelBottom) / (2 + _k * _sin60),
    );
    return Size(
      math.min(maxW, r * (2 + _k) + _padX * 2),
      math.min(maxH, r * (2 + _k * _sin60) + _labelTop + _labelBottom),
    );
  }

  factory AneisGeometria.caber(Size size) {
    final availW = math.max(1.0, size.width - _padX * 2);
    final availH = math.max(1.0, size.height - _labelTop - _labelBottom);
    final r = math.min(availW / (2 + _k), availH / (2 + _k * _sin60));
    final d = _k * r;
    final boxW = 2 * r + d;
    final boxH = 2 * r + d * _sin60;
    final originX = (size.width - boxW) / 2;
    final originY = _labelTop + math.max(0.0, (availH - boxH) / 2);

    return AneisGeometria._(
      size: size,
      radius: r,
      palavra: Offset(originX + r, originY + r),
      atributo: Offset(originX + r + d, originY + r),
      contexto: Offset(originX + r + d / 2, originY + r + d * _sin60),
      compacto: r < 78,
    );
  }

  final Size size;
  final double radius;
  final Offset palavra;
  final Offset atributo;
  final Offset contexto;
  final bool compacto;

  bool _dentro(Offset ponto, Offset centro) =>
      (ponto - centro).distance <= radius;

  AneisRegiao regiaoEm(Offset ponto) {
    return AneisRegiao.fromCirculos(
      palavra: _dentro(ponto, palavra),
      atributo: _dentro(ponto, atributo),
      contexto: _dentro(ponto, contexto),
    );
  }

  Offset centroDa(AneisRegiao regiao) {
    final palpite = switch (regiao) {
      AneisRegiao.nenhum => Offset(size.width * 0.5, size.height - 8),
      AneisRegiao.palavra => palavra + Offset(-radius * 0.58, -radius * 0.18),
      AneisRegiao.atributo => atributo + Offset(radius * 0.58, -radius * 0.18),
      AneisRegiao.contexto => contexto + Offset(0, radius * 0.54),
      AneisRegiao.palavraAtributo => _centroDuplo(palavra, atributo, contexto),
      AneisRegiao.palavraContexto => _centroDuplo(palavra, contexto, atributo),
      AneisRegiao.atributoContexto => _centroDuplo(atributo, contexto, palavra),
      AneisRegiao.todos => Offset(
        (palavra.dx + atributo.dx + contexto.dx) / 3,
        (palavra.dy + atributo.dy + contexto.dy) / 3,
      ),
    };
    if (regiaoEm(palpite) == regiao) return palpite;
    return _buscarCentro(regiao, palpite);
  }

  Offset _centroDuplo(Offset a, Offset b, Offset excluido) {
    final meio = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    var dir = meio - excluido;
    final dist = dir.distance;
    dir = dist < 0.001
        ? const Offset(0, -1)
        : Offset(dir.dx / dist, dir.dy / dist);

    final margem = math.max(18.0, radius * 0.22);
    var t = math.max(0.0, radius + margem - dist);
    for (var i = 0; i < 10; i++) {
      final ponto = meio + dir * t;
      if (_dentro(ponto, a) && _dentro(ponto, b) && !_dentro(ponto, excluido)) {
        return ponto;
      }
      t *= 0.72;
    }
    return meio + dir * math.max(8.0, radius * 0.08);
  }

  Offset _buscarCentro(AneisRegiao alvo, Offset inicio) {
    for (var raio = 4.0; raio <= radius * 0.45; raio += 4) {
      for (var angulo = 0.0; angulo < 360; angulo += 20) {
        final rad = angulo * math.pi / 180;
        final candidato =
            inicio + Offset(math.cos(rad) * raio, math.sin(rad) * raio);
        if (candidato.dx < 4 ||
            candidato.dy < 4 ||
            candidato.dx > size.width - 4 ||
            candidato.dy > size.height - 4) {
          continue;
        }
        if (regiaoEm(candidato) == alvo) return candidato;
      }
    }
    return inicio;
  }
}

class _VennPainter extends CustomPainter {
  final AneisGeometria geometria;
  final AneisRegiao? destaque;

  _VennPainter({required this.geometria, this.destaque});

  @override
  void paint(Canvas canvas, Size size) {
    final fills = [
      (geometria.palavra, AneisConstants.corPalavra, 'Palavra'),
      (geometria.atributo, AneisConstants.corAtributo, 'Atributo'),
      (geometria.contexto, AneisConstants.corContexto, 'Contexto'),
    ];
    final r = geometria.radius;

    for (final entry in fills) {
      canvas.drawCircle(
        entry.$1,
        r,
        Paint()
          ..style = PaintingStyle.fill
          ..color = entry.$2.withValues(alpha: 0.26),
      );
    }

    if (destaque != null && destaque != AneisRegiao.nenhum) {
      final path = _pathDaRegiao(destaque!);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = destaque!.cor.withValues(alpha: 0.22),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = destaque!.cor,
      );
    }

    for (final entry in fills) {
      canvas.drawCircle(
        entry.$1,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = entry.$2,
      );
    }

    final fonte = (r * 0.13).clamp(10.0, 13.0);
    _desenharRotulo(
      canvas,
      'Palavra',
      Offset(geometria.palavra.dx, geometria.palavra.dy - r - fonte * 0.85),
      AneisConstants.corPalavra,
      fonte,
    );
    _desenharRotulo(
      canvas,
      'Atributo',
      Offset(geometria.atributo.dx, geometria.atributo.dy - r - fonte * 0.85),
      AneisConstants.corAtributo,
      fonte,
    );
    _desenharRotulo(
      canvas,
      'Contexto',
      Offset(geometria.contexto.dx, geometria.contexto.dy + r + fonte * 0.55),
      AneisConstants.corContexto,
      fonte,
    );
  }

  Path _circulo(Offset centro) {
    return Path()
      ..addOval(Rect.fromCircle(center: centro, radius: geometria.radius));
  }

  Path _pathDaRegiao(AneisRegiao regiao) {
    final p = _circulo(geometria.palavra);
    final a = _circulo(geometria.atributo);
    final c = _circulo(geometria.contexto);
    Path intersect(Path x, Path y) =>
        Path.combine(PathOperation.intersect, x, y);
    Path difference(Path x, Path y) =>
        Path.combine(PathOperation.difference, x, y);

    switch (regiao) {
      case AneisRegiao.palavra:
        return difference(difference(p, a), c);
      case AneisRegiao.atributo:
        return difference(difference(a, p), c);
      case AneisRegiao.contexto:
        return difference(difference(c, p), a);
      case AneisRegiao.palavraAtributo:
        return difference(intersect(p, a), c);
      case AneisRegiao.palavraContexto:
        return difference(intersect(p, c), a);
      case AneisRegiao.atributoContexto:
        return difference(intersect(a, c), p);
      case AneisRegiao.todos:
        return intersect(intersect(p, a), c);
      case AneisRegiao.nenhum:
        return Path();
    }
  }

  void _desenharRotulo(
    Canvas canvas,
    String texto,
    Offset offset,
    Color cor,
    double fonte,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(
          color: cor,
          fontWeight: FontWeight.w800,
          fontSize: fonte,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = offset.dx - painter.width / 2;
    var dy = offset.dy - painter.height / 2;
    dx = dx.clamp(2.0, geometria.size.width - painter.width - 2);
    dy = dy.clamp(0.0, geometria.size.height - painter.height);
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _VennPainter oldDelegate) {
    return oldDelegate.destaque != destaque ||
        oldDelegate.geometria.size != geometria.size ||
        oldDelegate.geometria.radius != geometria.radius;
  }
}

class _RegionMarker extends StatelessWidget {
  final AneisGeometria geometria;
  final AneisRegiao regiao;
  final List<AneisCartaTabuleiro> cartas;
  final bool posicionando;
  final VoidCallback onTap;
  final ValueChanged<Offset> onLongPressStart;
  final VoidCallback onLongPressEnd;

  const _RegionMarker({
    required this.geometria,
    required this.regiao,
    required this.cartas,
    required this.posicionando,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final count = cartas.length;
    if (count == 0 && !posicionando) {
      return const SizedBox.shrink();
    }

    final centro = geometria.centroDa(regiao);
    final mostrarPalavra =
        !geometria.compacto &&
        regiao.ehAnelExclusivo &&
        count == 1;
    final largura = mostrarPalavra ? 58.0 : 28.0;
    final altura = mostrarPalavra ? 40.0 : 28.0;
    final left = (centro.dx - largura / 2).clamp(
      0.0,
      geometria.size.width - largura,
    );
    final top = (centro.dy - altura / 2).clamp(
      0.0,
      geometria.size.height - altura,
    );

    return Positioned(
      left: left,
      top: top,
      width: largura,
      height: altura,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: (details) => onLongPressStart(details.globalPosition),
        onLongPressEnd: (_) => onLongPressEnd(),
        onLongPressCancel: onLongPressEnd,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: count == 0
                    ? Colors.white.withValues(alpha: 0.72)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: regiao.cor, width: 1.6),
              ),
              child: Text(
                count == 0 ? '+' : '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: count == 0 ? regiao.cor : Colors.black,
                ),
              ),
            ),
            if (mostrarPalavra)
              Text(
                cartas.first.texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NenhumAnelBandeja extends StatelessWidget {
  final int quantidade;
  final bool selecionada;
  final bool posicionando;
  final VoidCallback onTap;
  final ValueChanged<Offset> onLongPressStart;
  final VoidCallback onLongPressEnd;

  const _NenhumAnelBandeja({
    required this.quantidade,
    required this.selecionada,
    required this.posicionando,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionada
          ? AneisConstants.corNenhum.withValues(alpha: 0.28)
          : AneisConstants.corNenhum.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPressStart: (details) =>
            onLongPressStart(details.globalPosition),
        onLongPressEnd: (_) => onLongPressEnd(),
        onLongPressCancel: onLongPressEnd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selecionada
                  ? AneisConstants.corNenhum
                  : AneisConstants.corNenhum.withValues(alpha: 0.55),
              width: selecionada ? 2.2 : 1.3,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.highlight_off,
                size: 18,
                color: AneisConstants.corNenhum,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  posicionando
                      ? 'Nenhum anel — toque para colocar'
                      : 'Nenhum anel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AneisConstants.corNenhum,
                  ),
                ),
              ),
              Text(
                quantidade == 1 ? '1 carta' : '$quantidade cartas',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AneisConstants.corNenhum),
            ],
          ),
        ),
      ),
    );
  }
}
