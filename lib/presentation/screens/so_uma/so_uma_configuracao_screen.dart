import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../providers/so_uma_partida_provider.dart';
import '../../widgets/config_card.dart';
import '../../widgets/primary_button.dart';
import 'so_uma_escolha_numero_screen.dart';

class SoUmaConfiguracaoScreen extends StatefulWidget {
  const SoUmaConfiguracaoScreen({super.key});

  @override
  State<SoUmaConfiguracaoScreen> createState() =>
      _SoUmaConfiguracaoScreenState();
}

class _SoUmaConfiguracaoScreenState extends State<SoUmaConfiguracaoScreen> {
  final List<TextEditingController> _nomeControllers = [];
  int _quantidadeJogadores = SoUmaConstants.minJogadores;

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
    final provider = context.read<SoUmaPartidaProvider>();

    final sucesso = await provider.iniciarNovaPartida(_nomes);
    if (!mounted) return;

    if (sucesso) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const SoUmaEscolhaNumeroScreen()),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Partida')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ConfigCard(
              title: 'Jogadores',
              subtitle: 'Só uma! usa de 3 a 7 pessoas',
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
                        '${SoUmaConstants.minJogadores}-${SoUmaConstants.maxJogadores}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _quantidadeJogadores.toDouble(),
                    min: SoUmaConstants.minJogadores.toDouble(),
                    max: SoUmaConstants.maxJogadores.toDouble(),
                    divisions:
                        SoUmaConstants.maxJogadores -
                        SoUmaConstants.minJogadores,
                    onChanged: (value) {
                      _quantidadeJogadores = value.toInt();
                      _ajustarControllers(_quantidadeJogadores);
                    },
                  ),
                  if (_quantidadeJogadores ==
                      SoUmaConstants.jogadoresParaDuasPistas)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Com 3 jogadores, cada escritor dá 2 pistas em vez de 1.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            ConfigCard(
              title: 'Nomes dos Jogadores',
              subtitle: 'A ordem de quem adivinha primeiro será sorteada',
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
            const SizedBox(height: 24),
            Consumer<SoUmaPartidaProvider>(
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
