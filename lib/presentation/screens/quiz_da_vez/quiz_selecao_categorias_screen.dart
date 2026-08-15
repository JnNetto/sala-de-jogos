import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_categoria_provider.dart';

class QuizSelecaoCategoriasScreen extends StatelessWidget {
  const QuizSelecaoCategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              final p = context.read<QuizCategoriaProvider>();
              if (v == 'todas') p.selecionarTodas();
              if (v == 'nenhuma') p.deselecionarTodas();
              if (v == 'sortear') p.sortear();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'todas', child: Text('Todas')),
              PopupMenuItem(value: 'nenhuma', child: Text('Nenhuma')),
              PopupMenuItem(value: 'sortear', child: Text('Sortear 3')),
            ],
          ),
        ],
      ),
      body: Consumer<QuizCategoriaProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              if (provider.selecionadas.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    '${provider.selecionadas.length} categorias · ${provider.totalDisponivel()} perguntas',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.categorias.length,
                  itemBuilder: (context, i) {
                    final cat = provider.categorias[i];
                    return CheckboxListTile(
                      value: provider.isSelecionada(cat),
                      onChanged: (_) => provider.toggle(cat),
                      title: Text(cat),
                      subtitle: Text('${provider.quantidade(cat)} perguntas'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
