import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/lobisomem_partida_provider.dart';
import '../../widgets/lobisomem_sair_partida.dart';
import '../../widgets/primary_button.dart';
import 'lobisomem_passar_dispositivo_screen.dart';

class LobisomemNarradorScreen extends StatefulWidget {
  final String texto;
  final void Function(BuildContext context) onContinuar;
  final String textoBotao;

  const LobisomemNarradorScreen({
    super.key,
    required this.texto,
    required this.onContinuar,
    this.textoBotao = 'Continuar',
  });

  @override
  State<LobisomemNarradorScreen> createState() => _LobisomemNarradorScreenState();
}

class _LobisomemNarradorScreenState extends State<LobisomemNarradorScreen> {
  bool _naMaoDoNarrador = false;

  @override
  Widget build(BuildContext context) {
    final partida = context.watch<LobisomemPartidaProvider>().partida;
    if (partida == null) {
      return const Scaffold(body: Center(child: Text('Partida não iniciada')));
    }

    final narrador = partida.narrador;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: lobisomemAppBar(context: context, title: 'Narrador'),
        body: SafeArea(
          child: _naMaoDoNarrador
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Leia em voz alta',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        narrador.nome,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.menu_book,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.texto,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      PrimaryButton(
                        text: widget.textoBotao,
                        icon: Icons.arrow_forward,
                        onPressed: () => widget.onContinuar(context),
                      ),
                    ],
                  ),
                )
              : LobisomemPassarDispositivoScreen(
                  titulo: 'Passe o celular para ${narrador.nome}',
                  subtitulo: narrador.vivo
                      ? 'O Narrador vai ler o próximo capítulo em voz alta.'
                      : 'Mesmo fora do jogo, o Narrador continua lendo a historinha.',
                  icone: Icons.menu_book,
                  textoBotao: 'Estou com o celular',
                  onConfirmar: () => setState(() => _naMaoDoNarrador = true),
                ),
        ),
      ),
    );
  }
}
