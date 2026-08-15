import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/categoria_provider.dart';

class SelecaoCategoriasScreen extends StatelessWidget {
  const SelecaoCategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Categorias'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final provider = context.read<CategoriaProvider>();
              switch (value) {
                case 'todas':
                  provider.selecionarTodas();
                  break;
                case 'nenhuma':
                  provider.deselecionarTodas();
                  break;
                case 'sortear':
                  provider.sortearCategorias(quantidade: 3);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todas',
                child: Row(
                  children: [
                    Icon(Icons.check_box),
                    SizedBox(width: 12),
                    Text('Selecionar Todas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'nenhuma',
                child: Row(
                  children: [
                    Icon(Icons.check_box_outline_blank),
                    SizedBox(width: 12),
                    Text('Desselecionar Todas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sortear',
                child: Row(
                  children: [
                    Icon(Icons.shuffle),
                    SizedBox(width: 12),
                    Text('Sortear 3 Categorias'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<CategoriaProvider>(
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
                          '${provider.categoriasSelecionadas.length} ${provider.categoriasSelecionadas.length == 1 ? 'categoria selecionada' : 'categorias selecionadas'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.getQuantidadeTotalPalavras()} ${provider.getQuantidadeTotalPalavras() == 1 ? 'palavra disponível' : 'palavras disponíveis'}',
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
                      final isSelecionada = provider.isSelecionada(
                        categoria.id,
                      );
                      final qtdPalavras = provider.getQuantidadePalavras(
                        categoria.id,
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: CheckboxListTile(
                          value: isSelecionada,
                          onChanged: (value) {
                            provider.toggleCategoria(categoria.id);
                          },
                          title: Text(
                            categoria.nome,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (categoria.descricao != null) ...[
                                const SizedBox(height: 4),
                                Text(categoria.descricao!),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '$qtdPalavras ${qtdPalavras == 1 ? 'palavra' : 'palavras'}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelecionada
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.category,
                              color: isSelecionada
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
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
      bottomNavigationBar: Consumer<CategoriaProvider>(
        builder: (context, provider, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: provider.categoriasSelecionadas.isEmpty
                    ? null
                    : () => Navigator.pop(context),
                child: const Text('Confirmar Seleção'),
              ),
            ),
          );
        },
      ),
    );
  }
}
