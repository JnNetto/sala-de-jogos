import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/enums/aneis_regiao.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/aneis_carta_tabuleiro.dart';
import '../sala/pressionavel.dart';
import 'cores_dos_aneis.dart';

/// O tabuleiro do Cabe Aqui?: três anéis entrelaçados sobre o céu, cada um
/// na sua luz, com a contagem de cartas de cada região e, embaixo, a
/// bandeja de quem ficou fora de todos.
///
/// Com [posicionando], toda região vira alvo (as vazias mostram um "+") e o
/// toque escolhe onde a carta vai. Fora disso, o toque abre as cartas da
/// região, e segurar mostra uma prévia.
class TabuleiroAneis extends StatefulWidget {
  const TabuleiroAneis({
    super.key,
    required this.cartas,
    this.posicionando = false,
    this.destaque,
    this.aoEscolherRegiao,
    this.aoVerRegiao,
  });

  final List<AneisCartaTabuleiro> cartas;
  final bool posicionando;

  /// A região do palpite em julgamento, acesa enquanto se posiciona.
  final AneisRegiao? destaque;
  final ValueChanged<AneisRegiao>? aoEscolherRegiao;
  final ValueChanged<AneisRegiao>? aoVerRegiao;

  @override
  State<TabuleiroAneis> createState() => _TabuleiroAneisState();
}

class _TabuleiroAneisState extends State<TabuleiroAneis> {
  OverlayEntry? _previa;
  bool _foiSegurado = false;

  @override
  void dispose() {
    _esconderPrevia();
    super.dispose();
  }

  void _mostrarPrevia(Offset global, AneisRegiao regiao) {
    _foiSegurado = true;
    _esconderPrevia();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final daRegiao = [
      for (final carta in widget.cartas)
        if (carta.regiao == regiao) carta.texto,
    ];
    final tela = MediaQuery.sizeOf(context);
    final esquerda = (global.dx - 110).clamp(8.0, tela.width - 228);
    final topo = (global.dy - 150).clamp(8.0, tela.height - 220);
    // A prévia mora no Overlay, fora deste tema: leva as cores junto.
    final tema = Theme.of(context);

    _previa = OverlayEntry(
      builder: (_) => Positioned(
        left: esquerda,
        top: topo,
        child: IgnorePointer(
          child: Theme(
            data: tema,
            child: _Previa(regiao: regiao, textos: daRegiao),
          ),
        ),
      ),
    );
    overlay.insert(_previa!);
  }

  void _esconderPrevia() {
    _previa?.remove();
    _previa = null;
  }

  void _fecharPrevia() {
    _esconderPrevia();
    WidgetsBinding.instance.addPostFrameCallback((_) => _foiSegurado = false);
  }

  void _aoTocar(AneisRegiao regiao) {
    if (widget.posicionando) {
      widget.aoEscolherRegiao?.call(regiao);
    } else {
      widget.aoVerRegiao?.call(regiao);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final rotulo = Theme.of(context).textTheme.labelMedium!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, restricoes) {
              final area = AneisGeometria.areaUtil(restricoes.biggest);
              final geo = AneisGeometria.caber(area);
              return Center(
                child: SizedBox(
                  width: area.width,
                  height: area.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _PintorDosAneis(
                              geometria: geo,
                              cores: c,
                              estiloRotulo: rotulo,
                              destaque: widget.posicionando
                                  ? widget.destaque
                                  : null,
                              alvo: widget.posicionando,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (d) {
                            if (_foiSegurado) {
                              _foiSegurado = false;
                              return;
                            }
                            final regiao = geo.regiaoEm(d.localPosition);
                            if (widget.posicionando ||
                                regiao != AneisRegiao.nenhum) {
                              _aoTocar(regiao);
                            }
                          },
                          onLongPressStart: (d) {
                            _foiSegurado = true;
                            final regiao = geo.regiaoEm(d.localPosition);
                            if (regiao == AneisRegiao.nenhum) return;
                            _mostrarPrevia(d.globalPosition, regiao);
                          },
                          onLongPressEnd: (_) => _fecharPrevia(),
                          onLongPressCancel: _fecharPrevia,
                        ),
                      ),
                      for (final regiao in AneisRegiao.values)
                        if (regiao != AneisRegiao.nenhum)
                          _Marcador(
                            geometria: geo,
                            regiao: regiao,
                            textos: [
                              for (final carta in widget.cartas)
                                if (carta.regiao == regiao) carta.texto,
                            ],
                            posicionando: widget.posicionando,
                            destacado:
                                widget.posicionando &&
                                widget.destaque == regiao,
                            aoTocar: () => _aoTocar(regiao),
                            aoSegurar: (g) => _mostrarPrevia(g, regiao),
                            aoSoltar: _fecharPrevia,
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: Espaco.e2),
        _BandejaDeFora(
          quantidade: widget.cartas
              .where((carta) => carta.regiao == AneisRegiao.nenhum)
              .length,
          posicionando: widget.posicionando,
          destacada:
              widget.posicionando && widget.destaque == AneisRegiao.nenhum,
          aoTocar: () => _aoTocar(AneisRegiao.nenhum),
        ),
      ],
    );
  }
}

