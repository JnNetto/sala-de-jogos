import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import 'botao_sala.dart';

/// Seletor de mais e menos para números pequenos. O número antigo sai para
/// cima (ou para baixo, ao diminuir) e o novo entra do lado oposto.
class Contador extends StatefulWidget {
  const Contador({
    super.key,
    required this.valor,
    required this.minimo,
    required this.maximo,
    required this.aoMudar,
    this.rotulo = 'valor',
  });

  final int valor, minimo, maximo;
  final ValueChanged<int> aoMudar;

  /// Para o leitor de tela: "Diminuir espiões".
  final String rotulo;

  @override
  State<Contador> createState() => _ContadorState();
}

class _ContadorState extends State<Contador> {
  bool _subiu = true;

  void _mudar(int delta) {
    final novo = widget.valor + delta;
    if (novo < widget.minimo || novo > widget.maximo) return;
    HapticFeedback.lightImpact();
    setState(() => _subiu = delta > 0);
    widget.aoMudar(novo);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final estilo = Theme.of(context).textTheme.displaySmall;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.superficieFunda,
        borderRadius: BorderRadius.circular(Raio.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BotaoIcone(
            icone: Symbols.remove_rounded,
            rotulo: 'Diminuir ${widget.rotulo}',
            onPressed: widget.valor > widget.minimo ? () => _mudar(-1) : null,
          ),
          SizedBox(
            width: 64,
            height: 48,
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: Movimento.d(context, Movimento.base),
                switchInCurve: Movimento.pulo,
                switchOutCurve: Movimento.saida,
                transitionBuilder: (filho, animacao) {
                  final entrando = filho.key == ValueKey(widget.valor);
                  final sentido = (_subiu ? 1.0 : -1.0) * (entrando ? 1 : -1);
                  return SlideTransition(
                    position: Tween(
                      begin: Offset(0, .8 * sentido),
                      end: Offset.zero,
                    ).animate(animacao),
                    child: FadeTransition(opacity: animacao, child: filho),
                  );
                },
                child: Center(
                  key: ValueKey(widget.valor),
                  child: Text(
                    '${widget.valor}',
                    style: estilo?.copyWith(height: 1),
                  ),
                ),
              ),
            ),
          ),
          BotaoIcone(
            icone: Symbols.add_rounded,
            rotulo: 'Aumentar ${widget.rotulo}',
            onPressed: widget.valor < widget.maximo ? () => _mudar(1) : null,
          ),
        ],
      ),
    );
  }
}
