import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/resistencia_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import '../sala/fim_de_jogo.dart';
import '../sala/janela.dart';
import '../sala/jogador_sala.dart';
import '../sala/pressionavel.dart';
import '../sala/selo_papel.dart';

export '../sala/etapa.dart';

const matizExpedicao = Matiz.brasa;

extension CoresDaExpedicao on SalaCores {
  Luz get explorador => luz(Matiz.menta);
  Luz get saqueador => luz(Matiz.carmim);
}

/// O selo do papel: Explorador ou Saqueador.
Widget seloDoPapel(
  BuildContext context, {
  required bool saqueador,
  String? texto,
  bool compacto = false,
}) {
  final c = context.cores;
  return SeloPapel(
    texto: texto ?? (saqueador ? 'SAQUEADOR' : 'EXPLORADOR'),
    icone: saqueador ? Symbols.skull_rounded : Symbols.explore_rounded,
    luz: saqueador ? c.saqueador : c.explorador,
    compacto: compacto,
  );
}

// ─── A trilha das câmaras e as tochas ─────────────────────────────────────

/// As cinco câmaras da expedição, ligadas por uma trilha: as exploradas
/// com o tesouro, as que caíram na armadilha, a atual acesa e, em cada uma
/// ainda por vir, quantas pessoas entram.
class TrilhaDasCamaras extends StatelessWidget {
  const TrilhaDasCamaras({
    super.key,
    required this.resultados,
    required this.tamanhos,
    required this.atual,
    required this.jogadores,
  });

  final List<bool> resultados;
  final List<int> tamanhos;

  /// A câmara da vez (1 a 5).
  final int atual;
  final int jogadores;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Row(
      children: [
        for (var i = 0; i < ResistenciaConstants.totalMissoes; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i < resultados.length + 1 && i <= resultados.length
                      ? c.linhaForte.withValues(alpha: .7)
                      : c.linha,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          _Camara(
            numero: i + 1,
            tamanho: i < tamanhos.length ? tamanhos[i] : 0,
            resultado: i < resultados.length ? resultados[i] : null,
            atual: i + 1 == atual && i >= resultados.length,
            duasArmadilhas:
                ResistenciaConstants.fracassosNecessariosParaFalhar(
                  missao: i + 1,
                  quantidadeJogadores: jogadores,
                ) >
                1,
          ),
        ],
      ],
    );
  }
}

class _Camara extends StatelessWidget {
  const _Camara({
    required this.numero,
    required this.tamanho,
    required this.resultado,
    required this.atual,
    required this.duasArmadilhas,
  });

  final int numero, tamanho;
  final bool? resultado;
  final bool atual, duasArmadilhas;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(matizExpedicao);
    final feita = resultado != null;
    final cor = resultado == true
        ? c.explorador
        : resultado == false
        ? c.saqueador
        : luz;
    final rotulo = switch (resultado) {
      true => 'Câmara $numero: explorada',
      false => 'Câmara $numero: armadilha',
      null => 'Câmara $numero: $tamanho pessoas',
    };

    return Semantics(
      label: rotulo,
      excludeSemantics: true,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: Movimento.media,
              curve: Movimento.padrao,
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: feita || atual ? cor.suave : c.superficieFunda,
                shape: BoxShape.circle,
                border: Border.all(
                  color: feita || atual
                      ? (c.ehDia ? c.contorno : cor.cor)
                      : (c.ehDia ? c.contorno : c.linha),
                  width: atual ? 2.5 : c.bordaControle,
                ),
                boxShadow: atual
                    ? c.brilho(cor.cor, alpha: .5, blur: 20)
                    : null,
              ),
              child: feita
                  ? Icon(
                      resultado!
                          ? Symbols.diamond_rounded
                          : Symbols.dangerous_rounded,
                      fill: 1,
                      size: 22,
                      color: cor.tinta,
                    )
                  : Text(
                      '$tamanho',
                      style: context.estilos.hud.copyWith(
                        fontSize: 18,
                        height: 1,
                        color: atual ? cor.tinta : c.texto3,
                      ),
                    ),
            ),
            if (duasArmadilhas && !feita)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: c.saqueador.cor,
                    borderRadius: BorderRadius.circular(Raio.xs),
                  ),
                  child: Text(
                    '2×',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: c.sobreCor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// As tochas da expedição: cada equipe recusada apaga uma, na partida
/// inteira. Quando todas se apagam, os saqueadores vencem.
class Tochas extends StatelessWidget {
  const Tochas({super.key, required this.apagadas});

  final int apagadas;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(matizExpedicao);
    final total = ResistenciaConstants.maxRejeicoes;
    final acesas = (total - apagadas).clamp(0, total);
    return Semantics(
      label: '$acesas de $total tochas acesas',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: Movimento.lenta,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: i < acesas
                    ? c.brilho(luz.cor, alpha: .45, blur: 12)
                    : null,
              ),
              child: Icon(
                Symbols.local_fire_department_rounded,
                size: 20,
                fill: i < acesas ? 1 : 0,
                color: i < acesas ? luz.tinta : c.texto3.withValues(alpha: .5),
              ),
            ),
        ],
      ),
    );
  }
}

