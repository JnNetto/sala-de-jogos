import 'package:flutter/material.dart';

import 'sala_texto.dart';

/// Uma cor de luz do sistema em três usos.
@immutable
class Luz {
  const Luz(this.cor, this.tinta, this.suave);

  /// Preenchimento e brilho.
  final Color cor;

  /// Texto e ícone sobre superfícies.
  final Color tinta;

  /// Fundo tingido.
  final Color suave;

  static Luz lerp(Luz a, Luz b, double t) => Luz(
    Color.lerp(a.cor, b.cor, t)!,
    Color.lerp(a.tinta, b.tinta, t)!,
    Color.lerp(a.suave, b.suave, t)!,
  );
}

/// As famílias de cor. Cada jogo é uma luz; estados e papéis reaproveitam as mesmas.
enum Matiz { violeta, rosa, menta, brasa, lampada, luar, ceu, carmim }

@immutable
class SalaCores extends ThemeExtension<SalaCores> {
  const SalaCores({
    required this.ceuTopo,
    required this.ceuBrilho,
    required this.fundo,
    required this.estrela,
    required this.superficie,
    required this.superficieElevada,
    required this.superficieFunda,
    required this.linha,
    required this.linhaForte,
    required this.contorno,
    required this.texto,
    required this.texto2,
    required this.texto3,
    required this.janelaBarra,
    required this.janelaBarraTexto,
    required this.primaria,
    required this.primariaLabio,
    required this.primariaTinta,
    required this.sobreCor,
    required this.marca,
    required this.marcaSuave,
    required this.veu,
    required this.luzes,
    required this.ehDia,
  });

  final Color ceuTopo, ceuBrilho, fundo, estrela;
  final Color superficie, superficieElevada, superficieFunda;
  final Color linha, linhaForte, contorno;
  final Color texto, texto2, texto3;
  final Color janelaBarra, janelaBarraTexto;
  final Color primaria, primariaLabio, primariaTinta, sobreCor;
  final Color marca, marcaSuave, veu;
  final Map<Matiz, Luz> luzes;
  final bool ehDia;

  Luz luz(Matiz m) => luzes[m]!;
  Luz get sucesso => luz(Matiz.menta);
  Luz get erro => luz(Matiz.carmim);
  Luz get aviso => luz(Matiz.lampada);
  Luz get info => luz(Matiz.ceu);
  Luz get papelEspiao => luz(Matiz.carmim);
  Luz get papelCivil => luz(Matiz.ceu);

  /// Espessura das bordas de controle: fina no Noite, de tinta no Dia.
  double get bordaControle => ehDia ? 2 : 1.5;

  /// `sombra-card`: um lábio escuro e duro, sem desfoque, nos dois temas.
  /// O desfoque de 28 px dos tokens quase não aparecia sobre o céu escuro e
  /// custava caro: nas transições cada card era redesenhado com ele a cada
  /// quadro.
  List<BoxShadow> get sombraCard => ehDia
      ? [BoxShadow(color: contorno, offset: const Offset(0, 3))]
      : const [BoxShadow(color: Color(0x8004051A), offset: Offset(0, 4))];

