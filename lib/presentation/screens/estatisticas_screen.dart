import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/service_locator.dart';
import '../../data/models/estatisticas.dart';

class EstatisticasScreen extends StatefulWidget {
  const EstatisticasScreen({super.key});

  @override
  State<EstatisticasScreen> createState() => _EstatisticasScreenState();
}

class _EstatisticasScreenState extends State<EstatisticasScreen> {
  final _estatisticasService = ServiceLocator().estatisticasService;
  Estatisticas? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    setState(() => _isLoading = true);
    final stats = await _estatisticasService.getEstatisticas();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas'),
        actions: [
          if (_stats != null && _stats!.partidasJogadas > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmarLimpar(),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _stats == null || _stats!.partidasJogadas == 0
            ? _buildEmptyState()
            : _buildStats(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma partida jogada ainda',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Jogue algumas partidas para ver suas estatísticas',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          icon: Icons.sports_esports,
          title: 'Partidas Jogadas',
          value: '${_stats!.partidasJogadas}',
          color: AppTheme.primaryColor,
        ),
        _buildStatCard(
          icon: Icons.group,
          title: 'Vitórias dos Civis',
          value: '${_stats!.vitoriasCivis}',
          subtitle: '${_stats!.percentualVitoriasCivis.toStringAsFixed(1)}%',
          color: AppTheme.civilColor,
        ),
        _buildStatCard(
          icon: Icons.visibility_off,
          title: 'Vitórias dos Espiões',
          value: '${_stats!.vitoriasEspioes}',
          subtitle: '${_stats!.percentualVitoriasEspioes.toStringAsFixed(1)}%',
          color: AppTheme.espiaoColor,
        ),
        _buildStatCard(
          icon: Icons.timer,
          title: 'Tempo MéMédio de Partida',
          value: _stats!.tempoMedioFormatado,
          color: AppTheme.secondaryColor,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarLimpar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Estatísticas'),
        content: const Text(
          'Tem certeza que deseja limpar todas as estatísticasó Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _estatisticasService.limparEstatisticas();
      _carregarEstatisticas();
    }
  }
}
