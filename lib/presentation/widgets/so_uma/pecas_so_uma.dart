import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../../core/theme/sala_tokens.dart';
export '../sala/etapa.dart';
import '../sala/fim_de_jogo.dart';
import '../sala/janela.dart';
import '../sala/jogador_sala.dart';
import '../sala/palco_da_sala.dart';
import '../sala/pressionavel.dart';

const matizSoUma = Matiz.lampada;

/// O placar no varal: uma lâmpada por carta da partida, acesa (colorida)
/// para cada carta que o grupo ganhou.
ProgressoDoVaral placarNoVaral(BuildContext context, int cartasGanhas) {
  const roda = [
    Matiz.lampada,
    Matiz.rosa,
    Matiz.menta,
    Matiz.ceu,
    Matiz.brasa,
    Matiz.violeta,
    Matiz.luar,
  ];
  final c = context.cores;
  return ProgressoDoVaral(
    cores: [
      for (var i = 0; i < SoUmaConstants.totalCartasPartida; i++)
        c.luz(roda[i % roda.length]).cor,
    ],
    acesas: cartasGanhas,
  );
}

/// Pílula com as cartas ganhas, para a barra.
class PlacarSoUma extends StatelessWidget {
  const PlacarSoUma({super.key, required this.cartas});

  final int cartas;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(matizSoUma);
    return Semantics(
      label: '$cartas ${cartas == 1 ? 'carta ganha' : 'cartas ganhas'}',
      excludeSemantics: true,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: Espaco.e3),
        decoration: BoxDecoration(
          color: luz.suave,
          borderRadius: BorderRadius.circular(Raio.pill),
          border: c.ehDia ? Border.all(color: c.contorno, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.star_rounded, fill: 1, size: 18, color: luz.tinta),
            const SizedBox(width: Espaco.e1),
            Text(
              '$cartas',
              style: context.estilos.hud.copyWith(
                fontSize: 18,
                color: luz.tinta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A carta de cinco palavras. Três jeitos:
/// - escondida, para quem adivinha escolher um número às cegas;
/// - com a palavra [alvo] acesa, para quem escreve as pistas;
/// - revelada no resultado (também com [alvo]).
class CartaSoUma extends StatelessWidget {
  const CartaSoUma({
    super.key,
    this.palavras,
    this.alvo,
    this.escolhido,
    this.aoEscolher,
    this.tentadas = const {},
  });

  /// Sem palavras, a carta está virada: só os números.
  final List<String>? palavras;

  /// O índice (0 a 4) da palavra da rodada.
  final int? alvo;

  /// Escondida: o número que quem adivinha está escolhendo (0 a 4).
  final int? escolhido;
  final ValueChanged<int>? aoEscolher;

  /// Escondida: as palavras (0 a 4) já tentadas nesta carta, que não dá
  /// para escolher de novo.
  final Set<int> tentadas;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      padding: const EdgeInsets.all(Espaco.e3),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(Raio.xl),
        border: Border.all(
          color: c.ehDia ? c.contorno : c.linha,
          width: c.bordaControle,
        ),
        boxShadow: c.sombraCard,
      ),
      child: Column(
        children: [
          for (var i = 0; i < SoUmaConstants.palavrasPorCarta; i++) ...[
            if (i > 0) const SizedBox(height: Espaco.e2),
            _LinhaDaCarta(
              numero: i + 1,
              palavra: palavras == null || i >= palavras!.length
                  ? null
                  : palavras![i],
              alvo: alvo == i,
              apagada: alvo != null && alvo != i,
              escolhida: escolhido == i,
              tentada: tentadas.contains(i),
              aoTocar: aoEscolher == null || tentadas.contains(i)
                  ? null
                  : () => aoEscolher!(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinhaDaCarta extends StatelessWidget {
  const _LinhaDaCarta({
    required this.numero,
    required this.palavra,
    required this.alvo,
    required this.apagada,
    required this.escolhida,
    required this.aoTocar,
    this.tentada = false,
  });

  final int numero;
  final String? palavra;
  final bool alvo, apagada, escolhida, tentada;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(matizSoUma);
    final aceso = alvo || escolhida;
    final texto = Theme.of(context).textTheme;

    final linha = AnimatedContainer(
      duration: Movimento.base,
      curve: Movimento.padrao,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: Espaco.e3),
      decoration: BoxDecoration(
        color: aceso ? luz.suave : c.superficieFunda,
        borderRadius: BorderRadius.circular(Raio.md),
        border: Border.all(
          color: aceso
              ? (c.ehDia ? c.contorno : luz.cor)
              : (c.ehDia
                    ? c.contorno.withValues(alpha: .3)
                    : Colors.transparent),
          width: aceso ? 2 : 1,
        ),
        boxShadow: aceso ? c.brilho(luz.cor, alpha: .3, blur: 18) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: aceso ? luz.cor : c.superficie,
              borderRadius: BorderRadius.circular(Raio.sm),
              border: c.ehDia
                  ? Border.all(color: c.contorno, width: 1.5)
                  : null,
            ),
            child: Text(
              '$numero',
              style: context.estilos.hud.copyWith(
                fontSize: 16,
                height: 1,
                color: aceso ? c.sobreCor : c.texto2,
              ),
            ),
          ),
          const SizedBox(width: Espaco.e3),
          Expanded(
            child: tentada
                ? Text(
                    'JÁ SAIU',
                    style: texto.labelSmall?.copyWith(color: c.texto3),
                  )
                : palavra == null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: _Tarja(largura: 60.0 + (numero * 37 % 70)),
                  )
                : Text(
                    palavra!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (alvo ? texto.titleLarge : texto.titleMedium)
                        ?.copyWith(
                          color: alvo
                              ? luz.tinta
                              : apagada
                              ? c.texto3
                              : c.texto,
                        ),
                  ),
          ),
          if (alvo)
            Icon(Symbols.arrow_left_alt_rounded, color: luz.tinta)
          else if (escolhida)
            Icon(Symbols.check_rounded, color: luz.tinta),
        ],
      ),
    );

    if (aoTocar == null) {
      return Semantics(
        label: tentada
            ? 'Palavra $numero, já tentada'
            : palavra == null
            ? 'Palavra $numero'
            : '$numero: $palavra${alvo ? ', a palavra da rodada' : ''}',
        excludeSemantics: true,
        child: linha,
      );
    }
    return Semantics(
      button: true,
      selected: escolhida,
      label: 'Palavra $numero',
      excludeSemantics: true,
      child: Pressionavel(onTap: aoTocar, escala: .98, child: linha),
    );
  }
}

/// A tarja que esconde uma palavra na carta virada.
class _Tarja extends StatelessWidget {
  const _Tarja({required this.largura});

  final double largura;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      width: largura,
      height: 12,
      decoration: BoxDecoration(
        color: c.linha,
        borderRadius: BorderRadius.circular(Raio.xs),
      ),
    );
  }
}

/// Uma pista que sobreviveu, grande, como um papelzinho na mesa.
class CartazPista extends StatelessWidget {
  const CartazPista(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(matizSoUma);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espaco.e4,
        vertical: Espaco.e3,
      ),
      decoration: BoxDecoration(
        color: c.superficieElevada,
        borderRadius: BorderRadius.circular(Raio.md),
        border: Border.all(
          color: c.ehDia ? c.contorno : luz.cor.withValues(alpha: .6),
          width: c.bordaControle,
        ),
        boxShadow: [...c.sombraCard, ...c.brilho(luz.cor, alpha: .18)],
      ),
      child: Text(texto, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

/// As pistas que sobraram, centralizadas. Sem nenhuma, um aviso.
class PistasNaMesa extends StatelessWidget {
  const PistasNaMesa({super.key, required this.pistas});

  final List<String> pistas;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    if (pistas.isEmpty) {
      return FatoDoFim(
        poco: PocoIcone(icone: Symbols.block_rounded, luz: c.erro),
        texto: const TextSpan(
          text:
              'Todas as pistas foram anuladas. Dá para chutar mesmo '
              'assim, ou passar.',
        ),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Espaco.e2,
      runSpacing: Espaco.e2,
      children: [for (final p in pistas) CartazPista(p)],
    );
  }
}

String descreverAnulacao(String motivo) => switch (motivo) {
  'identica' => 'Igual a outra pista',
  'plural' => 'Mesma palavra, no plural',
  'genero' => 'Mesma palavra, outro gênero',
  'raiz' => 'Parece da mesma família de outra',
  'palavra_alvo' => 'É a própria palavra da rodada',
  'palavra_alvo_raiz' => 'Parece da família da palavra da rodada',
  _ => 'Anulada automaticamente',
};

/// Uma pista na conferência: vale (verde) ou foi anulada (riscada). Tocar
/// troca.
class PistaParaConferir extends StatelessWidget {
  const PistaParaConferir({
    super.key,
    required this.texto,
    required this.anulada,
    required this.aoTocar,
    this.autor,
    this.motivo,
  });

  final String texto;
  final bool anulada;
  final VoidCallback? aoTocar;
  final String? autor;

  /// Por que o jogo anulou sozinho.
  final String? motivo;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final luz = anulada ? c.erro : c.sucesso;
    final apoio = [
      ?autor,
      if (motivo != null) descreverAnulacao(motivo!),
    ].join(' · ');

    return Semantics(
      toggled: !anulada,
      button: true,
      label: '$texto, ${anulada ? 'anulada' : 'vale'}',
      excludeSemantics: true,
      child: Pressionavel(
        onTap: aoTocar,
        escala: .98,
        child: AnimatedContainer(
          duration: Movimento.base,
          curve: Movimento.padrao,
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(
            horizontal: Espaco.e3,
            vertical: Espaco.e2,
          ),
          decoration: BoxDecoration(
            color: anulada ? c.superficieFunda : c.superficie,
            borderRadius: BorderRadius.circular(Raio.lg),
            border: Border.all(
              color: c.ehDia
                  ? c.contorno
                  : anulada
                  ? c.erro.cor.withValues(alpha: .5)
                  : c.linha,
              width: c.bordaControle,
            ),
          ),
          child: Row(
            children: [
              PocoIcone(
                icone: anulada ? Symbols.block_rounded : Symbols.check_rounded,
                luz: luz,
              ),
              const SizedBox(width: Espaco.e3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      texto,
                      style: t.titleLarge?.copyWith(
                        color: anulada ? c.texto3 : c.texto,
                        decoration: anulada ? TextDecoration.lineThrough : null,
                        decorationColor: c.erro.cor,
                        decorationThickness: 2,
                      ),
                    ),
                    if (apoio.isNotEmpty)
                      Text(
                        apoio,
                        style: t.bodyMedium?.copyWith(color: c.texto3),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Espaco.e2),
              Text(
                anulada ? 'ANULADA' : 'VALE',
                style: t.labelSmall?.copyWith(color: luz.tinta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Como acabou a rodada: "acerto", "erro" ou "passou".
class ResultadoDaRodada extends StatelessWidget {
  const ResultadoDaRodada({
    super.key,
    required this.resultado,
    required this.palavraAlvo,
    required this.adivinhador,
    required this.palavras,
    required this.pistas,
    this.palpite,
    this.cartaVolta = false,
  });

  final String resultado;

  /// Errou e ainda há palavras para tentar: a carta volta para a mesma
  /// pessoa.
  final bool cartaVolta;
  final String palavraAlvo;
  final String adivinhador;
  final String? palpite;
  final List<String> palavras;

  /// Todas as pistas da rodada, com as anuladas.
  final List<({String texto, bool anulada})> pistas;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final (
      Luz luz,
      IconData icone,
      String barra,
      String titulo,
      String efeito,
    ) = switch (resultado) {
      'acerto' => (
        c.sucesso,
        Symbols.check_circle_rounded,
        'ACERTOU',
        'Acertou!',
        'Uma carta a mais para o grupo.',
      ),
      'erro' => (
        c.erro,
        Symbols.cancel_rounded,
        'ERROU',
        'Não foi dessa vez',
        cartaVolta
            ? 'A carta volta: $adivinhador escolhe outra palavra dela.'
            : 'As cinco palavras já foram tentadas, então a carta sai.',
      ),
      _ => (
        c.luz(Matiz.luar),
        Symbols.skip_next_rounded,
        'PASSOU',
        'Passou',
        'Só esta carta fica de fora.',
      ),
    };
    final alvo = palavras.indexOf(palavraAlvo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Janela(
          titulo: barra,
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: luz.suave,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.ehDia ? c.contorno : luz.cor,
                    width: 3,
                  ),
                  boxShadow: c.brilho(luz.cor, alpha: .4, blur: 36),
                ),
                child: Icon(icone, fill: 1, size: 44, color: luz.tinta),
              ),
              const SizedBox(height: Espaco.e4),
              Text(titulo, style: texto.headlineLarge),
              const SizedBox(height: Espaco.e2),
              Text.rich(
                comDestaque(context, 'A palavra era ', palavraAlvo, '.'),
                textAlign: TextAlign.center,
                style: texto.bodyLarge?.copyWith(color: c.texto2),
              ),
              if (palpite != null) ...[
                const SizedBox(height: Espaco.e1),
                Text.rich(
                  comDestaque(context, '$adivinhador chutou ', palpite!, '.'),
                  textAlign: TextAlign.center,
                  style: texto.bodyLarge?.copyWith(color: c.texto2),
                ),
              ],
              const SizedBox(height: Espaco.e3),
              Text(
                efeito,
                textAlign: TextAlign.center,
                style: texto.bodyMedium?.copyWith(color: luz.tinta),
              ),
            ],
          ),
        ),
        const SizedBox(height: Espaco.e6),
        Text('A carta', style: texto.headlineSmall),
        const SizedBox(height: Espaco.e3),
        CartaSoUma(palavras: palavras, alvo: alvo < 0 ? null : alvo),
        if (pistas.isNotEmpty) ...[
          const SizedBox(height: Espaco.e6),
          Text('As pistas', style: texto.headlineSmall),
          const SizedBox(height: Espaco.e3),
          Wrap(
            spacing: Espaco.e2,
            runSpacing: Espaco.e2,
            children: [
              for (final p in pistas)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Espaco.e3,
                    vertical: Espaco.e2,
                  ),
                  decoration: BoxDecoration(
                    color: p.anulada ? c.superficieFunda : c.sucesso.suave,
                    borderRadius: BorderRadius.circular(Raio.sm),
                    border: c.ehDia
                        ? Border.all(color: c.contorno, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    p.texto,
                    style: texto.titleSmall?.copyWith(
                      color: p.anulada ? c.texto3 : c.sucesso.tinta,
                      decoration: p.anulada ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Uma linha do "rodada a rodada" no fim da partida.
typedef RodadaDoFim = ({
  String nome,
  int indice,
  String palavraAlvo,
  String? palpite,
  String resultado,
});

/// O fim da partida: quantas cartas o grupo ganhou, a faixa e cada rodada.
class FimSoUma extends StatelessWidget {
  const FimSoUma({
    super.key,
    required this.cartasGanhas,
    required this.rodadas,
  });

  final int cartasGanhas;
  final List<RodadaDoFim> rodadas;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(matizSoUma);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Janela(
          titulo: 'FIM DE JOGO',
          child: Column(
            children: [
              Text(
                'O GRUPO FEZ',
                style: texto.labelSmall?.copyWith(color: c.texto3),
              ),
              const SizedBox(height: Espaco.e2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$cartasGanhas',
                      style: TextStyle(
                        color: luz.tinta,
                        shadows: c.ehDia
                            ? null
                            : [
                                Shadow(
                                  color: luz.cor.withValues(alpha: .6),
                                  blurRadius: 24,
                                ),
                              ],
                      ),
                    ),
                    TextSpan(
                      text: '/${SoUmaConstants.totalCartasPartida}',
                      style: TextStyle(color: c.texto3, fontSize: 36),
                    ),
                  ],
                ),
                style: context.estilos.hud.copyWith(fontSize: 72, height: 1),
              ),
              const SizedBox(height: Espaco.e3),
              Text(
                SoUmaConstants.faixaDesempenho(cartasGanhas),
                style: texto.headlineSmall,
              ),
            ],
          ),
        ),
        if (rodadas.isNotEmpty) ...[
          const SizedBox(height: Espaco.e8),
          Text('Rodada a rodada', style: texto.headlineSmall),
          const SizedBox(height: Espaco.e3),
          for (final (i, r) in rodadas.indexed) ...[
            if (i > 0) const SizedBox(height: Espaco.e2),
            FatoDoFim(
              poco: AvatarJogador(nome: r.nome, indice: r.indice, tamanho: 44),
              texto: TextSpan(
                children: [
                  comDestaque(context, '${r.nome}: ', r.palavraAlvo),
                  TextSpan(
                    text: r.palpite == null
                        ? '\npassou'
                        : '\nchutou "${r.palpite}"',
                  ),
                ],
              ),
              direita: _SeloResultado(r.resultado),
            ),
          ],
        ],
      ],
    );
  }
}

class _SeloResultado extends StatelessWidget {
  const _SeloResultado(this.resultado);

  final String resultado;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final (luz, icone) = switch (resultado) {
      'acerto' => (c.sucesso, Symbols.check_rounded),
      'erro' => (c.erro, Symbols.close_rounded),
      _ => (c.luz(Matiz.luar), Symbols.skip_next_rounded),
    };
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: luz.suave, shape: BoxShape.circle),
      child: Icon(icone, size: 20, weight: 700, color: luz.tinta),
    );
  }
}

/// O campo de uma palavra só (pista ou chute): sem espaços, grande e
/// centralizado.
class CampoDaPalavra extends StatelessWidget {
  const CampoDaPalavra({
    super.key,
    required this.controlador,
    required this.dica,
    required this.aoEnviar,
    this.autofoco = true,
  });

  final TextEditingController controlador;
  final String dica;
  final VoidCallback aoEnviar;
  final bool autofoco;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    return TextField(
      controller: controlador,
      autofocus: autofoco,
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.done,
      maxLength: 30,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      onSubmitted: (_) => aoEnviar(),
      style: t.headlineSmall,
      decoration: InputDecoration(
        hintText: dica,
        counterText: '',
        hintStyle: t.headlineSmall?.copyWith(color: c.texto3),
      ),
    );
  }
}