/// Onde ficam os anéis numa área: três círculos de raio igual, os centros
/// num triângulo equilátero, com espaço para os rótulos em cima e embaixo.
class AneisGeometria {
  AneisGeometria._({
    required this.tamanho,
    required this.raio,
    required this.palavra,
    required this.atributo,
    required this.contexto,
    required this.compacto,
  });

  static const double _k = 1.14;
  static const double _sen60 = 0.86602540378;
  static const double _rotuloTopo = 24.0;
  static const double _rotuloBase = 22.0;
  static const double _margemX = 8.0;

  /// O pedaço da área disponível que os anéis usam de fato.
  static Size areaUtil(Size disponivel) {
    final maxL = math.max(1.0, disponivel.width);
    final maxA = math.max(1.0, disponivel.height);
    final r = math.min(
      (maxL - _margemX * 2) / (2 + _k),
      (maxA - _rotuloTopo - _rotuloBase) / (2 + _k * _sen60),
    );
    return Size(
      math.min(maxL, r * (2 + _k) + _margemX * 2),
      math.min(maxA, r * (2 + _k * _sen60) + _rotuloTopo + _rotuloBase),
    );
  }

  factory AneisGeometria.caber(Size tamanho) {
    final livreL = math.max(1.0, tamanho.width - _margemX * 2);
    final livreA = math.max(1.0, tamanho.height - _rotuloTopo - _rotuloBase);
    final r = math.min(livreL / (2 + _k), livreA / (2 + _k * _sen60));
    final d = _k * r;
    final caixaL = 2 * r + d;
    final caixaA = 2 * r + d * _sen60;
    final x = (tamanho.width - caixaL) / 2;
    final y = _rotuloTopo + math.max(0.0, (livreA - caixaA) / 2);

    return AneisGeometria._(
      tamanho: tamanho,
      raio: r,
      palavra: Offset(x + r, y + r),
      atributo: Offset(x + r + d, y + r),
      contexto: Offset(x + r + d / 2, y + r + d * _sen60),
      compacto: r < 78,
    );
  }

  final Size tamanho;
  final double raio;
  final Offset palavra, atributo, contexto;

  /// Pouco espaço: os marcadores mostram só o número.
  final bool compacto;

  bool _dentro(Offset ponto, Offset centro) =>
      (ponto - centro).distance <= raio;

  AneisRegiao regiaoEm(Offset ponto) => AneisRegiao.fromCirculos(
    palavra: _dentro(ponto, palavra),
    atributo: _dentro(ponto, atributo),
    contexto: _dentro(ponto, contexto),
  );

