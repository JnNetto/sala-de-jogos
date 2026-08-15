import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/resistencia_constants.dart';
import '../../providers/resistencia_partida_provider.dart';
import '../../widgets/config_card.dart';
import '../../widgets/primary_button.dart';
import 'resistencia_distribuicao_screen.dart';

class ResistenciaConfiguracaoScreen extends StatefulWidget {
  const ResistenciaConfiguracaoScreen({super.key});

  @override
  State<ResistenciaConfiguracaoScreen> createState() =>
      _ResistenciaConfiguracaoScreenState();
}

class _ResistenciaConfiguracaoScreenState
    extends State<ResistenciaConfiguracaoScreen> {
  final List<TextEditingController> _nomeControllers = [];
  int _quantidadeJogadores = ResistenciaConstants.minJogadores;
  bool _mostrarNomes = true;

  @override
  void initState() {
    super.initState();
    _ajustarControllers(_quantidadeJogadores);
  }

  void _ajustarControllers(int quantidade) {
    if (_nomeControllers.length < quantidade) {
      for (var i = _nomeControllers.length; i < quantidade; i++) {
        _nomeControllers.add(TextEditingController(text: 'Jogador ${i + 1}'));
      }
    } else if (_nomeControllers.length > quantidade) {
      while (_nomeControllers.length > quantidade) {
        _nomeControllers.removeLast().dispose();
      }
    }
    setState(() {});
  }

  List<String> get _nomes {
    return [
      for (var i = 0; i < _nomeControllers.length; i++)
        _nomeControllers[i].text.trim().isEmpty
            ? 'Jogador ${i + 1}'
            : _nomeControllers[i].text.trim(),
    ];
  }

  Future<void> _iniciarPartida() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ResistenciaPartidaProvider>();

    final sucesso = await provider.iniciarNovaPartida(_nomes);
    if (!mounted) return;

    if (sucesso) {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ResistenciaDistribuicaoScreen(),
        ),
      );
    } else if (provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _nomeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantidadeEspioes = ResistenciaConstants.quantidadeEspioes(
      _quantidadeJogadores,
    );
    final quantidadeResistencia = _quantidadeJogadores - quantidadeEspioes;
    final tamanhosEquipe = ResistenciaConstants.tamanhosEquipe(
      _quantidadeJogadores,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Partida')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ConfigCard(
              title: 'Jogadores',
              subtitle: 'A Resistência usa de 5 a 10 pessoas',
              icon: Icons.group,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_quantidadeJogadores jogadores',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${ResistenciaConstants.minJogadores}-${ResistenciaConstants.maxJogadores}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _quantidadeJogadores.toDouble(),
                    min: ResistenciaConstants.minJogadores.toDouble(),
                    max: ResistenciaConstants.maxJogadores.toDouble(),
                    divisions:
                        ResistenciaConstants.maxJogadores -
                        ResistenciaConstants.minJogadores,
                    onChanged: (value) {
                      _quantidadeJogadores = value.toInt();
                      _ajustarControllers(_quantidadeJogadores);
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _mostrarNomes = !_mostrarNomes);
                      },
                      icon: Icon(
                        _mostrarNomes ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(
                        _mostrarNomes
                            ? 'Ocultar nomes'
                            : 'Editar nomes dos jogadores',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_mostrarNomes)
              ConfigCard(
                title: 'Nomes dos Jogadores',
                subtitle: 'A ordem de liderança será sorteada ao iniciar',
                icon: Icons.edit,
                child: Column(
                  children: [
                    for (var i = 0; i < _nomeControllers.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: _nomeControllers[i],
                          decoration: InputDecoration(
                            labelText: 'Jogador ${i + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                  ],
                ),
              ),
            ConfigCard(
              title: 'Times',
              subtitle:
                  'Composição oficial para $_quantidadeJogadores jogadores',
              icon: Icons.shield_outlined,
              child: Row(
                children: [
                  Expanded(
                    child: _ResumoTime(
                      label: 'Resistência',
                      valor: quantidadeResistencia,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResumoTime(
                      label: 'Espiões',
                      valor: quantidadeEspioes,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            ConfigCard(
              title: 'Missões',
              subtitle: 'Tamanho da equipe em cada uma das 5 missões',
              icon: Icons.flag_outlined,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < tamanhosEquipe.length; i++)
                    Chip(
                      avatar: CircleAvatar(child: Text('${i + 1}')),
                      label: Text('${tamanhosEquipe[i]} jogadores'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Consumer<ResistenciaPartidaProvider>(
              builder: (context, provider, _) {
                return PrimaryButton(
                  text: 'Iniciar Partida',
                  icon: Icons.play_arrow,
                  isLoading: provider.isLoading,
                  onPressed: _iniciarPartida,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ResumoTime extends StatelessWidget {
  final String label;
  final int valor;
  final Color color;

  const _ResumoTime({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.08),
      ),
      child: Column(
        children: [
          Text(
            '$valor',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
