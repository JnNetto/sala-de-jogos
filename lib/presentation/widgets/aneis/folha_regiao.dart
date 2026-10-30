import 'package:flutter/material.dart';

import '../../../core/enums/aneis_regiao.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/aneis_anel_publico.dart';
import '../../../data/models/aneis_carta_tabuleiro.dart';
import '../../../data/models/aneis_regra_revelada.dart';
import '../sala/tela_da_sala.dart';
import 'cores_dos_aneis.dart';
import 'tabuleiro_aneis.dart';

/// A folha de uma região do tabuleiro: de quais anéis ela é, o que isso
/// quer dizer, a regra secreta (para quem pode ver) e as cartas que já
/// estão lá.
Future<void> mostrarCartasDaRegiao(
  BuildContext context, {
  required AneisRegiao regiao,
  required List<AneisCartaTabuleiro> cartas,
  List<AneisAnelPublico> aneis = const [],
  AneisRegraRevelada? regraSecreta,
}) {
  AneisAnelPublico? anel;
  if (regiao.ehAnelExclusivo) {
    for (final item in aneis) {
      if (item.id == regiao.id) anel = item;
    }
  }
  final tema = temaComLuz(Theme.of(context), context.cores.luz(Matiz.ceu));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => Theme(
      data: tema,
      child: _Folha(
        regiao: regiao,
        anel: anel,
        regraSecreta: regraSecreta,
        textos: [
          for (final carta in cartas)
            if (carta.regiao == regiao) carta.texto,
        ],
      ),
    ),
  );
}

class _Folha extends StatelessWidget {
  const _Folha({
    required this.regiao,
    required this.anel,
    required this.regraSecreta,
    required this.textos,
  });

  final AneisRegiao regiao;
  final AneisAnelPublico? anel;
  final AneisRegraRevelada? regraSecreta;
  final List<String> textos;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luzDaRegiao(regiao);
    final aneisDaRegiao = [
      if (regiao.noPalavra) c.anelPalavra,
      if (regiao.noAtributo) c.anelAtributo,
      if (regiao.noContexto) c.anelContexto,
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .7,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Espaco.margemTela,
          0,
          Espaco.margemTela,
          Espaco.e6 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Aneis(luzes: aneisDaRegiao),
                const SizedBox(width: Espaco.e3),
                Expanded(
                  child: Text(
                    anel?.nome ??
                        (regiao == AneisRegiao.nenhum
                            ? 'Fora dos anéis'
                            : regiao.rotulo),
                    style: texto.headlineSmall,
                  ),
                ),
                Text(
                  '${textos.length}',
                  style: context.estilos.hud.copyWith(color: luz.tinta),
                ),
              ],
            ),
            const SizedBox(height: Espaco.e2),
            Text(
              _descricao(regiao, anel),
              style: texto.bodyLarge?.copyWith(color: c.texto2),
            ),
            if (regraSecreta != null) ...[
              const SizedBox(height: Espaco.e4),
              Container(
                padding: const EdgeInsets.all(Espaco.e4),
                decoration: BoxDecoration(
                  color: luz.suave,
                  borderRadius: BorderRadius.circular(Raio.lg),
                  border: c.ehDia
                      ? Border.all(color: c.contorno, width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REGRA SECRETA',
                      style: texto.labelSmall?.copyWith(color: luz.tinta),
                    ),
                    const SizedBox(height: Espaco.e1),
                    Text(regraSecreta!.texto, style: texto.titleLarge),
                  ],
                ),
              ),
            ],
            const SizedBox(height: Espaco.e5),
            if (textos.isEmpty)
              Text(
                'Nenhuma carta aqui ainda.',
                style: texto.bodyMedium?.copyWith(color: c.texto3),
              )
            else
              Wrap(
                spacing: Espaco.e2,
                runSpacing: Espaco.e2,
                children: [
                  for (final t in textos)
                    CartaNoTabuleiro(
                      t,
                      luz: regiao == AneisRegiao.nenhum ? null : luz,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Os anéis da região em miniatura, um por cima do outro.
class _Aneis extends StatelessWidget {
  const _Aneis({required this.luzes});

  final List<Luz> luzes;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    if (luzes.isEmpty) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.texto3, width: 2.5),
        ),
      );
    }
    return SizedBox(
      width: 22.0 + (luzes.length - 1) * 12,
      height: 22,
      child: Stack(
        children: [
          for (final (i, luz) in luzes.indexed)
            Positioned(
              left: i * 12.0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: luz.cor.withValues(alpha: .2),
                  border: Border.all(
                    color: c.ehDia ? luz.tinta : luz.cor,
                    width: 2.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _descricao(AneisRegiao regiao, AneisAnelPublico? anel) {
  if (regiao.ehAnelExclusivo) {
    final subtitulo = anel?.subtitulo.trim() ?? '';
    if (subtitulo.isNotEmpty) return subtitulo;
  }
  return switch (regiao) {
    AneisRegiao.palavra =>
      'Cumpre só a regra da Letra: como a palavra se escreve ou soa.',
    AneisRegiao.atributo =>
      'Cumpre só a regra do Jeito: o que a coisa é ou tem.',
    AneisRegiao.contexto =>
      'Cumpre só a regra do Lugar: onde aparece ou para que se usa.',
    AneisRegiao.palavraAtributo => 'Cumpre Letra e Jeito, mas não Lugar.',
    AneisRegiao.palavraContexto => 'Cumpre Letra e Lugar, mas não Jeito.',
    AneisRegiao.atributoContexto => 'Cumpre Jeito e Lugar, mas não Letra.',
    AneisRegiao.todos => 'Cumpre as três regras secretas ao mesmo tempo.',
    AneisRegiao.nenhum => 'Não cumpre nenhuma das três regras.',
  };
}