  Offset centroDa(AneisRegiao regiao) {
    final palpite = switch (regiao) {
      AneisRegiao.nenhum => Offset(tamanho.width * .5, tamanho.height - 8),
      AneisRegiao.palavra => palavra + Offset(-raio * .58, -raio * .18),
      AneisRegiao.atributo => atributo + Offset(raio * .58, -raio * .18),
      AneisRegiao.contexto => contexto + Offset(0, raio * .54),
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
    dir = dist < .001
        ? const Offset(0, -1)
        : Offset(dir.dx / dist, dir.dy / dist);

    final margem = math.max(18.0, raio * .22);
    var t = math.max(0.0, raio + margem - dist);
    for (var i = 0; i < 10; i++) {
      final ponto = meio + dir * t;
      if (_dentro(ponto, a) && _dentro(ponto, b) && !_dentro(ponto, excluido)) {
        return ponto;
      }
      t *= .72;
    }
    return meio + dir * math.max(8.0, raio * .08);
  }

  Offset _buscarCentro(AneisRegiao alvo, Offset inicio) {
    for (var r = 4.0; r <= raio * .45; r += 4) {
      for (var angulo = 0.0; angulo < 360; angulo += 20) {
        final rad = angulo * math.pi / 180;
        final candidato = inicio + Offset(math.cos(rad) * r, math.sin(rad) * r);
        if (candidato.dx < 4 ||
            candidato.dy < 4 ||
            candidato.dx > tamanho.width - 4 ||
            candidato.dy > tamanho.height - 4) {
          continue;
        }
        if (regiaoEm(candidato) == alvo) return candidato;
      }
    }
    return inicio;
  }

  /// O contorno exato de uma região, para acendê-la.
  Path caminhoDa(AneisRegiao regiao) {
    Path circulo(Offset centro) =>
        Path()..addOval(Rect.fromCircle(center: centro, radius: raio));
    final p = circulo(palavra), a = circulo(atributo), c = circulo(contexto);
    Path e(Path x, Path y) => Path.combine(PathOperation.intersect, x, y);
    Path menos(Path x, Path y) => Path.combine(PathOperation.difference, x, y);

    return switch (regiao) {
      AneisRegiao.palavra => menos(menos(p, a), c),
      AneisRegiao.atributo => menos(menos(a, p), c),
      AneisRegiao.contexto => menos(menos(c, p), a),
      AneisRegiao.palavraAtributo => menos(e(p, a), c),
      AneisRegiao.palavraContexto => menos(e(p, c), a),
      AneisRegiao.atributoContexto => menos(e(a, c), p),
      AneisRegiao.todos => e(e(p, a), c),
      AneisRegiao.nenhum => Path(),
    };
  }
}

class _PintorDosAneis extends CustomPainter {
  _PintorDosAneis({
    required this.geometria,
    required this.cores,
    required this.estiloRotulo,
    required this.destaque,
    required this.alvo,
  });

  final AneisGeometria geometria;
  final SalaCores cores;
  final TextStyle estiloRotulo;
  final AneisRegiao? destaque;

  /// Posicionando: os anéis ficam um pouco mais acesos.
  final bool alvo;

  @override
  void paint(Canvas canvas, Size size) {
    final c = cores;
    final r = geometria.raio;
    final aneis = [
      (geometria.palavra, c.anelPalavra, 'LETRA'),
      (geometria.atributo, c.anelAtributo, 'JEITO'),
      (geometria.contexto, c.anelContexto, 'LUGAR'),
    ];

    // Preenchimento translúcido: nas interseções as luzes se somam.
    final preenchimento = c.ehDia ? (alvo ? .26 : .2) : (alvo ? .2 : .14);
    for (final (centro, luz, _) in aneis) {
      canvas.drawCircle(
        centro,
        r,
        Paint()..color = luz.cor.withValues(alpha: preenchimento),
      );
    }

    final d = destaque;
    if (d != null && d != AneisRegiao.nenhum) {
      final luz = c.luzDaRegiao(d);
      final caminho = geometria.caminhoDa(d);
      canvas.drawPath(caminho, Paint()..color = luz.cor.withValues(alpha: .45));
      canvas.drawPath(
        caminho,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = c.ehDia ? c.contorno : c.texto,
      );
    }

    for (final (centro, luz, _) in aneis) {
      // No Noite, um halo largo e fraco faz as vezes do brilho, sem desfoque.
      if (!c.ehDia) {
        canvas.drawCircle(
          centro,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9
            ..color = luz.cor.withValues(alpha: .14),
        );
      }
      canvas.drawCircle(
        centro,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = c.ehDia ? 2.5 : 3
          ..color = c.ehDia ? luz.tinta : luz.cor,
      );
    }

    for (final (centro, luz, nome) in aneis) {
      final emCima = centro != geometria.contexto;
      _rotulo(
        canvas,
        nome,
        Offset(centro.dx, emCima ? centro.dy - r - 13 : centro.dy + r + 12),
        luz.tinta,
      );
    }
  }