/// O painel do topo: a trilha das câmaras e, embaixo, o placar e as tochas.
class PainelDaExpedicao extends StatelessWidget {
  const PainelDaExpedicao({
    super.key,
    required this.resultados,
    required this.tamanhos,
    required this.atual,
    required this.jogadores,
    required this.rejeicoes,
    this.nota,
  });

  final List<bool> resultados;
  final List<int> tamanhos;
  final int atual, jogadores, rejeicoes;

  /// Uma linha extra embaixo (a Lanterna, por exemplo).
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final exploradas = resultados.where((r) => r).length;
    final armadilhas = resultados.length - exploradas;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Espaco.e4,
        Espaco.e4,
        Espaco.e4,
        Espaco.e3,
      ),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(Raio.lg),
        border: Border.all(
          color: c.ehDia ? c.contorno : c.linha,
          width: c.bordaControle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrilhaDasCamaras(
            resultados: resultados,
            tamanhos: tamanhos,
            atual: atual,
            jogadores: jogadores,
          ),
          const SizedBox(height: Espaco.e3),
          Row(
            children: [
              Icon(
                Symbols.diamond_rounded,
                size: 16,
                fill: 1,
                color: c.explorador.tinta,
              ),
              const SizedBox(width: 2),
              Text(
                '$exploradas',
                style: context.estilos.hud.copyWith(
                  fontSize: 15,
                  color: c.explorador.tinta,
                ),
              ),
              const SizedBox(width: Espaco.e3),
              Icon(
                Symbols.dangerous_rounded,
                size: 16,
                fill: 1,
                color: c.saqueador.tinta,
              ),
              const SizedBox(width: 2),
              Text(
                '$armadilhas',
                style: context.estilos.hud.copyWith(
                  fontSize: 15,
                  color: c.saqueador.tinta,
                ),
              ),
              const Spacer(),
              Text('TOCHAS', style: t.labelSmall?.copyWith(color: c.texto3)),
              const SizedBox(width: Espaco.e1),
              Tochas(apagadas: rejeicoes),
            ],
          ),
          if (nota != null) ...[
            const SizedBox(height: Espaco.e2),
            Row(
              children: [
                Icon(Symbols.flashlight_on_rounded, size: 16, color: c.texto3),
                const SizedBox(width: Espaco.e1),
                Expanded(
                  child: Text(
                    nota!,
                    style: t.bodySmall?.copyWith(color: c.texto2),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Cartas da câmara ─────────────────────────────────────────────────────

/// A escolha secreta de quem entra na câmara. Exploradores só avançam;
/// saqueadores escolhem.
class EscolhaDaCarta extends StatelessWidget {
  const EscolhaDaCarta({
    super.key,
    required this.saqueador,
    required this.aoEscolher,
    this.ocupado = false,
  });

  final bool saqueador, ocupado;
  final ValueChanged<bool> aoEscolher;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _CartaGrande(
                avancar: true,
                aoTocar: ocupado ? null : () => aoEscolher(true),
              ),
            ),
            const SizedBox(width: Espaco.e3),
            Expanded(
              child: _CartaGrande(
                avancar: false,
                aoTocar: ocupado || !saqueador ? null : () => aoEscolher(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: Espaco.e3),
        Text(
          saqueador
              ? 'Você é saqueador: pode avançar para despistar ou armar a '
                    'armadilha.'
              : 'Exploradores sempre avançam.',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: c.texto2),
        ),
      ],
    );
  }
}

class _CartaGrande extends StatelessWidget {
  const _CartaGrande({required this.avancar, required this.aoTocar});

  final bool avancar;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = avancar ? c.explorador : c.saqueador;
    final ativa = aoTocar != null;
    return Semantics(
      button: true,
      enabled: ativa,
      label: avancar ? 'Avançar' : 'Armadilha',
      excludeSemantics: true,
      child: Opacity(
        opacity: ativa ? 1 : Opacidade.desabilitado,
        child: Pressionavel(
          onTap: aoTocar == null
              ? null
              : () {
                  HapticFeedback.heavyImpact();
                  aoTocar!();
                },
          escala: .96,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: luz.suave,
              borderRadius: BorderRadius.circular(Raio.xl),
              border: Border.all(
                color: c.ehDia ? c.contorno : luz.cor,
                width: 2,
              ),
              boxShadow: ativa ? c.brilho(luz.cor, alpha: .3, blur: 26) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  avancar
                      ? Symbols.directions_walk_rounded
                      : Symbols.dangerous_rounded,
                  size: 56,
                  fill: 1,
                  color: luz.tinta,
                ),
                const SizedBox(height: Espaco.e3),
                Text(
                  avancar ? 'AVANÇAR' : 'ARMADILHA',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: luz.tinta),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// As cartas de uma câmara viradas uma a uma, embaralhadas. Chama
/// [aoTerminar] depois da última.
class CartasReveladas extends StatefulWidget {
  const CartasReveladas({super.key, required this.cartas, this.aoTerminar});

  /// `true` = Avançar, `false` = Armadilha.
  final List<bool> cartas;
  final VoidCallback? aoTerminar;

  @override
  State<CartasReveladas> createState() => _CartasReveladasState();
}

class _CartasReveladasState extends State<CartasReveladas> {
  int _viradas = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 650), (t) {
      if (!mounted) return;
      if (_viradas >= widget.cartas.length) {
        t.cancel();
        widget.aoTerminar?.call();
        return;
      }
      HapticFeedback.lightImpact();
      setState(() => _viradas++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Espaco.e2,
      runSpacing: Espaco.e2,
      children: [
        for (final (i, avancar) in widget.cartas.indexed)
          AnimatedSwitcher(
            duration: Movimento.media,
            transitionBuilder: (filho, a) => ScaleTransition(
              scale: Tween(
                begin: .6,
                end: 1.0,
              ).animate(CurvedAnimation(parent: a, curve: Movimento.pulo)),
              child: FadeTransition(opacity: a, child: filho),
            ),
            child: i < _viradas
                ? _CartaPequena(key: ValueKey('v$i'), avancar: avancar)
                : Container(
                    key: ValueKey('f$i'),
                    width: 64,
                    height: 88,
                    decoration: BoxDecoration(
                      color: c.superficieElevada,
                      borderRadius: BorderRadius.circular(Raio.md),
                      border: Border.all(
                        color: c.ehDia ? c.contorno : c.linhaForte,
                        width: c.bordaControle,
                      ),
                    ),
                    child: Icon(Symbols.help_rounded, color: c.texto3),
                  ),
          ),
      ],
    );
  }
}

class _CartaPequena extends StatelessWidget {
  const _CartaPequena({super.key, required this.avancar});

  final bool avancar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = avancar ? c.explorador : c.saqueador;
    return Container(
      width: 64,
      height: 88,
      decoration: BoxDecoration(
        color: luz.suave,
        borderRadius: BorderRadius.circular(Raio.md),
        border: Border.all(color: c.ehDia ? c.contorno : luz.cor, width: 2),
        boxShadow: c.brilho(luz.cor, alpha: .35, blur: 16),
      ),
      child: Icon(
        avancar ? Symbols.directions_walk_rounded : Symbols.dangerous_rounded,
        size: 32,
        fill: 1,
        color: luz.tinta,
      ),
    );
  }
}

/// A janela do resultado de uma câmara, depois que as cartas viram.
class ResultadoDaCamara extends StatelessWidget {
  const ResultadoDaCamara({
    super.key,
    required this.numero,
    required this.explorada,
    required this.armadilhas,
  });

  final int numero, armadilhas;
  final bool explorada;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final luz = explorada ? c.explorador : c.saqueador;
    return Janela(
      titulo: 'CÂMARA $numero',
      child: Column(
        children: [
          Icon(
            explorada ? Symbols.diamond_rounded : Symbols.dangerous_rounded,
            size: 48,
            fill: 1,
            color: luz.tinta,
          ),
          const SizedBox(height: Espaco.e2),
          Text(
            explorada ? 'Câmara explorada!' : 'Armadilha!',
            style: t.headlineMedium?.copyWith(color: luz.tinta),
          ),
          const SizedBox(height: Espaco.e1),
          Text(
            armadilhas == 0
                ? 'Ninguém armou nada.'
                : armadilhas == 1
                ? 'Alguém armou uma armadilha${explorada ? ', mas não bastou' : ''}.'
                : '$armadilhas armadilhas foram armadas.',
            textAlign: TextAlign.center,
            style: t.bodyLarge?.copyWith(color: c.texto2),
          ),
        ],
      ),
    );
  }
}

// ─── Papel e fim ──────────────────────────────────────────────────────────

/// A frente da carta de papel: o selo, o ícone e, para saqueadores, quem
/// são os outros.
class FrenteDoPapel extends StatelessWidget {
  const FrenteDoPapel({
    super.key,
    required this.saqueador,
    required this.outrosSaqueadores,
  });

  final bool saqueador;
  final List<String> outrosSaqueadores;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final luz = saqueador ? c.saqueador : c.explorador;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        seloDoPapel(
          context,
          saqueador: saqueador,
          texto: saqueador ? 'VOCÊ É SAQUEADOR' : 'VOCÊ É EXPLORADOR',
        ),
        const SizedBox(height: Espaco.e4),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: c.brilho(luz.cor, alpha: .4, blur: 48),
          ),
          child: Icon(
            saqueador ? Symbols.skull_rounded : Symbols.explore_rounded,
            size: 60,
            fill: 1,
            color: luz.tinta,
          ),
        ),
        const SizedBox(height: Espaco.e4),
        if (saqueador) ...[
          Text(
            outrosSaqueadores.isEmpty
                ? 'Você age sozinho.'
                : 'OS OUTROS SAQUEADORES',
            style: outrosSaqueadores.isEmpty
                ? t.titleMedium
                : t.labelSmall?.copyWith(color: c.texto3),
          ),
          if (outrosSaqueadores.isNotEmpty) ...[
            const SizedBox(height: Espaco.e2),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Espaco.e2,
              runSpacing: Espaco.e2,
              children: [
                for (final nome in outrosSaqueadores)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Espaco.e3,
                      vertical: Espaco.e1,
                    ),
                    decoration: BoxDecoration(
                      color: luz.suave,
                      borderRadius: BorderRadius.circular(Raio.sm),
                    ),
                    child: Text(
                      nome,
                      style: t.titleSmall?.copyWith(color: luz.tinta),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: Espaco.e3),
          Text(
            'Arme três armadilhas sem ser descoberto.',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: c.texto2),
          ),
        ] else
          Text(
            'Explore três câmaras e não leve saqueadores junto.',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: c.texto2),
          ),
      ],
    );
  }
}

