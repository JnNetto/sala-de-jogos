import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pergunta_categoria_provider.dart';

class PerguntaSelecaoCategoriasScreen extends StatelessWidget {
  const PerguntaSelecaoCategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Categorias'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final provider = context.read<PerguntaCategoriaProvider>();
              if (value == 'todas') {
                provider.selecionarTodas();
              } else if (value == 'nenhuma') {
                provider.deselecionarTodas();
              } else if (value == 'sortear') {
                provider.sortearCategorias(quantidade: 3);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'todas', child: Text('Selecionar Todas')),
              PopupMenuItem(
                value: 'nenhuma',
                child: Text('Desselecionar Todas'),
              ),
              PopupMenuItem(
                value: 'sortear',
                child: Text('Sortear 3 Categorias'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<PerguntaCategoriaProvider>(
          builder: (context, provider, _) {
            if (provider.categorias.isEmpty) {
              return const Center(child: Text('Nenhuma categoria disponível'));
            }

            return Column(
              children: [
                if (provider.categoriasSelecionadas.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    child: Column(
                      children: [
                        Text(
                          '${provider.categoriasSelecionadas.length} categorias selecionadas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.getQuantidadeTotalPares()} perguntas disponíveis',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = provider.categorias[index];
                      final selecionada = provider.isSelecionada(categoria.id);
                      final qtd = provider.getQuantidadePares(categoria.id);

                      return Card(
                        child: CheckboxListTile(
                          value: selecionada,
                          onChanged: (_) =>
                              provider.toggleCategoria(categoria.id),
                          title: Text(categoria.nome),
                          subtitle: Text('$qtd perguntas'),
                          secondary: Icon(
                            Icons.category,
                            color: selecionada
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
