import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/sala_tokens.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/cronometro.dart';
import '../../widgets/sala/dialogo.dart';
import '../../widgets/sala/janela.dart';
import '../../widgets/sala/jogador_sala.dart';
import '../../widgets/sala/tela_da_sala.dart';
import 'pergunta_cartas.dart';
import 'pergunta_votacao_screen.dart';

/// A conversa: a pergunta de verdade aparece, e com ela todo mundo confere
/// quem respondeu outra coisa. Quando o cronômetro zera, votam.
class PerguntaDiscussaoScreen extends StatefulWidget {
  const PerguntaDiscussaoScreen({super.key});

  @override
  State<PerguntaDiscussaoScreen> createState() =>
      _PerguntaDiscussaoScreenState();
}

class _PerguntaDiscussaoScreenState extends State<PerguntaDiscussaoScreen> {
  bool _navegouParaVotacao = false;
  bool _pausado = false;

  void _irParaVotacao() {
    if (_navegouParaVotacao) return;
    _navegouParaVotacao = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const PerguntaVotacaoScreen()),
    );
  }

  Future<void> _pausar() async {
    final provider = context.read<PerguntaPartidaProvider>();
    provider.pausarDiscussao();
    setState(() => _pausado = true);
    final tempo = formatarTempo(provider.partida?.tempoRestanteSegundos ?? 0);
    final escolha = await mostrarDialogo(
      context,
      matiz: Matiz.rosa,
      barra: 'PAUSA',
      icone: Symbols.pause_rounded,
      titulo: 'Jogo pausado',
      corpo: 'O cronômetro parou em $tempo.',
      acao: 'Continuar',
      escape: 'Sair da partida',
    );
    if (!mounted) return;
    if (escolha == false) {
      await _abortar(jaPausado: true);
      return;
    }
    setState(() => _pausado = false);
    provider.retomarDiscussao();
  }

  Future<void> _abortar({bool jaPausado = false}) async {
    final provider = context.read<PerguntaPartidaProvider>();
    if (!jaPausado) {
      provider.pausarDiscussao();
      setState(() => _pausado = true);
    }
    await abortarPerguntaImpostora(
      context,
      corpo:
          'A conversa para aqui e a partida não conta nas estatísticas. '
          'Vocês voltam para a escolha de jogadores.',
    );
    // Se não abortaram, a conversa segue.
    if (!mounted || provider.partida == null) return;
    setState(() => _pausado = false);
    provider.retomarDiscussao();
  }

  Future<void> _pular() async {
    final pular = await mostrarDialogo(
      context,
      matiz: Matiz.rosa,
      barra: 'VOTAÇÃO',
      icone: Symbols.how_to_vote_rounded,
      titulo: 'Já querem votar?',
      corpo: 'O tempo que sobrou fica de lado e todo mundo vota agora.',
      acao: 'Ir para a votação',
      escape: 'Conversar mais',
    );
    if (pular != true || !mounted) return;
    context.read<PerguntaPartidaProvider>().pularDiscussao();
    _irParaVotacao();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(Matiz.rosa);
    final partida = context.watch<PerguntaPartidaProvider>().partida;
    if (partida == null) {
      return const TelaDaSala(
        corpo: Center(child: Text('A partida terminou.')),
      );
    }
    final tempo = partida.tempoRestanteSegundos;
    if (tempo <= 0 && !_navegouParaVotacao) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _irParaVotacao();
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu && !_pausado) _pausar();
      },
      child: TelaDaSala(
        sobretitulo: 'DISCUSSÃO',
        titulo: 'Pergunta Impostora',
        matiz: Matiz.rosa,
        inicio: BotaoIcone(
          icone: Symbols.pause_rounded,
          rotulo: 'Pausar',
          onPressed: _pausado ? null : _pausar,
        ),
        acao: BotaoIcone(
          icone: Symbols.stop_circle_rounded,
          rotulo: 'Abortar partida',
          perigo: true,
          onPressed: _pausado ? null : _abortar,
        ),
        corpo: ListView(
          padding: const EdgeInsets.fromLTRB(
            Espaco.margemTela,
            Espaco.e3,
            Espaco.margemTela,
            Espaco.e6,
          ),
          children: [
            Center(
              child: Cronometro(segundos: tempo, pausado: _pausado),
            ),
            const SizedBox(height: Espaco.e5),
            Janela(
              titulo: 'A PERGUNTA ERA',
              preenchimento: const EdgeInsets.all(Espaco.e5),
              child: Text(
                partida.par.principal,
                textAlign: TextAlign.center,
                style: texto.titleLarge?.copyWith(
                  color: luz.tinta,
                  fontWeight: FontWeight.w900,
                  fontVariations: const [FontVariation.weight(900)],
                ),
              ),
            ),
            const SizedBox(height: Espaco.e6),
            Row(
              children: [
                Expanded(child: Text('Respostas', style: texto.titleMedium)),
                Text(
                  'QUAL NÃO COMBINA?',
                  style: texto.labelSmall?.copyWith(color: c.texto3),
                ),
              ],
            ),
            const SizedBox(height: Espaco.e3),
            for (final j in partida.jogadores) ...[
              LinhaJogador(
                nome: j.nome,
                indice: j.id - 1,
                apoio: '“${j.resposta ?? '...'}”',
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
              rotulo: 'Ir para a votação',
              icone: Symbols.how_to_vote_rounded,
              luz: luz,
              bloco: true,
              onPressed: _pausado ? null : _pular,
            ),
          ),
        ),
      ),
    );
  }
}
