import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/service_locator.dart';
import '../../providers/aneis_sala_provider.dart';
import '../../widgets/primary_button.dart';
import 'aneis_sala_router_screen.dart';

class AneisEntradaSalaScreen extends StatefulWidget {
  final bool criarSala;

  const AneisEntradaSalaScreen({super.key, required this.criarSala});

  @override
  State<AneisEntradaSalaScreen> createState() => _AneisEntradaSalaScreenState();
}

class _AneisEntradaSalaScreenState extends State<AneisEntradaSalaScreen> {
  final _nomeController = TextEditingController();
  final _codigoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nomeController.text =
        ServiceLocator().storageService.getNomeJogador() ?? 'Jogador';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final provider = context.read<AneisSalaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Informe seu nome')));
      return;
    }

    await ServiceLocator().storageService.saveNomeJogador(nome);

    final ok = widget.criarSala
        ? await provider.criarSala(nome)
        : await provider.entrarNaSala(
            codigo: _codigoController.text,
            nome: nome,
          );

    if (!mounted) return;

    if (ok && provider.sala != null) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const AneisSalaRouterScreen()),
      );
    } else if (provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.criarSala ? 'Criar sala online' : 'Entrar na sala';

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                widget.criarSala ? Icons.add_home : Icons.login,
                size: 88,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Seu nome',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              if (!widget.criarSala) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código da sala',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                ),
              ],
              const Spacer(),
              Consumer<AneisSalaProvider>(
                builder: (context, provider, _) {
                  return PrimaryButton(
                    text: widget.criarSala ? 'Criar Sala' : 'Entrar',
                    icon: widget.criarSala ? Icons.add : Icons.login,
                    isLoading: provider.isLoading,
                    onPressed: _enviar,
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
