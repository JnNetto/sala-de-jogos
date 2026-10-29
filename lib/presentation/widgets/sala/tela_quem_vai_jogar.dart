import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import 'botao_sala.dart';
import 'jogador_sala.dart';
import 'pressionavel.dart';
import 'tela_da_sala.dart';

/// "Quem vai jogar?": o primeiro passo dos jogos de passar o celular. Monta
/// a mesa com chips (a ordem é a de passar o celular, e segurar um chip
/// muda a ordem) e mostra embaixo o card que o jogo quiser, como a
/// quantidade de espiões.
class TelaQuemVaiJogar extends StatefulWidget {
  const TelaQuemVaiJogar({
    super.key,
    required this.nomeDoJogo,
    required this.matiz,
    required this.minimo,
    required this.maximo,
    required this.nomesSalvos,
    required this.extras,
    required this.aoContinuar,
    this.sobretitulo = 'PASSO 1 DE 2',
  });

  final String nomeDoJogo;
  final Matiz matiz;
  final int minimo, maximo;

  /// Os nomes da última partida, que voltam para a mesa.
  final Future<List<String>> Function() nomesSalvos;

  /// O que vem abaixo dos chips, conforme quantas pessoas estão na mesa.
  final Widget Function(BuildContext context, int jogadores) extras;
  final Future<void> Function(List<String> nomes) aoContinuar;
  final String sobretitulo;

  @override
  State<TelaQuemVaiJogar> createState() => _TelaQuemVaiJogarState();
}

class _TelaQuemVaiJogarState extends State<TelaQuemVaiJogar> {
  final _campo = TextEditingController();
  final _foco = FocusNode();
  final _nomes = <String>[];
  String? _erro;
  bool _carregou = false;

  /// Nomes de antes do chip ("Jogador 3") não valem como nome de verdade.
  static final _nomePadrao = RegExp(r'^Jogador \d+$');