  /// `sombra-flutuante`: diálogo, toast, carta. No Noite com metade do
  /// desfoque dos tokens, pelo mesmo motivo.
  List<BoxShadow> get sombraFlutuante => ehDia
      ? [BoxShadow(color: contorno, offset: const Offset(0, 6))]
      : const [
          BoxShadow(
            color: Color(0xB304051A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ];

  /// Halo `brilho-jogo` na cor dada. Só existe no Noite.
  List<BoxShadow> brilho(Color cor, {double alpha = .32, double blur = 26}) =>
      ehDia
      ? const []
      : [
          BoxShadow(
            color: cor.withValues(alpha: alpha),
            blurRadius: blur,
          ),
        ];

  static const noite = SalaCores(
    ceuTopo: Color(0xFF070822),
    ceuBrilho: Color(0xFF1E1D5C),
    fundo: Color(0xFF0D0F2B),
    estrela: Color(0xFFB9B6F2),
    superficie: Color(0xFF181B4A),
    superficieElevada: Color(0xFF222664),
    superficieFunda: Color(0xFF12143A),
    linha: Color(0xFF2B2F70),
    linhaForte: Color(0xFF6A6FC4),
    contorno: Color(0xFF05061A),
    texto: Color(0xFFF1EEFF),
    texto2: Color(0xFFB7B5E6),
    texto3: Color(0xFF8A8CC8),
    janelaBarra: Color(0xFF262A6E),
    janelaBarraTexto: Color(0xFFD9D6FF),
    primaria: Color(0xFFFFC94D),
    primariaLabio: Color(0xFFC9922A),
    primariaTinta: Color(0xFFFFC94D),
    sobreCor: Color(0xFF0D0F2B),
    marca: Color(0xFF8F7CFF),
    marcaSuave: Color(0xFF221C5A),
    veu: Color(0xCC070822),
    ehDia: false,
    luzes: {
      Matiz.violeta: Luz(
        Color(0xFF8F7CFF),
        Color(0xFF9A8AFF),
        Color(0xFF221C5A),
      ),
      Matiz.rosa: Luz(Color(0xFFFF77B7), Color(0xFFFF77B7), Color(0xFF3D1C4F)),
      Matiz.menta: Luz(Color(0xFF4FE3A6), Color(0xFF4FE3A6), Color(0xFF123B45)),
      Matiz.brasa: Luz(Color(0xFFFF8F55), Color(0xFFFF8F55), Color(0xFF3E2340)),
      Matiz.lampada: Luz(
        Color(0xFFFFC94D),
        Color(0xFFFFC94D),
        Color(0xFF3A2E3E),
      ),
      Matiz.luar: Luz(Color(0xFF67D6F0), Color(0xFF67D6F0), Color(0xFF143552)),
      Matiz.ceu: Luz(Color(0xFF5FA2FF), Color(0xFF5FA2FF), Color(0xFF1B2B66)),
      Matiz.carmim: Luz(
        Color(0xFFFF5D73),
        Color(0xFFFF5D73),
        Color(0xFF3F1A3C),
      ),
    },
  );

  static const dia = SalaCores(
    ceuTopo: Color(0xFFFBF6EC),
    ceuBrilho: Color(0xFFEFE4F6),
    fundo: Color(0xFFF4EEE3),
    estrela: Color(0xFFD9CDB8),
    superficie: Color(0xFFFFFBF4),
    superficieElevada: Color(0xFFFFFFFF),
    superficieFunda: Color(0xFFEBE3D4),
    linha: Color(0xFFDDD2BF),
    linhaForte: Color(0xFF1B1D5C),
    contorno: Color(0xFF1B1D5C),
    texto: Color(0xFF1B1D5C),
    texto2: Color(0xFF4A4C86),
    texto3: Color(0xFF5F6196),
    janelaBarra: Color(0xFF2335C7),
    janelaBarraTexto: Color(0xFFFFF6E6),
    primaria: Color(0xFFFFC94D),
    primariaLabio: Color(0xFF1B1D5C),
    primariaTinta: Color(0xFF8A5A00),
    sobreCor: Color(0xFF1B1D5C),
    marca: Color(0xFF5B47F0),
    marcaSuave: Color(0xFFE9E5FF),
    veu: Color(0x991B1D5C),
    ehDia: true,
    luzes: {
      Matiz.violeta: Luz(
        Color(0xFF8F7CFF),
        Color(0xFF5B47F0),
        Color(0xFFE9E5FF),
      ),
      Matiz.rosa: Luz(Color(0xFFFF77B7), Color(0xFFBE2A6E), Color(0xFFFFE4F0)),
      Matiz.menta: Luz(Color(0xFF4FE3A6), Color(0xFF08744A), Color(0xFFDDF7EA)),
      Matiz.brasa: Luz(Color(0xFFFF8F55), Color(0xFFB0440E), Color(0xFFFFE6D6)),
      Matiz.lampada: Luz(
        Color(0xFFFFC94D),
        Color(0xFF8A5A00),
        Color(0xFFFFF1CC),
      ),
      Matiz.luar: Luz(Color(0xFF67D6F0), Color(0xFF096C88), Color(0xFFDBF4FA)),
      Matiz.ceu: Luz(Color(0xFF5FA2FF), Color(0xFF1F5FD6), Color(0xFFE0ECFF)),
      Matiz.carmim: Luz(
        Color(0xFFFF5D73),
        Color(0xFFC22440),
        Color(0xFFFFE1E5),
      ),
    },
  );

  @override
  SalaCores copyWith() => this;

  @override
  SalaCores lerp(SalaCores? o, double t) {
    if (o == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SalaCores(
      ceuTopo: l(ceuTopo, o.ceuTopo),
      ceuBrilho: l(ceuBrilho, o.ceuBrilho),
      fundo: l(fundo, o.fundo),
      estrela: l(estrela, o.estrela),
      superficie: l(superficie, o.superficie),
      superficieElevada: l(superficieElevada, o.superficieElevada),
      superficieFunda: l(superficieFunda, o.superficieFunda),
      linha: l(linha, o.linha),
      linhaForte: l(linhaForte, o.linhaForte),
      contorno: l(contorno, o.contorno),
      texto: l(texto, o.texto),
      texto2: l(texto2, o.texto2),
      texto3: l(texto3, o.texto3),
      janelaBarra: l(janelaBarra, o.janelaBarra),
      janelaBarraTexto: l(janelaBarraTexto, o.janelaBarraTexto),
      primaria: l(primaria, o.primaria),
      primariaLabio: l(primariaLabio, o.primariaLabio),
      primariaTinta: l(primariaTinta, o.primariaTinta),
      sobreCor: l(sobreCor, o.sobreCor),
      marca: l(marca, o.marca),
      marcaSuave: l(marcaSuave, o.marcaSuave),
      veu: l(veu, o.veu),
      luzes: {
        for (final m in Matiz.values) m: Luz.lerp(luzes[m]!, o.luzes[m]!, t),
      },
      ehDia: t < .5 ? ehDia : o.ehDia,
    );
  }
}

abstract final class Espaco {
  static const e1 = 4.0, e2 = 8.0, e3 = 12.0, e4 = 16.0, e5 = 20.0;
  static const e6 = 24.0, e8 = 32.0, e12 = 48.0, e16 = 64.0;
  static const margemTela = 20.0, alvoToque = 48.0, larguraMax = 560.0;
}

abstract final class Raio {
  static const xs = 6.0, sm = 10.0, md = 14.0, lg = 18.0;
  static const xl = 24.0, xxl = 32.0, pill = 999.0;
}

abstract final class Opacidade {
  static const desabilitado = .4;
  static const suave = .15;
}

abstract final class Movimento {
  static const instante = Duration(milliseconds: 80);
  static const rapida = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 220);
  static const media = Duration(milliseconds: 320);
  static const lenta = Duration(milliseconds: 450);
  static const dramatica = Duration(milliseconds: 640);
  static const ambiente = Duration(milliseconds: 3200);

  static const padrao = Cubic(0.2, 0, 0, 1);
  static const entrada = Cubic(0.05, 0.7, 0.1, 1);
  static const saida = Cubic(0.3, 0, 0.8, 0.15);
  static const pulo = Cubic(0.34, 1.56, 0.64, 1);

  /// Use em toda animação não essencial.
  static bool reduzido(BuildContext c) => MediaQuery.disableAnimationsOf(c);
  static Duration d(BuildContext c, Duration x) =>
      reduzido(c) ? const Duration(milliseconds: 120) : x;
}

extension SalaContexto on BuildContext {
  SalaCores get cores => Theme.of(this).extension<SalaCores>()!;
  SalaTexto get estilos => Theme.of(this).extension<SalaTexto>()!;
}
