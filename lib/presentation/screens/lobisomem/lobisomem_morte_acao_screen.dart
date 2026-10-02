import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/lobisomem_jogador.dart';
import '../../../data/models/lobisomem_partida.dart';
import '../../providers/lobisomem_partida_provider.dart';
import '../../widgets/lobisomem_sair_partida.dart';
import '../../widgets/primary_button.dart';
import 'lobisomem_fluxo.dart';
import 'lobisomem_passar_dispositivo_screen.dart';

class LobisomemMorteAcaoScreen extends StatefulWidget {
  const LobisomemMorteAcaoScreen({super.key});

  @override
  State<LobisomemMorteAcaoScreen> createState() =>
      _LobisomemMorteAcaoScreenState();
}

class _LobisomemMorteAcaoScreenState extends State<LobisomemMorteAcaoScreen> {
  bool _mostrandoPasse = true;
  String? _alvoCacador;

  void _reset() {
    _mostrandoPasse = true;
    _alvoCacador = null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: lobisomemAppBar(context: context, title: 'Despedida'),
        body: SafeArea(
          child: Consumer<LobisomemPartidaProvider>(
            builder: (context, provider, _) {
              final partida = provider.partida;
              if (partida == null) {
                return const Center(child: Text('Partida não iniciada'));
              }
              if (!partida.temMorteNaFila) {
                return const Center(child: Text('Nenhuma morte pendente'));
              }

              final morto = partida.jogadorPorId(partida.morteAtualId);
              if (_mostrandoPasse) {
                return LobisomemPassarDispositivoScreen(
                  titulo: 'Passe o celular para ${morto.nome}',
                  subtitulo: 'Só esta pessoa deve olhar a próxima tela.',
                  icone: Icons.waving_hand,
                  onConfirmar: () => setState(() => _mostrandoPasse = false),
                );
              }

              return _TelaMorte(
                partida: partida,
                morto: morto,
                alvoCacador: _alvoCacador,
                onAlvo: (id) => setState(() => _alvoCacador = id),
                onContinuar: () {
                  if (morto.ehCacador && partida.vivos.isNotEmpty) {
                    if (_alvoCacador == null) return;
                    provider.registrarTiroCacador(_alvoCacador!);
                  } else {
                    provider.confirmarDespedida();
                  }
                  if (!context.mounted) return;
                  final atual = provider.partida;
                  if (atual == null) return;
                  if (atual.temMorteNaFila) {
                    setState(_reset);
                    return;
                  }
                  continuarAposMortes(context, provider);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TelaMorte extends StatelessWidget {
  final LobisomemPartida partida;
  final LobisomemJogador morto;
  final String? alvoCacador;
  final ValueChanged<String> onAlvo;
  final VoidCallback onContinuar;

  const _TelaMorte({
    required this.partida,
    required this.morto,
    required this.alvoCacador,
    required this.onAlvo,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    final precisaEscolherAlvo =
        morto.ehCacador && partida.vivos.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                Text(
                  morto.nome,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Você era ${morto.papel.nome}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Você morreu. Despeça-se em voz alta, sem revelar informações além do que a mesa combinou.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (precisaEscolherAlvo) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Escolha alguém vivo para cair com você.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: alvoCacador,
                    onChanged: (value) {
                      if (value != null) onAlvo(value);
                    },
                    child: Column(
                      children: [
                        for (final vivo in partida.vivos)
                          RadioListTile<String>(
                            title: Text(vivo.nome),
                            value: vivo.id,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          PrimaryButton(
            text: 'Continuar',
            icon: Icons.arrow_forward,
            onPressed: precisaEscolherAlvo && alvoCacador == null
                ? null
                : onContinuar,
          ),
        ],
      ),
    );
  }
}
