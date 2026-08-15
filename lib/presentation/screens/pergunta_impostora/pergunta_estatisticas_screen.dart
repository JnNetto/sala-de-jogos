import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/service_locator.dart';
import '../../../data/models/estatisticas.dart';

class PerguntaEstatisticasScreen extends StatefulWidget {
  const PerguntaEstatisticasScreen({super.key});

  @override
  State<PerguntaEstatisticasScreen> createState() =>
      _PerguntaEstatisticasScreenState();
}

class _PerguntaEstatisticasScreenState
    extends State<PerguntaEstatisticasScreen> {
  Estatisticas? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    final stats = await ServiceLocator().storageService
        .getEstatisticasPergunta();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _limpar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar estatísticas?'),
        content: const Text('Esta ação não pode ser desfeita.'),
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
      await ServiceLocator().storageService.saveEstatisticasPergunta(
        Estatisticas(),
      );
      await _carregar();
    }
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
              onPressed: _limpar,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _stats == null || _stats!.partidasJogadas == 0
            ? Center(
                child: Text(
                  'Nenhuma partida jogada ainda',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _statCard(
                    'Partidas',
                    '${_stats!.partidasJogadas}',
                    Icons.sports_esports,
                    Theme.of(context).colorScheme.primary,
                  ),
                  _statCard(
                    'Vitórias dos Civis',
                    '${_stats!.vitoriasCivis} (${_stats!.percentualVitoriasCivis.toStringAsFixed(0)}%)',
                    Icons.group,
                    AppTheme.civilColor,
                  ),
                  _statCard(
                    'Vitórias dos Impostores',
                    '${_stats!.vitoriasEspioes} (${_stats!.percentualVitoriasEspioes.toStringAsFixed(0)}%)',
                    Icons.help_outline,
                    AppTheme.espiaoColor,
                  ),
                  _statCard(
                    'Tempo méMédio',
                    _stats!.tempoMedioFormatado,
                    Icons.timer,
                    Colors.orange,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
