import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import 'pressionavel.dart';

/// A roda de cores dos jogadores, na ordem em que entram na mesa. A mesma
/// cor acompanha a pessoa na revelação, na votação e no resultado.
const _rodaDeJogadores = [
  Matiz.violeta,
  Matiz.rosa,
  Matiz.menta,
  Matiz.brasa,
  Matiz.lampada,
  Matiz.luar,
  Matiz.ceu,
];

Matiz matizDoJogador(int indice) =>
    _rodaDeJogadores[indice % _rodaDeJogadores.length];

/// Quadradinho com a inicial em pixel sobre a cor do jogador.
class AvatarJogador extends StatelessWidget {
  const AvatarJogador({
    super.key,
    required this.nome,
    required this.indice,
    this.tamanho = 36,
    this.brilho = false,
  });

  final String nome;
  final int indice;
  final double tamanho;

  /// Acende o halo (selecionado na votação, vez de jogar).
  final bool brilho;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(matizDoJogador(indice));
    final inicial = nome.trim().isEmpty
        ? '?'
        : nome.trim().characters.first.toUpperCase();
    return AnimatedContainer(
      duration: Movimento.base,
      curve: Movimento.padrao,
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: luz.cor,
        borderRadius: BorderRadius.circular(tamanho >= 56 ? Raio.lg : Raio.sm),
        border: c.ehDia ? Border.all(color: c.contorno, width: 2) : null,
        boxShadow: brilho ? c.brilho(luz.cor, alpha: .6, blur: 18) : const [],
      ),
      child: Text(
        inicial,
        style: TextStyle(
          fontFamily: 'PixelifySans',
          fontSize: tamanho * .46,
          height: 1,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation.weight(700)],
          color: c.sobreCor,
        ),
      ),
    );
  }
}

/// Chip de um jogador na montagem da mesa: avatar, nome e o × de remover.
class ChipJogador extends StatelessWidget {
  const ChipJogador({
    super.key,
    required this.nome,
    required this.indice,
    this.aoRemover,
    this.elevado = false,
  });

  final String nome;
  final int indice;
  final VoidCallback? aoRemover;

  /// Sendo arrastado: um pouco maior e flutuando.
  final bool elevado;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: elevado ? c.superficieElevada : c.superficie,
        borderRadius: BorderRadius.circular(Raio.md),
        border: Border.all(
          color: c.ehDia ? c.contorno : c.linha,
          width: c.bordaControle,
        ),
        boxShadow: elevado ? c.sombraFlutuante : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarJogador(nome: nome, indice: indice),
          const SizedBox(width: Espaco.e3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (aoRemover != null)
            Semantics(
              button: true,
              label: 'Remover $nome',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: aoRemover,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Symbols.close_rounded, size: 20, color: c.texto3),
                ),
              ),
            )
          else
            const SizedBox(width: Espaco.e4),
        ],
      ),
    );
  }
}

/// Linha grande (64) de um jogador para escolher: votação, resultado.
class LinhaJogador extends StatelessWidget {
  const LinhaJogador({
    super.key,
    required this.nome,
    required this.indice,
    this.selecionado = false,
    this.onTap,
    this.direita,
    this.apagado = false,
    this.apoio,
  });

  final String nome;
  final int indice;
  final bool selecionado;
  final VoidCallback? onTap;

  /// Etiqueta ou ícone à direita.
  final Widget? direita;

  /// Fora da mesa (eliminado): fica mais apagado.
  final bool apagado;

  /// Uma linha embaixo do nome, como a resposta do jogador.
  final String? apoio;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final marca = Theme.of(context).colorScheme.primary;
    final conteudo = AnimatedContainer(
      duration: Movimento.base,
      curve: Movimento.padrao,
      constraints: const BoxConstraints(minHeight: 64),
      padding: EdgeInsets.symmetric(
        horizontal: Espaco.e3,
        vertical: apoio == null ? 0 : Espaco.e3,
      ),
      decoration: BoxDecoration(
        color: selecionado
            ? Color.lerp(c.superficie, marca, c.ehDia ? .14 : .18)
            : c.superficie,
        borderRadius: BorderRadius.circular(Raio.lg),
        border: Border.all(
          color: selecionado ? (c.ehDia ? c.contorno : marca) : c.linha,
          width: selecionado ? 2 : c.bordaControle,
        ),
        boxShadow: selecionado ? c.brilho(marca, alpha: .3, blur: 22) : null,
      ),
      child: Row(
        children: [
          AvatarJogador(
            nome: nome,
            indice: indice,
            tamanho: 40,
            brilho: selecionado,
          ),
          const SizedBox(width: Espaco.e4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: apagado ? c.texto3 : null,
                    decoration: apagado ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (apoio != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    apoio!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: apagado ? c.texto3 : c.texto2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?direita,
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      selected: selecionado,
      child: onTap == null
          ? conteudo
          : Pressionavel(onTap: onTap, escala: .98, child: conteudo),
    );
  }
}