  @override
  void initState() {
    super.initState();
    // Depois do primeiro quadro: carregar mexe no provider, que avisa os
    // ouvintes, e isso não pode acontecer no meio da montagem.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final salvos = await widget.nomesSalvos();
      if (!mounted) return;
      setState(() {
        _nomes.addAll(
          salvos
              .map((n) => n.trim())
              .where((n) => n.isNotEmpty && !_nomePadrao.hasMatch(n))
              .toSet()
              .take(widget.maximo),
        );
        _carregou = true;
      });
    });
  }

  @override
  void dispose() {
    _campo.dispose();
    _foco.dispose();
    super.dispose();
  }

  bool get _cheia => _nomes.length >= widget.maximo;

  void _adicionar() {
    final nome = _campo.text.trim();
    if (nome.isEmpty) return;
    final repetido = _nomes
        .where((n) => n.toLowerCase() == nome.toLowerCase())
        .firstOrNull;
    if (repetido != null) {
      HapticFeedback.mediumImpact();
      setState(() => _erro = 'Já tem $repetido na mesa. Que tal um apelido?');
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _nomes.add(nome);
      _erro = null;
    });
    _campo.clear();
    // Enter adiciona e o teclado continua aberto para o próximo nome.
    if (!_cheia) _foco.requestFocus();
  }

  void _mover(int de, int para) {
    if (de == para) return;
    HapticFeedback.selectionClick();
    setState(() {
      final nome = _nomes.removeAt(de);
      _nomes.insert(para, nome);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(widget.matiz);
    final n = _nomes.length;
    final min = widget.minimo, max = widget.maximo;

    return TelaDaSala(
      sobretitulo: widget.sobretitulo,
      titulo: widget.nomeDoJogo,
      matiz: widget.matiz,
      corpo: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espaco.margemTela,
          Espaco.e4,
          Espaco.margemTela,
          Espaco.e6,
        ),
        children: [
          Text('Quem vai jogar?', style: texto.headlineLarge),
          const SizedBox(height: Espaco.e2),
          Text(
            'De $min a $max pessoas. Segure um nome para mudar a ordem.',
            style: texto.bodyLarge?.copyWith(color: c.texto2),
          ),
          const SizedBox(height: Espaco.e6),
          Text('Nome do jogador', style: texto.titleSmall),
          const SizedBox(height: Espaco.e2),
          TextField(
            controller: _campo,
            focusNode: _foco,
            enabled: !_cheia,
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: texto.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation.weight(700)],
            ),
            onChanged: (_) {
              if (_erro != null) setState(() => _erro = null);
            },
            onSubmitted: (_) => _adicionar(),
            decoration: InputDecoration(
              hintText: _cheia ? 'Mesa cheia' : 'Ex.: Ana',
              counterText: '',
              errorText: _erro,
              helperText: _cheia ? 'A mesa está cheia: $max é o máximo.' : null,
              contentPadding: const EdgeInsets.fromLTRB(Espaco.e4, 18, 0, 18),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(6),
                child: _BotaoAdicionar(
                  luz: luz,
                  onPressed: _cheia ? null : _adicionar,
                ),
              ),
            ),
          ),
          const SizedBox(height: Espaco.e4),
          if (_carregou)
            Wrap(
              spacing: Espaco.e2,
              runSpacing: Espaco.e2,
              children: [
                for (final (i, nome) in _nomes.indexed)
                  _ChipArrastavel(
                    key: ValueKey(nome),
                    nome: nome,
                    indice: i,
                    aoRemover: () => setState(() => _nomes.removeAt(i)),
                    aoSoltarSobre: (de) => _mover(de, i),
                  ),
              ],
            ),
          const SizedBox(height: Espaco.e6),
          widget.extras(context, n),
        ],
      ),
      rodape: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Espaco.margemTela,
            Espaco.e3,
            Espaco.margemTela,
            Espaco.e4,
          ),
          child: Row(
            children: [
              Semantics(
                label: '$n jogadores',
                excludeSemantics: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$n',
                      style: context.estilos.hud.copyWith(
                        fontSize: 32,
                        height: 1,
                        color: n >= min ? c.texto : c.texto3,
                      ),
                    ),
                    const SizedBox(height: Espaco.e1),
                    Text(
                      n == 1 ? 'JOGADOR' : 'JOGADORES',
                      style: texto.labelSmall?.copyWith(color: c.texto3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Espaco.e6),
              Expanded(
                child: BotaoSala(
                  rotulo: 'Continuar',
                  icone: Symbols.arrow_forward_rounded,
                  iconeNoFim: true,
                  luz: luz,
                  bloco: true,
                  onPressed: n >= min
                      ? () => widget.aoContinuar(List.of(_nomes))
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O "+" dentro do campo, cheio na luz do jogo.
class _BotaoAdicionar extends StatelessWidget {
  const _BotaoAdicionar({required this.luz, this.onPressed});

  final Luz luz;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final ativo = onPressed != null;
    return Semantics(
      button: true,
      enabled: ativo,
      label: 'Adicionar jogador',
      excludeSemantics: true,
      child: Pressionavel(
        onTap: onPressed,
        escala: .92,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ativo ? luz.cor : c.superficieElevada,
            borderRadius: BorderRadius.circular(Raio.md),
            border: c.ehDia ? Border.all(color: c.contorno, width: 2) : null,
          ),
          child: Icon(
            Symbols.add_rounded,
            color: ativo ? c.sobreCor : c.texto3,
          ),
        ),
      ),
    );
  }
}

/// Chip que entra com um pulinho e, segurado, pode ser arrastado sobre
/// outro para trocar de lugar na ordem.
class _ChipArrastavel extends StatelessWidget {
  const _ChipArrastavel({
    super.key,
    required this.nome,
    required this.indice,
    required this.aoRemover,
    required this.aoSoltarSobre,
  });

  final String nome;
  final int indice;
  final VoidCallback aoRemover;
  final ValueChanged<int> aoSoltarSobre;

  @override
  Widget build(BuildContext context) {
    final chip = ChipJogador(nome: nome, indice: indice, aoRemover: aoRemover);
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != indice,
      onAcceptWithDetails: (d) => aoSoltarSobre(d.data),
      builder: (context, candidatos, _) => LongPressDraggable<int>(
        data: indice,
        hapticFeedbackOnStart: true,
        feedback: Material(
          type: MaterialType.transparency,
          child: Transform.scale(
            scale: 1.05,
            child: ChipJogador(nome: nome, indice: indice, elevado: true),
          ),
        ),
        childWhenDragging: Opacity(opacity: .3, child: chip),
        child: AnimatedScale(
          // Quem está embaixo do chip arrastado se afasta um pouquinho.
          scale: candidatos.isNotEmpty ? .92 : 1,
          duration: Movimento.base,
          curve: Movimento.pulo,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Movimento.d(context, Movimento.base),
            curve: Movimento.pulo,
            builder: (_, t, filho) => Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - t)),
                child: Transform.scale(scale: .85 + .15 * t, child: filho),
              ),
            ),
            child: chip,
          ),
        ),
      ),
    );
  }
}
