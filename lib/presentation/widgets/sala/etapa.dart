import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import 'botao_sala.dart';
import 'jogador_sala.dart';

/// Centro de tela para quando o celular muda de mão (no modo de um celular
/// só) ou quando se espera alguém (no online).
class PasseOCelular extends StatelessWidget {
  const PasseOCelular({
    super.key,
    required this.titulo,
    required this.texto,
    this.nome,
    this.indice = 0,
    this.icone,
    this.acao,
    this.aoContinuar,
    this.extra,
    this.bolinhas = true,
    this.matiz = Matiz.lampada,
  });

  /// A luz do jogo (no poço, nas bolinhas e no botão).
  final Matiz matiz;

  final String titulo, texto;

  /// Com nome, o avatar da pessoa; sem, o [icone] num poço.
  final String? nome;
  final int indice;
  final IconData? icone;

  /// Sem ação, é uma espera (as bolinhas correm).
  final String? acao;
  final VoidCallback? aoContinuar;
  final Widget? extra;

  /// Numa espera, as bolinhas correndo (some quando o [extra] já mostra o
  /// progresso).
  final bool bolinhas;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final luz = c.luz(matiz);
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Espaco.margemTela,
                  vertical: Espaco.e4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (nome != null)
                      AvatarJogador(
                        nome: nome!,
                        indice: indice,
                        tamanho: 88,
                        brilho: true,
                      )
                    else
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: luz.suave,
                          borderRadius: BorderRadius.circular(Raio.xl),
                          border: c.ehDia
                              ? Border.all(color: c.contorno, width: 2)
                              : null,
                          boxShadow: c.brilho(luz.cor, alpha: .35, blur: 40),
                        ),
                        child: Icon(
                          icone ?? Symbols.smartphone_rounded,
                          fill: 1,
                          size: 44,
                          color: luz.tinta,
                        ),
                      ),
                    const SizedBox(height: Espaco.e6),
                    Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: t.headlineLarge,
                    ),
                    const SizedBox(height: Espaco.e2),
                    Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: t.bodyLarge?.copyWith(color: c.texto2),
                    ),
                    if (extra != null) ...[
                      const SizedBox(height: Espaco.e6),
                      extra!,
                    ],
                    if (acao == null && bolinhas) ...[
                      const SizedBox(height: Espaco.e6),
                      BolinhasCarregando(cor: luz.cor),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (acao != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Espaco.margemTela,
                Espaco.e3,
                Espaco.margemTela,
                Espaco.e4,
              ),
              child: BotaoSala(
                rotulo: acao!,
                icone: Symbols.arrow_forward_rounded,
                iconeNoFim: true,
                luz: luz,
                bloco: true,
                onPressed: aoContinuar,
              ),
            ),
        ],
      ),
    );
  }
}

/// Uma etapa com conteúdo rolável e o botão principal preso embaixo.
class Etapa extends StatelessWidget {
  const Etapa({super.key, required this.children, this.rodape});

  final List<Widget> children;
  final Widget? rodape;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Espaco.margemTela,
                Espaco.e4,
                Espaco.margemTela,
                Espaco.e6,
              ),
              children: children,
            ),
          ),
          if (rodape != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Espaco.margemTela,
                Espaco.e3,
                Espaco.margemTela,
                Espaco.e4,
              ),
              child: rodape,
            ),
        ],
      ),
    );
  }
}

/// O título e a explicação no topo de uma etapa.
class CabecaDaEtapa extends StatelessWidget {
  const CabecaDaEtapa({
    super.key,
    required this.titulo,
    required this.texto,
    this.nome,
    this.indice = 0,
  });

  final String titulo, texto;
  final String? nome;
  final int indice;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final cabeca = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: t.headlineLarge),
        const SizedBox(height: Espaco.e1),
        Text(texto, style: t.bodyLarge?.copyWith(color: c.texto2)),
      ],
    );
    if (nome == null) return cabeca;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, right: Espaco.e3),
          child: AvatarJogador(nome: nome!, indice: indice, tamanho: 44),
        ),
        Expanded(child: cabeca),
      ],
    );
  }
}
