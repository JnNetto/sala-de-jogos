import 'package:flutter/material.dart';
import '../../core/models/jogo_disponivel.dart';

class JogoCard extends StatelessWidget {
  final JogoDisponivel jogo;
  final VoidCallback? onTap;

  const JogoCard({super.key, required this.jogo, this.onTap});

  @override
  Widget build(BuildContext context) {
    final habilitado = jogo.disponivel && onTap != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: habilitado ? onTap : null,
        child: Opacity(
          opacity: habilitado ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: jogo.cor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(jogo.icone, size: 32, color: jogo.cor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jogo.nome,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jogo.descricao,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
