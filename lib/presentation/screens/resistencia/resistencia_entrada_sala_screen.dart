import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/resistencia_sala_provider.dart';
import '../../widgets/primary_button.dart';
import 'resistencia_sala_router_screen.dart';

class ResistenciaEntradaSalaScreen extends StatefulWidget {
  final bool criarSala;

  const ResistenciaEntradaSalaScreen({super.key, required this.criarSala});

  @override
  State<ResistenciaEntradaSalaScreen> createState() =>
      _ResistenciaEntradaSalaScreenState();
}

class _ResistenciaEntradaSalaScreenState
    extends State<ResistenciaEntradaSalaScreen> {
  final _nomeController = TextEditingController(text: 'Jogador');
  final _codigoController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final provider = context.read<ResistenciaSalaProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Informe seu nome')));
      return;
    }

    final ok = widget.criarSala
        ? await provider.criarSala(nome)
        : await provider.entrarNaSala(
            codigo: _codigoController.text,
            nome: nome,
          );

    if (!mounted) return;

    if (ok && provider.sala != null) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const ResistenciaSalaRouterScreen()),
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
              Consumer<ResistenciaSalaProvider>(
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
