import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/estatisticas.dart';
import 'botao_sala.dart';
import 'dialogo.dart';
import 'marca.dart';
import 'tela_da_sala.dart';
import 'varal.dart';

/// Estatísticas de um jogo de civis contra mentirosos (espiões,
/// impostores): partidas, vitórias de cada lado e tempo médio, em blocos de
/// número.
class TelaEstatisticas extends StatefulWidget {
  const TelaEstatisticas({
    super.key,
    required this.nomeDoJogo,
    required this.matiz,
    required this.carregar,
    required this.apagar,
    required this.mentirosos,
    required this.iconeMentirosos,
  });

  final String nomeDoJogo;
  final Matiz matiz;
  final Future<Estatisticas> Function() carregar;
  final Future<void> Function() apagar;

  /// "espiões", "impostores".
  final String mentirosos;
  final IconData iconeMentirosos;

  @override
  State<TelaEstatisticas> createState() => _TelaEstatisticasState();
}

class _TelaEstatisticasState extends State<TelaEstatisticas> {
  Estatisticas? _stats;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final stats = await widget.carregar();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _carregando = false;
    });
  }

  Future<void> _apagar() async {
    final apagar = await mostrarDialogo(
      context,
      matiz: widget.matiz,
      barra: 'ATENÇÃO',
      icone: Symbols.delete_rounded,
      titulo: 'Apagar as estatísticas?',
      corpo:
          'Partidas e vitórias do ${widget.nomeDoJogo} voltam a zero. Não '
          'dá para desfazer.',
      acao: 'Apagar',
      escape: 'Manter',
      perigo: true,
    );
    if (apagar != true) return;
    await widget.apagar();
    _carregar();
  }

  bool get _vazio => _stats == null || _stats!.partidasJogadas == 0;

  @override
  Widget build(BuildContext context) {
    return TelaDaSala(
      titulo: 'Estatísticas',
      sobretitulo: widget.nomeDoJogo.toUpperCase(),
      matiz: widget.matiz,
      acao: _vazio
          ? null
          : BotaoIcone(
              icone: Symbols.delete_rounded,
              rotulo: 'Apagar estatísticas',
              perigo: true,
              onPressed: _apagar,
            ),
      corpo: _carregando
          ? const Center(child: Varal.carregando())
          : _vazio
          ? _vazioDeTudo(context)
          : _numeros(context),
    );
  }

  Widget _vazioDeTudo(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.margemTela),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Opacity(opacity: .4, child: Marca(tamanho: 64)),
            const SizedBox(height: Espaco.e6),
            Text('Nenhuma partida ainda', style: texto.titleLarge),
            const SizedBox(height: Espaco.e2),
            Text(
              'A primeira rodada fica registrada aqui.',
              textAlign: TextAlign.center,
              style: texto.bodyMedium?.copyWith(color: c.texto2),
            ),
            const SizedBox(height: Espaco.e8),
            BotaoSala(
              rotulo: 'Jogar agora',
              icone: Symbols.play_arrow_rounded,
              luz: c.luz(widget.matiz),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numeros(BuildContext context) {
    final c = context.cores;
    final s = _stats!;
    final cartoes = [
      _CartaoEstatistica(
        icone: Symbols.sports_esports_rounded,
        luz: c.luz(widget.matiz),
        valor: s.partidasJogadas,
        rotulo: 'Partidas jogadas',
      ),
      _CartaoEstatistica(
        icone: Symbols.schedule_rounded,
        luz: c.luz(Matiz.lampada),
        texto: s.tempoMedioFormatado,
        rotulo: 'Tempo médio',
      ),
      _CartaoEstatistica(
        icone: Symbols.group_rounded,
        luz: c.papelCivil,
        valor: s.vitoriasCivis,
        rotulo: 'Vitórias dos civis',
        detalhe: '${s.percentualVitoriasCivis.round()}%',
      ),
      _CartaoEstatistica(
        icone: widget.iconeMentirosos,
        luz: c.papelEspiao,
        valor: s.vitoriasEspioes,
        rotulo: 'Vitórias dos ${widget.mentirosos}',
        detalhe: '${s.percentualVitoriasEspioes.round()}%',
      ),
    ];
    return LayoutBuilder(
      builder: (context, limites) => GridView.count(
        padding: const EdgeInsets.fromLTRB(
          Espaco.margemTela,
          Espaco.e4,
          Espaco.margemTela,
          Espaco.e6,
        ),
        crossAxisCount: limites.maxWidth >= 560 ? 3 : 2,
        mainAxisSpacing: Espaco.e3,
        crossAxisSpacing: Espaco.e3,
        childAspectRatio: .95,
        children: cartoes,
      ),
    );
  }
}

/// Bloco de um número: poço com ícone, valor em pixel que conta de 0 até
/// ele ao abrir, e o rótulo.
class _CartaoEstatistica extends StatelessWidget {
  const _CartaoEstatistica({
    required this.icone,
    required this.luz,
    required this.rotulo,
    this.valor,
    this.texto,
    this.detalhe,
  });

  final IconData icone;
  final Luz luz;
  final String rotulo;

  /// Número inteiro, que conta ao aparecer.
  final int? valor;

  /// Valor já formatado (tempo), mostrado como está.
  final String? texto;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final estilos = Theme.of(context).textTheme;
    return Semantics(
      label: '$rotulo: ${texto ?? valor}${detalhe == null ? '' : ', $detalhe'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Espaco.e4),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: luz.suave,
                borderRadius: BorderRadius.circular(Raio.sm),
              ),
              child: Icon(icone, fill: 1, color: luz.tinta),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: valor == null
                        ? Text(texto ?? '', style: estilos.displaySmall)
                        : TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: valor!.toDouble()),
                            duration: Movimento.d(
                              context,
                              const Duration(milliseconds: 600),
                            ),
                            curve: Movimento.padrao,
                            builder: (_, v, _) => Text(
                              '${v.round()}',
                              style: estilos.displaySmall,
                            ),
                          ),
                  ),
                ),
                if (detalhe != null) ...[
                  const SizedBox(width: Espaco.e2),
                  Text(
                    detalhe!,
                    style: estilos.labelMedium?.copyWith(color: luz.tinta),
                  ),
                ],
              ],
            ),
            const SizedBox(height: Espaco.e1),
            Text(rotulo, style: estilos.bodyMedium?.copyWith(color: c.texto2)),
          ],
        ),
      ),
    );
  }
}
