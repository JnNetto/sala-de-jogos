import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../../data/models/so_uma_jogador.dart';
import '../../providers/so_uma_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'so_uma_comparar_pistas_screen.dart';
import 'so_uma_passar_dispositivo_screen.dart';

class SoUmaEscreverPistaScreen extends StatefulWidget {
  const SoUmaEscreverPistaScreen({super.key});

  @override
  State<SoUmaEscreverPistaScreen> createState() =>
      _SoUmaEscreverPistaScreenState();
}

class _SoUmaEscreverPistaScreenState extends State<SoUmaEscreverPistaScreen> {
  bool _pronto = false;
  int _escritorIndex = 0;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SoUmaPartidaProvider>();
    final partida = provider.partida;
    final rodada = partida?.rodadaAtual;
    if (partida == null || rodada == null) {
      return const Scaffold(body: Center(child: Text('Rodada não iniciada')));
    }

    final escritores = partida.escritores;

    if (!_pronto) {
      return SoUmaPassarDispositivoScreen(
        titulo: 'Passe o celular para os escritores',
        subtitulo:
            'Não deixe ${partida.adivinhadorAtual.nome} ver a tela a partir de agora.',
        icone: Icons.groups,
        onConfirmar: () => setState(() => _pronto = true),
      );
    }

    if (_escritorIndex >= escritores.length) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Icon(Icons.check_circle, size: 96, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  'Todo mundo escreveu sua pista!',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                PrimaryButton(
                  text: 'Comparar Pistas',
                  icon: Icons.arrow_forward,
                  onPressed: () => _finalizarEscrita(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final escritorAtual = escritores[_escritorIndex];
    final duasPistas =
        partida.quantidadeJogadores == SoUmaConstants.jogadoresParaDuasPistas;
    final pistasJaEscritas = provider.pistasEscritasPorAutor(escritorAtual.id);
    final numeroDaPista = pistasJaEscritas + 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Escreva sua pista'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              LinearProgressIndicator(
                value: _escritorIndex / escritores.length,
                backgroundColor: Colors.grey[200],
                minHeight: 8,
              ),
              const SizedBox(height: 16),
              Text(
                duasPistas
                    ? '${escritorAtual.nome} — pista $numeroDaPista de 2'
                    : escritorAtual.nome,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _CartaCompleta(
                palavras: rodada.carta.palavras,
                indiceAlvo: rodada.numeroEscolhido - 1,
              ),
              const SizedBox(height: 24),
              Text(
                'Escreva uma única palavra que leve ${partida.adivinhadorAtual.nome} até a palavra em destaque.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Sua pista',
                  prefixIcon: Icon(Icons.edit),
                ),
                textCapitalization: TextCapitalization.none,
                onSubmitted: (_) => _enviar(context, escritorAtual, duasPistas),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Confirmar Pista',
                icon: Icons.check,
                onPressed: () => _enviar(context, escritorAtual, duasPistas),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _enviar(
    BuildContext context,
    SoUmaJogador escritorAtual,
    bool duasPistas,
  ) {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    final provider = context.read<SoUmaPartidaProvider>();
    final ok = provider.adicionarPista(escritorAtual.id, texto);
    if (!ok) return;

    _controller.clear();
    final jaEscritas = provider.pistasEscritasPorAutor(escritorAtual.id);
    final necessarias = duasPistas ? 2 : 1;
    if (jaEscritas >= necessarias) {
      setState(() => _escritorIndex++);
    } else {
      setState(() {});
    }
  }

  void _finalizarEscrita(BuildContext context) {
    final provider = context.read<SoUmaPartidaProvider>();
    provider.finalizarEscritaPistas();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SoUmaCompararPistasScreen()),
    );
  }
}

class _CartaCompleta extends StatelessWidget {
  final List<String> palavras;
  final int indiceAlvo;

  const _CartaCompleta({required this.palavras, required this.indiceAlvo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < palavras.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: i == indiceAlvo
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.14)
                        : null,
                    border: i == indiceAlvo
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: i == indiceAlvo
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.3),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          palavras[i],
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: i == indiceAlvo
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
