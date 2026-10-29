import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/theme/sala_tokens.dart';
import '../navegacao.dart';
import '../providers/partida_provider.dart';
import '../widgets/sala/botao_sala.dart';
import '../widgets/sala/cronometro.dart';
import '../widgets/sala/dialogo.dart';
import '../widgets/sala/janela.dart';
import '../widgets/sala/jogador_sala.dart';
import '../widgets/sala/tela_da_sala.dart';
import 'votacao_screen.dart';

/// A conversa: o cronômetro corre enquanto a roda pergunta e responde.
/// Quando zera (ou quando pulam), todo mundo vota.
class DiscussaoScreen extends StatefulWidget {
  const DiscussaoScreen({super.key});

  @override
  State<DiscussaoScreen> createState() => _DiscussaoScreenState();
}

class _DiscussaoScreenState extends State<DiscussaoScreen> {
  bool _navegouParaVotacao = false;
  bool _pausado = false;

  void _irParaVotacao() {
    if (_navegouParaVotacao) return;
    _navegouParaVotacao = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const VotacaoScreen()),
    );
  }

  Future<void> _pausar() async {
    final provider = context.read<PartidaProvider>();
    provider.pausarDiscussao();
    setState(() => _pausado = true);
    final tempo = formatarTempo(provider.partida?.tempoRestanteSegundos ?? 0);
    final escolha = await mostrarDialogo(
      context,
      matiz: Matiz.violeta,
      barra: 'PAUSA',
      icone: Symbols.pause_rounded,
      titulo: 'Jogo pausado',
      corpo:
          'O cronômetro parou em $tempo. Ninguém espia o celular de '
          'ninguém.',
      acao: 'Continuar',
      escape: 'Sair da partida',
    );
    if (!mounted) return;
    if (escolha == false) {
      final saiu = await _confirmarSaida();
      if (saiu || !mounted) return;
    }
    setState(() => _pausado = false);
    provider.retomarDiscussao();
  }

  /// Devolve `true` se a partida acabou e a tela saiu.
  Future<bool> _confirmarSaida() async {
    final abortar = await mostrarDialogo(
      context,
      matiz: Matiz.violeta,
      barra: 'ATENÇÃO',
      icone: Symbols.stop_circle_rounded,
      titulo: 'Abortar a partida?',
      corpo:
          'A conversa para aqui e a partida não conta nas estatísticas. '
          'Vocês voltam para a escolha de jogadores.',
      acao: 'Abortar',
      escape: 'Continuar jogando',
      perigo: true,
    );
    if (abortar != true || !mounted) return false;
    context.read<PartidaProvider>().encerrarPartida();
    Navigator.of(context).popUntil(ehInicioDoEspiao);
    return true;
  }

  Future<void> _abortar() async {
    final provider = context.read<PartidaProvider>();
    provider.pausarDiscussao();
    setState(() => _pausado = true);
    final saiu = await _confirmarSaida();
    if (saiu || !mounted) return;
    setState(() => _pausado = false);
    provider.retomarDiscussao();
  }

  Future<void> _pular() async {
    final pular = await mostrarDialogo(
      context,
      matiz: Matiz.violeta,
      barra: 'VOTAÇÃO',
      icone: Symbols.how_to_vote_rounded,
      titulo: 'Já querem votar?',
      corpo: 'O tempo que sobrou fica de lado e todo mundo vota agora.',
      acao: 'Ir para a votação',
      escape: 'Conversar mais',
    );
    if (pular != true || !mounted) return;
    context.read<PartidaProvider>().pularDiscussao();
    _irParaVotacao();
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

    final tempo = partida.tempoRestanteSegundos;
    if (tempo <= 0 && !_navegouParaVotacao) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _irParaVotacao();
      });
    }
    final inicial = partida.jogadorInicial;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu && !_pausado) _pausar();
      },
      child: TelaDaSala(
        sobretitulo: 'DISCUSSÃO',
        titulo: 'Quem é o Espião?',
        matiz: Matiz.violeta,
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
        corpo: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Espaco.margemTela,
              Espaco.e3,
              Espaco.margemTela,
              Espaco.e6,
            ),
            children: [
              if (inicial != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.fromLTRB(
                      Espaco.e2,
                      0,
                      Espaco.e5,
                      0,
                    ),
                    decoration: BoxDecoration(
                      color: c.superficie,
                      borderRadius: BorderRadius.circular(Raio.lg),
                      border: Border.all(
                        color: c.ehDia ? c.contorno : c.linha,
                        width: c.bordaControle,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AvatarJogador(
                          nome: inicial.nome,
                          indice: inicial.id - 1,
                          tamanho: 40,
                        ),
                        const SizedBox(width: Espaco.e3),
                        Text(
                          'Começa ${inicial.nome}',
                          style: texto.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: Espaco.e12),
              Center(
                child: Cronometro(
                  segundos: tempo,
                  pausado: _pausado,
                  grande: true,
                ),
              ),
              const SizedBox(height: Espaco.e3),
              Center(
                child: Text(
                  _pausado ? 'PAUSADO' : 'PARA A CONVERSA',
                  style: texto.labelMedium?.copyWith(color: c.texto3),
                ),
              ),
              const SizedBox(height: Espaco.e12),
              Janela(
                titulo: 'NA RODA',
                preenchimento: const EdgeInsets.fromLTRB(
                  Espaco.e5,
                  Espaco.e4,
                  Espaco.e5,
                  Espaco.e5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, dica) in const [
                      'Pergunte algo sobre a palavra para alguém da roda.',
                      'Responda sem entregar a palavra de bandeja.',
                      'Desconfiou? Guarde para a votação.',
                    ].indexed) ...[
                      if (i > 0) const SizedBox(height: Espaco.e3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${i + 1}',
                              style: context.estilos.hud.copyWith(
                                fontSize: 18,
                                color: luz.tinta,
                              ),
                            ),
                          ),
                          Expanded(child: Text(dica, style: texto.bodyLarge)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
