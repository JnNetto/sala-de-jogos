import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';

/// Texto em pixel com cada caractere numa caixa de largura fixa: a fonte
/// pixel não tem algarismos tabulares, e assim o tempo não "pula".
class DigitosHud extends StatelessWidget {
  const DigitosHud(this.texto, {super.key, this.estilo});

  final String texto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final s = estilo ?? context.estilos.hud;
    final fs = s.fontSize ?? 20;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ch in texto.characters)
          SizedBox(
            width: fs * (ch == ':' ? .4 : .66),
            child: Text(ch, style: s, textAlign: TextAlign.center),
          ),
      ],
    );
  }
}

String formatarTempo(int segundos) {
  final s = segundos.clamp(0, 5999);
  return '${(s ~/ 60).toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';
}

/// O relógio HUD da rodada. Muda de cara perto do fim: atenção (≤10 s, em
/// lâmpada) e crítico (≤5 s, em carmim, pulsando a cada segundo). Pausado,
/// os dígitos piscam.
class Cronometro extends StatefulWidget {
  const Cronometro({
    super.key,
    required this.segundos,
    this.pausado = false,
    this.grande = false,
  });

  final int segundos;
  final bool pausado;

  /// A versão de destaque, no meio da tela.
  final bool grande;

  @override
  State<Cronometro> createState() => _CronometroState();
}

class _CronometroState extends State<Cronometro> with TickerProviderStateMixin {
  late final _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final _piscar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    _atualizarPiscar();
  }

  @override
  void didUpdateWidget(Cronometro antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.pausado != widget.pausado) _atualizarPiscar();
    final critico = widget.segundos <= 5 && widget.segundos > 0;
    if (critico && antigo.segundos != widget.segundos && !widget.pausado) {
      HapticFeedback.lightImpact();
      if (!Movimento.reduzido(context)) _pulso.forward(from: 0);
    }
    if (widget.segundos == 0 && antigo.segundos != 0) {
      HapticFeedback.mediumImpact();
    }
  }

  void _atualizarPiscar() {
    if (widget.pausado) {
      _piscar.repeat(reverse: true);
    } else {
      _piscar
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    _piscar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final s = widget.segundos;
    final Luz? estado = s <= 5
        ? c.erro
        : s <= 10
        ? c.aviso
        : null;
    final fundo = estado?.suave ?? c.superficie;
    final tinta = estado?.tinta ?? c.texto;
    final borda = estado?.cor ?? c.linha;
    final escala = widget.grande ? 2.0 : 1.0;

    final pilula = AnimatedContainer(
      duration: Movimento.base,
      curve: Movimento.padrao,
      height: 44 * escala,
      padding: EdgeInsets.symmetric(horizontal: Espaco.e4 * escala),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(Raio.pill),
        border: Border.all(
          color: c.ehDia ? c.contorno : borda,
          width: estado == null ? c.bordaControle : 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.pausado ? Symbols.pause_rounded : Symbols.timer_rounded,
            size: 22 * escala,
            color: estado?.tinta ?? c.texto2,
          ),
          SizedBox(width: Espaco.e2 * escala),
          FadeTransition(
            opacity: Tween(begin: 1.0, end: .5).animate(_piscar),
            child: DigitosHud(
              formatarTempo(s),
              estilo: context.estilos.hud.copyWith(
                color: tinta,
                fontSize: 20 * escala,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: widget.pausado
          ? 'Tempo pausado em ${s ~/ 60} minutos e ${s % 60} segundos'
          : 'Faltam ${s ~/ 60} minutos e ${s % 60} segundos',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _pulso,
        builder: (_, filho) => Transform.scale(
          scale: 1 + .06 * Curves.easeOut.transform(1 - _pulso.value),
          child: filho,
        ),
        child: pilula,
      ),
    );
  }
}
