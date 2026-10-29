import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/sala_tokens.dart';
import '../providers/theme_provider.dart';
import '../widgets/sala/alternar_tema.dart';
import '../widgets/sala/cartao_config.dart';
import '../widgets/sala/marca.dart';
import '../widgets/sala/tela_da_sala.dart';

/// Configurações do app (não de uma partida). Hoje tem só o tema; é aqui que
/// entram música, idioma e vibração quando chegarem.
class ConfiguracoesAppScreen extends StatelessWidget {
  const ConfiguracoesAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final noite = context.watch<ThemeProvider>().isDarkMode;

    Widget secao(String rotulo) => Padding(
      padding: const EdgeInsets.only(bottom: Espaco.e3),
      child: Semantics(
        header: true,
        child: Text(
          rotulo,
          style: texto.labelMedium?.copyWith(color: c.texto3),
        ),
      ),
    );

    return TelaDaSala(
      titulo: 'Configurações',
      corpo: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Espaco.larguraMax),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Espaco.margemTela,
              Espaco.e4,
              Espaco.margemTela,
              Espaco.e12,
            ),
            children: [
              secao('APARÊNCIA'),
              CartaoConfig(
                icone: noite
                    ? Symbols.dark_mode_rounded
                    : Symbols.light_mode_rounded,
                titulo: noite ? 'Tema Noite' : 'Tema Dia',
                subtitulo: noite
                    ? 'Céu escuro e luzes acesas.'
                    : 'Papel creme e traço de tinta.',
                controle: const AlternarTema(),
                controleNaLinha: true,
              ),
              const SizedBox(height: Espaco.e8),
              secao('SOBRE'),
              _Sobre(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sobre extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Espaco.e5),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(Raio.xl),
        border: Border.all(
          color: c.ehDia ? c.contorno : c.linha,
          width: c.bordaControle,
        ),
        boxShadow: c.sombraCard,
      ),
      child: Row(
        children: [
          const Marca(tamanho: 48),
          const SizedBox(width: Espaco.e4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appName, style: texto.titleLarge),
                const SizedBox(height: Espaco.e1),
                Text(
                  'Versão ${AppConstants.appVersion}',
                  style: texto.bodyMedium?.copyWith(color: c.texto2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
