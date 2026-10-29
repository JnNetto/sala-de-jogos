import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/models/jogo_disponivel.dart';
import '../../../core/theme/sala_tokens.dart';
import 'botao_sala.dart';
import 'janela.dart';
import 'tag_sala.dart';
import 'tela_da_sala.dart';

/// A home de um jogo: poço grande com a luz do jogo, nome, o que é o jogo,
/// as tags, uma janela "EM 20 SEGUNDOS" com os passos e, no rodapé, "Jogar"
/// e "Estatísticas". As regras completas abrem pelo botão da barra.
class HomeDoJogo extends StatelessWidget {
  const HomeDoJogo({
    super.key,
    required this.jogo,
    required this.resumo,
    required this.passos,
    required this.aoJogar,
    this.aoVerRegras,
    this.aoVerEstatisticas,
    this.offline = true,
  });

  final JogoDisponivel jogo;

  /// Duas frases sobre o jogo (a descrição da lista é só uma linha).
  final String resumo;

  /// Até três passos curtos: "Passem o celular. Cada um vê a palavra."
  final List<String> passos;
  final VoidCallback aoJogar;
  final VoidCallback? aoVerRegras;
  final VoidCallback? aoVerEstatisticas;

  /// Joga num celular só, sem internet.
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(jogo.matiz);
    final texto = Theme.of(context).textTheme;

    return TelaDaSala(
      titulo: '',
      matiz: jogo.matiz,
      acao: aoVerRegras == null
          ? null
          : BotaoIcone(
              icone: Symbols.menu_book_rounded,
              rotulo: 'Regras',
              onPressed: aoVerRegras,
            ),
      corpo: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Espaco.larguraMax),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      Espaco.margemTela,
                      0,
                      Espaco.margemTela,
                      Espaco.e4,
                    ),
                    child: Column(
                      children: [
                        _Poco(luz: luz, icone: jogo.icone),
                        const SizedBox(height: Espaco.e6),
                        MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.3,
                          child: Semantics(
                            header: true,
                            child: Text(
                              jogo.nome,
                              textAlign: TextAlign.center,
                              style: texto.displayMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: Espaco.e3),
                        Text(
                          resumo,
                          textAlign: TextAlign.center,
                          style: texto.bodyLarge?.copyWith(color: c.texto2),
                        ),
                        const SizedBox(height: Espaco.e4),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: Espaco.e2,
                          runSpacing: 6,
                          children: [
                            TagSala(
                              '${jogo.minJogadores}–${jogo.maxJogadores}',
                              icone: Symbols.group_rounded,
                              luz: luz,
                            ),
                            TagSala(
                              '${jogo.duracaoMinutos} MIN',
                              icone: Symbols.schedule_rounded,
                            ),
                            if (offline)
                              const TagSala(
                                'OFFLINE',
                                icone: Symbols.wifi_off_rounded,
                              ),
                          ],
                        ),
                        const SizedBox(height: Espaco.e6),
                        Janela(
                          titulo: 'EM 20 SEGUNDOS',
                          preenchimento: const EdgeInsets.fromLTRB(
                            Espaco.e5,
                            Espaco.e4,
                            Espaco.e5,
                            Espaco.e5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, passo) in passos.indexed) ...[
                                if (i > 0) const SizedBox(height: Espaco.e3),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${i + 1}',
                                        style: context.estilos.hud.copyWith(
                                          fontSize: 18,
                                          color: luz.tinta,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        passo,
                                        style: texto.bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Espaco.margemTela,
                    Espaco.e2,
                    Espaco.margemTela,
                    Espaco.e6,
                  ),
                  child: Column(
                    children: [
                      BotaoSala(
                        rotulo: 'Jogar',
                        icone: Symbols.play_arrow_rounded,
                        luz: luz,
                        bloco: true,
                        onPressed: aoJogar,
                      ),
                      if (aoVerEstatisticas != null) ...[
                        const SizedBox(height: Espaco.e3),
                        BotaoSala(
                          rotulo: 'Estatísticas',
                          icone: Symbols.bar_chart_rounded,
                          variante: VarianteBotao.secundario,
                          bloco: true,
                          onPressed: aoVerEstatisticas,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O poço grande da home do jogo: tela acesa com linhas de CRT e halo forte.
class _Poco extends StatelessWidget {
  const _Poco({required this.luz, required this.icone});

  final Luz luz;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: luz.suave,
        borderRadius: BorderRadius.circular(Raio.xxl),
        border: c.ehDia ? Border.all(color: c.contorno, width: 2) : null,
        boxShadow: [
          ...c.brilho(luz.cor, alpha: .45, blur: 56),
          if (c.ehDia) BoxShadow(color: c.contorno, offset: const Offset(0, 4)),
        ],
      ),
      child: CustomPaint(
        painter: _LinhasCrt(luz.cor.withValues(alpha: .12)),
        child: Icon(icone, size: 56, fill: 1, color: luz.tinta),
      ),
    );
  }
}

class _LinhasCrt extends CustomPainter {
  _LinhasCrt(this.cor);

  final Color cor;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(Raio.xxl)),
    );
    final p = Paint()..color = cor;
    for (var y = 3.0; y < s.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, s.width, math.min(1, s.height)), p);
    }
  }

  @override
  bool shouldRepaint(_LinhasCrt o) => o.cor != cor;
}
