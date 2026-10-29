import 'package:flutter/material.dart';

/// A troca de tela da Sala de Jogos, em fade-through: a tela que sai some
/// primeiro, e a que entra surge depois, deslizando um pouquinho de [de].
///
/// As telas são transparentes sobre o céu do palco, então as duas nunca
/// aparecem inteiras ao mesmo tempo: no meio da troca só o céu e o varal
/// ficam à vista.
Widget transicaoDaSala(
  Animation<double> entrando,
  Animation<double> saindo,
  Widget filho, {
  Offset de = const Offset(0, .025),
}) {
  final entra = CurvedAnimation(
    parent: entrando,
    curve: const Interval(.4, 1, curve: Curves.easeOutCubic),
    reverseCurve: const Interval(.4, 1, curve: Curves.easeInCubic),
  );
  // Quando outra tela entra por cima, esta sai primeiro.
  final sai = CurvedAnimation(
    parent: saindo,
    curve: const Interval(0, .4, curve: Curves.easeInCubic),
    reverseCurve: const Interval(0, .4, curve: Curves.easeOutCubic),
  );
  return FadeTransition(
    opacity: ReverseAnimation(sai),
    child: FadeTransition(
      opacity: entra,
      child: SlideTransition(
        position: Tween(begin: de, end: Offset.zero).animate(entra),
        child: filho,
      ),
    ),
  );
}

/// [transicaoDaSala] na horizontal, para as rotas do Material
/// (`MaterialPageRoute`) seguirem os passos de um fluxo.
class TransicaoDaSala extends PageTransitionsBuilder {
  const TransicaoDaSala();

  /// Quando uma rota do Material entra por cima de uma rota com transição
  /// própria (a `rotaDaSala`), o Flutter congela a saída da de baixo e usa
  /// esta no lugar. Sem ela, a tela de baixo ficaria inteira até o fim.
  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      (context, animation, secondaryAnimation, allowSnapshotting, child) =>
          FadeTransition(
            opacity: ReverseAnimation(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: const Interval(0, .4, curve: Curves.easeInCubic),
                reverseCurve: const Interval(0, .4, curve: Curves.easeOutCubic),
              ),
            ),
            child: child,
          );

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => transicaoDaSala(
    animation,
    secondaryAnimation,
    child,
    de: const Offset(.06, 0),
  );
}