/// Um jogador no fim: nome, cor e o papel revelado.
typedef PapelNoFim = ({String nome, int indice, bool saqueador});

/// O fim da expedição: quem venceu, por quê, a trilha e os papéis.
class FimDaExpedicao extends StatelessWidget {
  const FimDaExpedicao({
    super.key,
    required this.exploradoresVenceram,
    required this.porTochas,
    required this.resultados,
    required this.tamanhos,
    required this.jogadores,
    required this.papeis,
  });

  final bool exploradoresVenceram, porTochas;
  final List<bool> resultados;
  final List<int> tamanhos;
  final int jogadores;
  final List<PapelNoFim> papeis;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final luz = exploradoresVenceram ? c.explorador : c.saqueador;
    final saqueadores = papeis.where((p) => p.saqueador).toList();
    final exploradores = papeis.where((p) => !p.saqueador).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Janela(
          titulo: 'FIM DA EXPEDIÇÃO',
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: luz.suave,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.ehDia ? c.contorno : luz.cor,
                    width: 3,
                  ),
                  boxShadow: c.brilho(luz.cor, alpha: .45, blur: 40),
                ),
                child: Icon(
                  exploradoresVenceram
                      ? Symbols.diamond_rounded
                      : Symbols.skull_rounded,
                  size: 48,
                  fill: 1,
                  color: luz.tinta,
                ),
              ),
              const SizedBox(height: Espaco.e4),
              Text(
                exploradoresVenceram
                    ? 'Os exploradores venceram!'
                    : 'Os saqueadores venceram!',
                textAlign: TextAlign.center,
                style: t.headlineMedium,
              ),
              const SizedBox(height: Espaco.e2),
              Text(
                exploradoresVenceram
                    ? 'Três câmaras exploradas. O tesouro é de vocês.'
                    : porTochas
                    ? 'As tochas se apagaram e a expedição se perdeu no escuro.'
                    : 'Três armadilhas e o tesouro sumiu.',
                textAlign: TextAlign.center,
                style: t.bodyLarge?.copyWith(color: c.texto2),
              ),
              const SizedBox(height: Espaco.e5),
              TrilhaDasCamaras(
                resultados: resultados,
                tamanhos: tamanhos,
                atual: 0,
                jogadores: jogadores,
              ),
            ],
          ),
        ),
        const SizedBox(height: Espaco.e8),
        Text('Os saqueadores eram', style: t.headlineSmall),
        const SizedBox(height: Espaco.e3),
        for (final (i, p) in saqueadores.indexed) ...[
          if (i > 0) const SizedBox(height: Espaco.e2),
          LinhaJogador(
            nome: p.nome,
            indice: p.indice,
            direita: seloDoPapel(context, saqueador: true, compacto: true),
          ),
        ],
        const SizedBox(height: Espaco.e6),
        Text('Exploradores', style: t.headlineSmall),
        const SizedBox(height: Espaco.e3),
        Wrap(
          spacing: Espaco.e2,
          runSpacing: Espaco.e2,
          children: [
            for (final p in exploradores)
              ChipJogador(nome: p.nome, indice: p.indice),
          ],
        ),
      ],
    );
  }
}

