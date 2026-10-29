import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/enums/vencedor.dart';
import '../../core/theme/sala_tokens.dart';
import '../navegacao.dart';
import '../providers/partida_provider.dart';
import '../widgets/sala/botao_sala.dart';
import '../widgets/sala/dialogo.dart';
import '../widgets/sala/jogador_sala.dart';
import '../widgets/sala/tela_da_sala.dart';
import 'resultado_screen.dart';

/// A votação: a roda escolhe junto um suspeito para sair da mesa.
class VotacaoScreen extends StatefulWidget {
  const VotacaoScreen({super.key});

  @override
  State<VotacaoScreen> createState() => _VotacaoScreenState();
}

class _VotacaoScreenState extends State<VotacaoScreen> {
  int? _selecionado;
  int _rodada = 1;

  Future<void> _abortar() async {
    final abortar = await mostrarDialogo(
      context,
      matiz: Matiz.violeta,
      barra: 'ATENÇÃO',
      icone: Symbols.stop_circle_rounded,
      titulo: 'Abortar a partida?',
      corpo:
          'A votação para aqui e a partida não conta nas estatísticas. '
          'Vocês voltam para a escolha de jogadores.',
      acao: 'Abortar',
      escape: 'Continuar votando',
      perigo: true,
    );
    if (abortar != true || !mounted) return;
    context.read<PartidaProvider>().encerrarPartida();
    Navigator.of(context).popUntil(ehInicioDoEspiao);
  }

  Future<void> _votar() async {
    final provider = context.read<PartidaProvider>();
    final partida = provider.partida;
    final id = _selecionado;
    if (partida == null || id == null) return;
    final nome = partida.jogadores.firstWhere((j) => j.id == id).nome;

    final confirmou = await mostrarDialogo(
      context,
      matiz: Matiz.violeta,
      barra: 'VOTAÇÃO',
      icone: Symbols.how_to_vote_rounded,
      titulo: 'Tirar $nome da mesa?',
      corpo:
          'Se $nome for o espião, os civis vencem. Se não for, a partida '
          'continua sem $nome.',
      acao: 'Tirar $nome',
      escape: 'Escolher outro',
    );
    if (confirmou != true || !mounted) return;

    HapticFeedback.heavyImpact();
    provider.votarJogador(id);
    final vencedor = provider.partida!.vencedor;

    if (vencedor != Vencedor.emAndamento) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const ResultadoScreen()),
      );
      return;
    }
    await mostrarDialogo(
      context,
      matiz: Matiz.violeta,
      barra: 'FORA DA MESA',
      icone: Symbols.person_remove_rounded,
      titulo: '$nome saiu da mesa.',
      corpo:
          'Ninguém venceu ainda: tem espião entre vocês. Conversem e '
          'votem de novo.',
      acao: 'Votar de novo',
      dispensavel: false,
    );
    if (!mounted) return;
    setState(() {
      _selecionado = null;
      _rodada++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(Matiz.violeta);
    final partida = context.watch<PartidaProvider>().partida;
    if (partida == null) {
      return const TelaDaSala(
        corpo: Center(child: Text('A partida terminou.')),
      );
    }
    final ativos = partida.jogadoresAtivos;
    final selecionado = ativos.where((j) => j.id == _selecionado).firstOrNull;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) _abortar();
      },
      child: TelaDaSala(
        sobretitulo: _rodada == 1 ? 'VOTAÇÃO' : 'VOTAÇÃO $_rodada',
        titulo: 'Quem é o Espião?',
        matiz: Matiz.violeta,
        voltar: false,
        acao: BotaoIcone(
          icone: Symbols.stop_circle_rounded,
          rotulo: 'Abortar partida',
          perigo: true,
          onPressed: _abortar,
        ),
        corpo: ListView(
          padding: const EdgeInsets.fromLTRB(
            Espaco.margemTela,
            Espaco.e4,
            Espaco.margemTela,
            Espaco.e6,
          ),
          children: [
            Text('Quem é o espião?', style: texto.headlineLarge),
            const SizedBox(height: Espaco.e2),
            Text(
              'Conversem e escolham juntos um suspeito.',
              style: texto.bodyLarge?.copyWith(color: c.texto2),
            ),
            const SizedBox(height: Espaco.e6),
            for (final j in ativos) ...[
              LinhaJogador(
                nome: j.nome,
                indice: j.id - 1,
                selecionado: j.id == _selecionado,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selecionado = j.id);
                },
                direita: AnimatedSwitcher(
                  duration: Movimento.base,
                  switchInCurve: Movimento.pulo,
                  transitionBuilder: (f, a) =>
                      ScaleTransition(scale: a, child: f),
                  child: j.id == _selecionado
                      ? Icon(
                          Symbols.check_circle_rounded,
                          key: const ValueKey('sim'),
                          fill: 1,
                          size: 28,
                          color: luz.tinta,
                        )
                      : const SizedBox(key: ValueKey('nao'), width: 28),
                ),
              ),
              const SizedBox(height: Espaco.e3),
            ],
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
            child: BotaoSala(
              rotulo: selecionado == null
                  ? 'Escolham um suspeito'
                  : 'Votar em ${selecionado.nome}',
              icone: Symbols.how_to_vote_rounded,
              luz: luz,
              bloco: true,
              onPressed: selecionado == null ? null : _votar,
            ),
          ),
        ),
      ),
    );
  }
}
