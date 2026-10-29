import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/sala_tokens.dart';

/// A física do toque de tudo que é tocável: afunda ao pressionar e volta com
/// um pulinho. A ação dispara no "up", não no fim da animação.
class Pressionavel extends StatefulWidget {
  const Pressionavel({
    super.key,
    required this.child,
    this.onTap,
    this.escala = .97,
    this.descida = 0,
    this.haptico = true,
    this.aoMudar,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// 0,97 em cards; 0,985 com descida de 3 px em botões.
  final double escala, descida;
  final bool haptico;

  /// Avisa o pai quando o estado pressionado muda, para ele acender detalhes.
  final ValueChanged<bool>? aoMudar;

  @override
  State<Pressionavel> createState() => _PressionavelState();
}

class _PressionavelState extends State<Pressionavel> {
  bool _baixo = false;

  void _set(bool v) {
    if (_baixo == v) return;
    setState(() => _baixo = v);
    widget.aoMudar?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final ativo = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: ativo
          ? (_) {
              _set(true);
              if (widget.haptico) HapticFeedback.lightImpact();
            }
          : null,
      onTapUp: ativo
          ? (_) {
              _set(false);
              widget.onTap!();
            }
          : null,
      onTapCancel: ativo ? () => _set(false) : null,
      child: AnimatedContainer(
        duration: _baixo ? Movimento.instante : Movimento.rapida,
        curve: _baixo ? Movimento.padrao : Movimento.pulo,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(0, _baixo ? widget.descida : 0, 0, 1)
          ..scaleByDouble(
            _baixo ? widget.escala : 1,
            _baixo ? widget.escala : 1,
            1,
            1,
          ),
        child: widget.child,
      ),
    );
  }
}
