import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';

/// Pílula que diz o papel: ícone preenchido e texto em pixel na cor do
/// papel. Nunca só a cor.
class SeloPapel extends StatelessWidget {
  const SeloPapel({
    super.key,
    required this.texto,
    required this.icone,
    required this.luz,
    this.compacto = false,
  });

  /// Já em CAIXA ALTA: "VOCÊ É O ESPIÃO".
  final String texto;
  final IconData icone;
  final Luz luz;

  /// A etiqueta pequena das linhas de resultado.
  final bool compacto;

  factory SeloPapel.espiao(
    BuildContext context, {
    String texto = 'ESPIÃO',
    bool compacto = false,
  }) => SeloPapel(
    texto: texto,
    icone: Symbols.visibility_off_rounded,
    luz: context.cores.papelEspiao,
    compacto: compacto,
  );

  factory SeloPapel.civil(
    BuildContext context, {
    String texto = 'CIVIL',
    bool compacto = false,
  }) => SeloPapel(
    texto: texto,
    icone: Symbols.person_rounded,
    luz: context.cores.papelCivil,
    compacto: compacto,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final estilo = compacto
        ? Theme.of(context).textTheme.labelSmall
        : Theme.of(context).textTheme.labelMedium;
    return Container(
      height: compacto ? 28 : 40,
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? Espaco.e2 : Espaco.e4,
      ),
      decoration: BoxDecoration(
        color: luz.suave,
        borderRadius: BorderRadius.circular(compacto ? Raio.xs : Raio.pill),
        border: compacto && !c.ehDia
            ? null
            : Border.all(color: c.ehDia ? c.contorno : luz.cor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, fill: 1, size: compacto ? 14 : 20, color: luz.tinta),
          SizedBox(width: compacto ? Espaco.e1 : Espaco.e2),
          Text(texto, style: estilo?.copyWith(color: luz.tinta, height: 1)),
        ],
      ),
    );
  }
}

/// O bloco da palavra secreta: Nunito Black em CAIXA ALTA (a pixel
/// confundiria letras), reduzindo para caber e nunca quebrando no meio.
class BlocoPalavra extends StatelessWidget {
  const BlocoPalavra({super.key, required this.palavra, required this.luz});

  final String palavra;
  final Luz luz;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Espaco.e5,
        vertical: Espaco.e4,
      ),
      decoration: BoxDecoration(
        color: luz.suave,
        borderRadius: BorderRadius.circular(Raio.lg),
        border: Border.all(color: c.ehDia ? c.contorno : luz.cor, width: 3),
        boxShadow: c.brilho(luz.cor, alpha: .32, blur: 32),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          palavra.toUpperCase(),
          maxLines: 1,
          style: context.estilos.revelacao.copyWith(color: c.texto),
        ),
      ),
    );
  }
}