/// A linha de um voto aberto: o jogador e "SEGUE" ou "RECUSA".
class LinhaDeVoto extends StatelessWidget {
  const LinhaDeVoto({
    super.key,
    required this.nome,
    required this.indice,
    required this.segue,
    this.aoTocar,
  });

  final String nome;
  final int indice;
  final bool segue;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = segue ? c.explorador : c.saqueador;
    return LinhaJogador(
      nome: nome,
      indice: indice,
      onTap: aoTocar,
      direita: AnimatedContainer(
        duration: Movimento.base,
        padding: const EdgeInsets.symmetric(
          horizontal: Espaco.e3,
          vertical: Espaco.e2,
        ),
        decoration: BoxDecoration(
          color: luz.suave,
          borderRadius: BorderRadius.circular(Raio.pill),
          border: c.ehDia ? Border.all(color: c.contorno, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              segue ? Symbols.thumb_up_rounded : Symbols.thumb_down_rounded,
              size: 16,
              fill: 1,
              color: luz.tinta,
            ),
            const SizedBox(width: Espaco.e1),
            Text(
              segue ? 'SEGUE' : 'RECUSA',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: luz.tinta),
            ),
          ],
        ),
      ),
    );
  }
}

/// O que a Lanterna mostrou: a carta de alguém, só para o guia.
class VisaoDaLanterna extends StatelessWidget {
  const VisaoDaLanterna({super.key, required this.nome, required this.avancou});

  final String nome;
  final bool avancou;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return FatoDoFim(
      poco: PocoIcone(
        icone: Symbols.flashlight_on_rounded,
        luz: c.luz(matizExpedicao),
      ),
      texto: comDestaque(
        context,
        '$nome jogou ',
        avancou ? 'Avançar' : 'Armadilha',
        '.',
      ),
    );
  }
}
