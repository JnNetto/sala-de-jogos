import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/enums/vencedor.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/jogador_partida.dart';
import '../../data/models/palavra.dart';
import '../providers/partida_provider.dart';
import '../widgets/primary_button.dart';
import 'configuracao_screen.dart';
import 'distribuicao_papeis_screen.dart';

class ResultadoScreen extends StatefulWidget {
  const ResultadoScreen({super.key});

  @override
  State<ResultadoScreen> createState() => _ResultadoScreenState();
}

class _ResultadoScreenState extends State<ResultadoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Captura os dados da partida para evitar que sejam atualizados
  // quando "Jogar Novamente" for clicado
  late Vencedor _vencedor;
  late Palavra _palavraSecreta;
  Palavra? _palavraRelacionada;
  late List<JogadorPartida> _civis;
  late List<JogadorPartida> _espioes;
  late List<JogadorPartida> _jogadoresEliminados;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();

    // Captura os dados da partida atual antes de finalizar
    final partida = context.read<PartidaProvider>().partida;
    if (partida != null) {
      _vencedor = partida.vencedor;
      _palavraSecreta = partida.palavraSecreta;
      _palavraRelacionada = partida.palavraRelacionada;
      _civis = List.from(partida.civis);
      _espioes = List.from(partida.espioes);
      _jogadoresEliminados = List.from(partida.jogadoresEliminados);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartidaProvider>().finalizarPartida();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final civisVenceram = _vencedor == Vencedor.civis;
    final backgroundColor = civisVenceram
        ? AppTheme.civilColor
        : AppTheme.espiaoColor;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      Icon(
                        civisVenceram ? Icons.group : Icons.visibility_off,
                        size: 120,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _vencedor.displayName,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Palavra secreta:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  _palavraSecreta.texto,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: backgroundColor,
                                  ),
                                ),
                              ],
                            ),
                            if (_palavraRelacionada != null) ...[
                              const SizedBox(height: 12),
                              Divider(color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Palavra do espião:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    _palavraRelacionada!.texto,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: backgroundColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Resumo da Partida',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildResumoItem(
                        'Civis',
                        _civis.map((j) => j.nome).join(', '),
                      ),
                      const SizedBox(height: 12),
                      _buildResumoItem(
                        'Espiões',
                        _espioes.map((j) => j.nome).join(', '),
                      ),
                      const SizedBox(height: 12),
                      _buildResumoItem(
                        'Eliminados',
                        _jogadoresEliminados.isEmpty
                            ? 'Ninguém'
                            : _jogadoresEliminados
                                  .map((j) => j.nome)
                                  .join(', '),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<PartidaProvider>(
                  builder: (context, provider, _) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: 'Jogar Novamente',
                            icon: Icons.refresh,
                            backgroundColor: Colors.white,
                            textColor: backgroundColor,
                            onPressed: () async {
                              final sucesso = await provider.jogarNovamente();
                              if (sucesso && mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DistribuicaoPapeisScreen(),
                                  ),
                                  (route) => route.isFirst,
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      provider.erro ??
                                          'Erro ao iniciar partida',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              provider.encerrarPartida();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ConfiguracaoScreen(),
                                ),
                                (route) => route.isFirst,
                              );
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Voltar ao Início'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}