  void _rotulo(Canvas canvas, String texto, Offset centro, Color cor) {
    final pintor = TextPainter(
      text: TextSpan(
        text: texto,
        style: estiloRotulo.copyWith(color: cor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final t = geometria.tamanho;
    final dx = (centro.dx - pintor.width / 2).clamp(
      2.0,
      math.max(2.0, t.width - pintor.width - 2),
    );
    final dy = (centro.dy - pintor.height / 2).clamp(
      0.0,
      math.max(0.0, t.height - pintor.height),
    );
    pintor.paint(canvas, Offset(dx.toDouble(), dy.toDouble()));
  }

  @override
  bool shouldRepaint(_PintorDosAneis o) =>
      o.destaque != destaque ||
      o.alvo != alvo ||
      o.cores != cores ||
      o.estiloRotulo != estiloRotulo ||
      o.geometria.tamanho != geometria.tamanho;
}

/// A contagem de uma região: um botãozinho redondo com o número (ou "+",
/// quando dá para colocar uma carta ali). Num anel com uma carta só e
/// espaço sobrando, a palavra aparece embaixo.
class _Marcador extends StatelessWidget {
  const _Marcador({
    required this.geometria,
    required this.regiao,
    required this.textos,
    required this.posicionando,
    required this.destacado,
    required this.aoTocar,
    required this.aoSegurar,
    required this.aoSoltar,
  });

  final AneisGeometria geometria;
  final AneisRegiao regiao;
  final List<String> textos;
  final bool posicionando, destacado;
  final VoidCallback aoTocar;
  final ValueChanged<Offset> aoSegurar;
  final VoidCallback aoSoltar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final n = textos.length;
    if (n == 0 && !posicionando) return const SizedBox.shrink();

    final luz = c.luzDaRegiao(regiao);
    final centro = geometria.centroDa(regiao);
    final comPalavra = !geometria.compacto && regiao.ehAnelExclusivo && n == 1;
    final largura = comPalavra ? 72.0 : 36.0;
    final altura = comPalavra ? 50.0 : 36.0;
    final t = geometria.tamanho;
    final vazio = n == 0;

    return Positioned(
      left: (centro.dx - largura / 2).clamp(0.0, t.width - largura),
      top: (centro.dy - 18).clamp(0.0, t.height - altura),
      width: largura,
      height: altura,
      child: Semantics(
        button: true,
        label: vazio
            ? 'Colocar em ${regiao.rotulo}'
            : '${regiao.rotulo}: $n ${n == 1 ? 'carta' : 'cartas'}',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: aoTocar,
          onLongPressStart: (d) => aoSegurar(d.globalPosition),
          onLongPressEnd: (_) => aoSoltar(),
          onLongPressCancel: aoSoltar,
          child: Column(
            children: [
              AnimatedContainer(
                duration: Movimento.base,
                curve: Movimento.padrao,
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: destacado
                      ? luz.cor
                      : vazio
                      ? c.superficieFunda.withValues(alpha: .85)
                      : c.superficieElevada,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.ehDia ? c.contorno : luz.cor,
                    width: 2,
                  ),
                  boxShadow: destacado ? c.brilho(luz.cor, alpha: .6) : null,
                ),
                child: vazio
                    ? Icon(
                        Symbols.add_rounded,
                        size: 18,
                        weight: 700,
                        color: destacado ? c.sobreCor : luz.tinta,
                      )
                    : Text(
                        '$n',
                        style: context.estilos.hud.copyWith(
                          fontSize: 15,
                          height: 1,
                          color: destacado ? c.sobreCor : c.texto,
                        ),
                      ),
              ),
              if (comPalavra) ...[
                const SizedBox(height: 3),
                Text(
                  textos.first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: c.texto,
                    height: 1.1,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A faixa embaixo dos anéis, para as cartas que não cumprem nenhuma regra.
class _BandejaDeFora extends StatelessWidget {
  const _BandejaDeFora({
    required this.quantidade,
    required this.posicionando,
    required this.destacada,
    required this.aoTocar,
  });

  final int quantidade;
  final bool posicionando, destacada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.foraDosAneis;
    return Semantics(
      button: true,
      label: posicionando
          ? 'Colocar fora dos anéis'
          : 'Fora dos anéis: $quantidade',
      excludeSemantics: true,
      child: Pressionavel(
        onTap: aoTocar,
        escala: .98,
        child: AnimatedContainer(
          duration: Movimento.base,
          curve: Movimento.padrao,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: Espaco.e4),
          decoration: BoxDecoration(
            color: destacada
                ? Color.lerp(c.superficie, c.texto3, .3)
                : c.superficieFunda.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(Raio.lg),
            border: Border.all(
              color: destacada
                  ? (c.ehDia ? c.contorno : c.texto2)
                  : (c.ehDia ? c.contorno : c.linha),
              width: destacada ? 2 : c.bordaControle,
            ),
          ),
          child: Row(
            children: [
              Icon(Symbols.block_rounded, size: 20, color: luz.tinta),
              const SizedBox(width: Espaco.e3),
              Expanded(
                child: Text(
                  'Fora dos anéis',
                  style: texto.titleSmall?.copyWith(color: c.texto2),
                ),
              ),
              if (posicionando)
                Icon(Symbols.add_rounded, size: 20, color: c.texto2)
              else ...[
                Text(
                  '$quantidade',
                  style: context.estilos.hud.copyWith(
                    fontSize: 16,
                    color: c.texto,
                  ),
                ),
                const SizedBox(width: Espaco.e1),
                Icon(Symbols.chevron_right_rounded, size: 20, color: c.texto3),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A prévia ao segurar uma região: o nome dela e as cartas que estão lá.
class _Previa extends StatelessWidget {
  const _Previa({required this.regiao, required this.textos});

  final AneisRegiao regiao;
  final List<String> textos;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luzDaRegiao(regiao);
    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220, maxHeight: 200),
        padding: const EdgeInsets.all(Espaco.e3),
        decoration: BoxDecoration(
          color: c.superficieElevada,
          borderRadius: BorderRadius.circular(Raio.lg),
          border: Border.all(
            color: c.ehDia ? c.contorno : luz.cor,
            width: c.bordaControle,
          ),
          boxShadow: c.sombraFlutuante,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              regiao.rotulo.toUpperCase(),
              style: texto.labelSmall?.copyWith(color: luz.tinta),
            ),
            const SizedBox(height: Espaco.e2),
            if (textos.isEmpty)
              Text(
                'Nenhuma carta',
                style: texto.bodyMedium?.copyWith(color: c.texto2),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final t in textos) CartaNoTabuleiro(t)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Uma carta já jogada, pequena: nas prévias, na folha da região e no fim.
class CartaNoTabuleiro extends StatelessWidget {
  const CartaNoTabuleiro(this.texto, {super.key, this.luz});

  final String texto;
  final Luz? luz;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: luz?.suave ?? c.superficieFunda,
        borderRadius: BorderRadius.circular(Raio.sm),
        border: Border.all(
          color: c.ehDia ? c.contorno : (luz?.cor ?? c.linha),
          width: c.ehDia ? 1.5 : 1,
        ),
      ),
      child: Text(
        texto,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: luz?.tinta ?? c.texto),
      ),
    );
  }
}
