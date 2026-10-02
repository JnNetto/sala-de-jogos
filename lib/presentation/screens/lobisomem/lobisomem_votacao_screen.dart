import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/lobisomem_jogador.dart';
import '../../../data/models/lobisomem_partida.dart';
import '../../providers/lobisomem_partida_provider.dart';
import '../../widgets/lobisomem_sair_partida.dart';
import '../../widgets/primary_button.dart';
import 'lobisomem_fluxo.dart';
import 'lobisomem_narrador_screen.dart';
import 'lobisomem_passar_dispositivo_screen.dart';

class LobisomemVotacaoScreen extends StatefulWidget {
  const LobisomemVotacaoScreen({super.key});

  @override
  State<LobisomemVotacaoScreen> createState() => _LobisomemVotacaoScreenState();
}

class _LobisomemVotacaoScreenState extends State<LobisomemVotacaoScreen> {
  int _indice = 0;
  bool _mostrandoPasse = true;
  bool _votosRevelados = false;
  String? _alvoSelecionado;
  bool _abster = false;

  void _resetVoto() {
    _mostrandoPasse = true;
    _alvoSelecionado = null;
    _abster = false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: lobisomemAppBar(context: context, title: 'Votação'),
        body: SafeArea(
          child: Consumer<LobisomemPartidaProvider>(
            builder: (context, provider, _) {
              final partida = provider.partida;
              if (partida == null) {
                return const Center(child: Text('Partida não iniciada'));
              }

              if (_votosRevelados) {
                return _ResultadoVotos(
                  partida: partida,
                  onContinuar: () {
                    provider.resolverVotacao();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LobisomemNarradorScreen(
                          texto: provider.textoResultadoVoto(),
                          onContinuar: (ctx) => continuarAposNarracaoEliminacao(
                            ctx,
                            provider,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              final eleitores = partida.eleitores;
              if (_indice >= eleitores.length) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      const Icon(Icons.lock, size: 96, color: Colors.orange),
                      const SizedBox(height: 32),
                      Text(
                        'Todos votaram',
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Revele os votos para a aldeia.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      PrimaryButton(
                        text: 'Revelar Votos',
                        icon: Icons.visibility,
                        onPressed: () => setState(() => _votosRevelados = true),
                      ),
                    ],
                  ),
                );
              }

              final eleitor = eleitores[_indice];
              if (_mostrandoPasse) {
                return LobisomemPassarDispositivoScreen(
                  titulo: 'Passe o celular para ${eleitor.nome}',
                  subtitulo: partida.emRevoto
                      ? 'Revoto somente entre os empatados.'
                      : 'Vote em silêncio e devolva o celular.',
                  icone: Icons.how_to_vote,
                  onConfirmar: () => setState(() => _mostrandoPasse = false),
                );
              }

              return _ColetaVoto(
                partida: partida,
                eleitor: eleitor,
                indice: _indice,
                alvoSelecionado: _alvoSelecionado,
                abster: _abster,
                onAlvo: (id) => setState(() {
                  _alvoSelecionado = id;
                  _abster = false;
                }),
                onAbster: () => setState(() {
                  _abster = true;
                  _alvoSelecionado = null;
                }),
                onConfirmar: () {
                  provider.registrarVotoDia(
                    eleitor.id,
                    _abster ? null : _alvoSelecionado,
                  );
                  setState(() {
                    _indice++;
                    _resetVoto();
                  });
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ColetaVoto extends StatelessWidget {
  final LobisomemPartida partida;
  final LobisomemJogador eleitor;
  final int indice;
  final String? alvoSelecionado;
  final bool abster;
  final ValueChanged<String> onAlvo;
  final VoidCallback onAbster;
  final VoidCallback onConfirmar;

  const _ColetaVoto({
    required this.partida,
    required this.eleitor,
    required this.indice,
    required this.alvoSelecionado,
    required this.abster,
    required this.onAlvo,
    required this.onAbster,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final alvos = [
      for (final alvo in partida.alvosVoto)
        if (partida.configuracao.permitirVotoEmSi || alvo.id != eleitor.id)
          alvo,
    ];
    final podeConfirmar = abster || alvoSelecionado != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: partida.eleitores.isEmpty
                ? 0
                : indice / partida.eleitores.length,
            backgroundColor: Colors.grey[200],
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Text(
            'Voto ${indice + 1} de ${partida.eleitores.length}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            eleitor.nome,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                RadioGroup<String>(
                  groupValue: abster ? '__abster__' : alvoSelecionado,
                  onChanged: (value) {
                    if (value == null) return;
                    if (value == '__abster__') {
                      onAbster();
                    } else {
                      onAlvo(value);
                    }
                  },
                  child: Column(
                    children: [
                      for (final alvo in alvos)
                        RadioListTile<String>(
                          title: Text(alvo.nome),
                          value: alvo.id,
                        ),
                      if (partida.configuracao.permitirAbstencao)
                        const RadioListTile<String>(
                          title: Text('Abster-se'),
                          value: '__abster__',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PrimaryButton(
            text: 'Confirmar voto',
            icon: Icons.check,
            onPressed: podeConfirmar ? onConfirmar : null,
          ),
        ],
      ),
    );
  }
}

class _ResultadoVotos extends StatelessWidget {
  final LobisomemPartida partida;
  final VoidCallback onContinuar;

  const _ResultadoVotos({required this.partida, required this.onContinuar});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Votos da aldeia',
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final eleitor in partida.eleitores)
                  _LinhaVoto(
                    nome: eleitor.nome,
                    alvo: partida.votosDia[eleitor.id] == null
                        ? 'Absteve-se'
                        : partida.nomePorId(partida.votosDia[eleitor.id]!),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'Continuar',
          icon: Icons.arrow_forward,
          onPressed: onContinuar,
        ),
      ],
    );
  }
}

class _LinhaVoto extends StatelessWidget {
  final String nome;
  final String alvo;

  const _LinhaVoto({required this.nome, required this.alvo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(nome, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            alvo,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
