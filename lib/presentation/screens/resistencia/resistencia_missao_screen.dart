import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/resistencia_fase.dart';
import '../../../core/enums/resistencia_papel.dart';
import '../../../data/models/resistencia_jogador.dart';
import '../../../data/models/resistencia_partida.dart';
import '../../providers/resistencia_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'resistencia_proposta_screen.dart';
import 'resistencia_resultado_screen.dart';

class ResistenciaMissaoScreen extends StatefulWidget {
  const ResistenciaMissaoScreen({super.key});

  @override
  State<ResistenciaMissaoScreen> createState() =>
      _ResistenciaMissaoScreenState();
}

class _ResistenciaMissaoScreenState extends State<ResistenciaMissaoScreen> {
  int _membroAtualIndex = 0;
  bool _resultadoRevelado = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Missão')),
        body: SafeArea(
          child: Consumer<ResistenciaPartidaProvider>(
            builder: (context, provider, _) {
              final partida = provider.partida;
              if (partida == null) {
                return const Center(child: Text('Partida não iniciada'));
              }

              if (_resultadoRevelado) {
                return _ResultadoMissao(
                  partida: partida,
                  onContinuar: () => _continuarAposResultado(context, partida),
                );
              }

              final equipe = partida.equipeProposta;
              final todosJogaram = _membroAtualIndex >= equipe.length;
              if (todosJogaram) {
                return _AguardandoRevelacaoMissao(
                  partida: partida,
                  onRevelar: () {
                    provider.resolverMissao();
                    setState(() => _resultadoRevelado = true);
                  },
                );
              }

              final jogador = equipe[_membroAtualIndex];
              return _ColetaCartaMissao(
                partida: partida,
                jogador: jogador,
                indice: _membroAtualIndex,
                onJogar: (sucesso) {
                  provider.registrarCartaMissao(jogador.id, sucesso);
                  setState(() => _membroAtualIndex++);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _continuarAposResultado(
    BuildContext context,
    ResistenciaPartida partida,
  ) {
    if (partida.fase == ResistenciaFase.propondo) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResistenciaPropostaScreen()),
      );
      return;
    }

    if (partida.fase == ResistenciaFase.finalizada) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResistenciaResultadoScreen()),
      );
    }
  }
}

class _ColetaCartaMissao extends StatelessWidget {
  final ResistenciaPartida partida;
  final ResistenciaJogador jogador;
  final int indice;
  final ValueChanged<bool> onJogar;

  const _ColetaCartaMissao({
    required this.partida,
    required this.jogador,
    required this.indice,
    required this.onJogar,
  });

  @override
  Widget build(BuildContext context) {
    final ehEspiao = jogador.papel == ResistenciaPapel.espiao;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: indice / partida.equipeProposta.length,
            backgroundColor: Colors.grey[200],
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Text(
            'Carta ${indice + 1} de ${partida.equipeProposta.length}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Icon(
            Icons.assignment_turned_in,
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            jogador.nome,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            ehEspiao
                ? 'Escolha secretamente sua carta de missão.'
                : 'A Resistência deve jogar Sucesso.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          if (ehEspiao)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onJogar(false),
                    icon: const Icon(Icons.close),
                    label: const Text('Fracasso'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Sucesso',
                    icon: Icons.check,
                    backgroundColor: Colors.green,
                    onPressed: () => onJogar(true),
                  ),
                ),
              ],
            )
          else
            PrimaryButton(
              text: 'Jogar Sucesso',
              icon: Icons.check,
              backgroundColor: Colors.green,
              onPressed: () => onJogar(true),
            ),
        ],
      ),
    );
  }
}

class _AguardandoRevelacaoMissao extends StatelessWidget {
  final ResistenciaPartida partida;
  final VoidCallback onRevelar;

  const _AguardandoRevelacaoMissao({
    required this.partida,
    required this.onRevelar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.lock, size: 96, color: Colors.orange),
          const SizedBox(height: 32),
          Text(
            'Cartas entregues',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Revele apenas a contagem de fracassos. Quem sabotou continua secreto.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          PrimaryButton(
            text: 'Revelar Resultado',
            icon: Icons.visibility,
            onPressed: onRevelar,
          ),
        ],
      ),
    );
  }
}

class _ResultadoMissao extends StatelessWidget {
  final ResistenciaPartida partida;
  final VoidCallback onContinuar;

  const _ResultadoMissao({required this.partida, required this.onContinuar});

  @override
  Widget build(BuildContext context) {
    final sucesso = partida.ultimaMissaoSucesso == true;
    final fracassos = partida.ultimosFracassosMissao ?? 0;
    final finalizada = partida.fase == ResistenciaFase.finalizada;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          sucesso ? Icons.shield_outlined : Icons.visibility_off,
          size: 96,
          color: sucesso ? Colors.blue : Colors.red,
        ),
        const SizedBox(height: 24),
        Text(
          sucesso ? 'Missão bem-sucedida' : 'Missão sabotada',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '$fracassos ${fracassos == 1 ? 'fracasso' : 'fracassos'}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _PlacarMissao(partida: partida),
        const SizedBox(height: 24),
        PrimaryButton(
          text: finalizada ? 'Fim da Partida' : 'Próxima Proposta',
          icon: Icons.arrow_forward,
          onPressed: onContinuar,
        ),
      ],
    );
  }
}

class _PlacarMissao extends StatelessWidget {
  final ResistenciaPartida partida;

  const _PlacarMissao({required this.partida});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Placar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < partida.tamanhosEquipe.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == partida.tamanhosEquipe.length - 1 ? 0 : 8,
                      ),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _corMissao(partida, i).withValues(alpha: 0.14),
                          border: Border.all(color: _corMissao(partida, i)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: _corMissao(partida, i),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _corMissao(ResistenciaPartida partida, int index) {
    if (index >= partida.resultadosMissoes.length) return Colors.grey;
    return partida.resultadosMissoes[index] ? Colors.blue : Colors.red;
  }
}
