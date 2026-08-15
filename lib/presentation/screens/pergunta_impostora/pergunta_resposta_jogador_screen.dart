import 'package:flutter/material.dart';
import '../../../data/models/jogador_pergunta.dart';
import '../../widgets/primary_button.dart';

class PerguntaRespostaJogadorScreen extends StatefulWidget {
  final JogadorPergunta jogador;
  final String pergunta;

  const PerguntaRespostaJogadorScreen({
    super.key,
    required this.jogador,
    required this.pergunta,
  });

  @override
  State<PerguntaRespostaJogadorScreen> createState() =>
      _PerguntaRespostaJogadorScreenState();
}

class _PerguntaRespostaJogadorScreenState
    extends State<PerguntaRespostaJogadorScreen> {
  final _controller = TextEditingController();
  bool _mostrarPergunta = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.jogador.nome),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _mostrarPergunta
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sua pergunta',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.pergunta,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Sua resposta',
                          border: OutlineInputBorder(),
                          hintText: 'Resposta curta',
                        ),
                        maxLength: 80,
                        onChanged: (_) => setState(() {}),
                      ),
                      const Spacer(),
                      PrimaryButton(
                        text: 'Confirmar Resposta',
                        icon: Icons.check,
                        onPressed: _controller.text.trim().isEmpty
                            ? null
                            : () => Navigator.pop(
                                context,
                                _controller.text.trim(),
                              ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Center(
                        child: Icon(
                          Icons.edit,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.jogador.nome,
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Só você deve olhar a tela para responder',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      PrimaryButton(
                        text: 'Responder',
                        icon: Icons.visibility,
                        onPressed: () =>
                            setState(() => _mostrarPergunta = true),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
