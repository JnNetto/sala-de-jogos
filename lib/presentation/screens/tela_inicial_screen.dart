import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/sala_tokens.dart';
import '../navegacao.dart';
import '../widgets/sala/alternar_tema.dart';
import '../widgets/sala/botao_sala.dart';
import '../widgets/sala/cena_sala.dart';
import '../widgets/sala/marca.dart';
import '../widgets/sala/varal.dart';
import 'configuracoes_app_screen.dart';
import 'jogos_screen.dart';

/// A porta da sala: marca, nome e o menu (Jogar, Configurações, Sair).
/// "Jogar" leva à estante de jogos.
class TelaInicialScreen extends StatefulWidget {
  const TelaInicialScreen({super.key});

  @override
  State<TelaInicialScreen> createState() => _TelaInicialScreenState();
}

class _TelaInicialScreenState extends State<TelaInicialScreen>
    with SingleTickerProviderStateMixin {
  /// O menu entra em cascata depois que a splash cruza para cá.
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  /// Sair do app só existe no Android: no iOS e na web quem fecha é o sistema.
  static bool get _podeSair =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entrada.isDismissed) {
      Movimento.reduzido(context) ? _entrada.value = 1 : _entrada.forward();
    }
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  Widget _entrando(int i, Widget filho) {
    final fatia = CurvedAnimation(
      parent: _entrada,
      curve: Interval(
        i * .15,
        (i * .15 + .55).clamp(0, 1),
        curve: Movimento.entrada,
      ),
    );
    return AnimatedBuilder(
      animation: fatia,
      builder: (_, f) => Opacity(
        opacity: fatia.value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - fatia.value)),
          child: f,
        ),
      ),
      child: filho,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final topo = MediaQuery.paddingOf(context).top;
    final base = MediaQuery.paddingOf(context).bottom;

    final menu = [
      BotaoSala(
        rotulo: 'Jogar',
        icone: Symbols.play_arrow_rounded,
        bloco: true,
        onPressed: () => Navigator.of(
          context,
        ).push(rotaDaSala(const JogosScreen(), nome: rotaJogos)),
      ),
      BotaoSala(
        rotulo: 'Configurações',
        icone: Symbols.settings_rounded,
        variante: VarianteBotao.secundario,
        bloco: true,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ConfiguracoesAppScreen(),
          ),
        ),
      ),
      if (_podeSair)
        BotaoSala(
          rotulo: 'Sair',
          icone: Symbols.logout_rounded,
          variante: VarianteBotao.fantasma,
          bloco: true,
          onPressed: () => SystemNavigator.pop(),
        ),
    ];

    return Scaffold(
      body: CenaSala(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Espaco.larguraMax),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      Espaco.margemTela,
                      topo + Varal.altura + Espaco.e1,
                      Espaco.margemTela,
                      base + Espaco.e4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: AlternarTema(),
                        ),
                        const Spacer(flex: 2),
                        const Center(child: Marca(tamanho: 120)),
                        const SizedBox(height: Espaco.e6),
                        // Títulos display param de crescer acima de 1,3×.
                        MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.3,
                          child: Semantics(
                            header: true,
                            child: Text(
                              AppConstants.appName,
                              textAlign: TextAlign.center,
                              style: texto.displayLarge,
                            ),
                          ),
                        ),
                        const SizedBox(height: Espaco.e2),
                        Text(
                          'A sala está aberta. Chame a galera.',
                          textAlign: TextAlign.center,
                          style: texto.bodyLarge?.copyWith(color: c.texto2),
                        ),
                        const Spacer(flex: 3),
                        const SizedBox(height: Espaco.e8),
                        for (final (i, botao) in menu.indexed) ...[
                          if (i > 0) const SizedBox(height: Espaco.e3),
                          _entrando(i, botao),
                        ],
                        const SizedBox(height: Espaco.e8),
                        Text(
                          'V${AppConstants.appVersion}',
                          textAlign: TextAlign.center,
                          style: texto.labelSmall?.copyWith(color: c.texto3),
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
    );
  }
}
