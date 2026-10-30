import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import 'aviso.dart';

/// Abre uma página no navegador.
Future<void> abrirPagina(BuildContext context, String url) async {
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);
  if (!ok && context.mounted) {
    mostrarAviso(context, 'Não deu para abrir o navegador.');
  }
}

/// "Política de privacidade", como link de texto.
class LinkPrivacidade extends StatelessWidget {
  const LinkPrivacidade({super.key, this.prefixo});

  /// Texto antes do link ("Ao entrar, você aceita a").
  final String? prefixo;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    return Semantics(
      link: true,
      label: '${prefixo ?? ''} Política de privacidade'.trim(),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Raio.sm),
        onTap: () => abrirPagina(context, AppConstants.urlPrivacidade),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Espaco.e2),
          child: Text.rich(
            TextSpan(
              children: [
                if (prefixo != null) TextSpan(text: '$prefixo '),
                TextSpan(
                  text: 'Política de privacidade',
                  style: TextStyle(
                    color: c.primariaTinta,
                    decoration: TextDecoration.underline,
                    decorationColor: c.primariaTinta,
                  ),
                ),
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Icon(Symbols.open_in_new_rounded, size: 14),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: c.texto2),
          ),
        ),
      ),
    );
  }
}
