import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/sala_tokens.dart';
import '../widgets/sala/marca.dart';
import '../widgets/sala/cena_sala.dart';
import 'tela_inicial_screen.dart';

/// A sala acendendo: o varal liga da esquerda para a direita, a janela
/// aparece com os vidros acendendo um a um e o nome sobe. Depois cruza para
/// a home com o varal no mesmo lugar, como se a luz continuasse acesa.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Linha do tempo da coreografia, em milissegundos. Sem pressa: a sala
  /// vai acendendo junto com o varal, nada estala.
  static const _total = 2300;
  static const _marcaEm = 400, _marcaDura = 900;
  static const _vidroEm = 900, _vidroPasso = 220, _vidroDura = 400;
  static const _nomeEm = 1500, _nomeDura = 700;

  /// Quando ir para a tela inicial: o varal do palco termina de acender em
  /// ~2,4 s; um respiro depois.
  static const _saida = Duration(milliseconds: 2700);

  late final _relogio = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _total),
  );

  late final _marcaEscala = _trecho(_marcaEm, _marcaDura, Movimento.padrao);
  late final _marcaOpacidade = _trecho(_marcaEm, 600, Curves.easeOut);
  late final _nome = _trecho(_nomeEm, _nomeDura, Movimento.entrada);

  Timer? _ir;

  Animation<double> _trecho(int inicio, int duracao, Curve curva) =>
      CurvedAnimation(
        parent: _relogio,
        curve: Interval(
          inicio / _total,
          ((inicio + duracao) / _total).clamp(0, 1),
          curve: curva,
        ),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ir != null) return;
    if (Movimento.reduzido(context)) {
      _relogio.value = 1;
    } else {
      _relogio.forward();
    }
    _ir = Timer(_saida, _irParaHome);
  }

  /// A marca e o nome saem primeiro; depois a tela inicial surge por cima.
  /// Céu e varal são iguais nas duas e ficam parados no lugar.
  bool _saindo = false;

  Future<void> _irParaHome() async {
    if (!mounted) return;
    setState(() => _saindo = true);
    await Future<void>.delayed(Movimento.base);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(rotaDaSala(const TelaInicialScreen()));
  }

  @override
  void dispose() {
    _ir?.cancel();
    _relogio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;

    return Scaffold(
      // O varal que acende aqui é o do PalcoDaSala: ele segue aceso pelo
      // resto do app.
      body: CenaSala(
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(0, -.12),
              child: AnimatedOpacity(
                opacity: _saindo ? 0 : 1,
                duration: Movimento.base,
                curve: Movimento.saida,
                child: Semantics(
                  label: AppConstants.appName,
                  excludeSemantics: true,
                  child: AnimatedBuilder(
                    animation: _relogio,
                    builder: (context, _) {
                      final ms = _relogio.value * _total;
                      // Cada vidro esquenta em _vidroDura, um depois do outro.
                      var vidros = 0.0;
                      for (var i = 0; i < 4; i++) {
                        vidros += Curves.easeInOut.transform(
                          ((ms - _vidroEm - i * _vidroPasso) / _vidroDura)
                              .clamp(0.0, 1.0),
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: _marcaOpacidade.value,
                            child: Transform.scale(
                              scale: .92 + .08 * _marcaEscala.value,
                              child: Marca(tamanho: 120, vidrosAcesos: vidros),
                            ),
                          ),
                          const SizedBox(height: Espaco.e6),
                          Opacity(
                            opacity: _nome.value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - _nome.value)),
                              child: Text(
                                AppConstants.appName,
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(color: c.texto),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
