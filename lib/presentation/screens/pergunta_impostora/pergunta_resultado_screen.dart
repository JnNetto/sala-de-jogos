import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/enums/vencedor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/jogador_pergunta.dart';
import '../../../data/models/par_perguntas.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/primary_button.dart';
import 'pergunta_configuracao_screen.dart';
import 'pergunta_distribuicao_screen.dart';

class PerguntaResultadoScreen extends StatefulWidget {
  const PerguntaResultadoScreen({super.key});

  @override
  State<PerguntaResultadoScreen> createState() =>
      _PerguntaResultadoScreenState();
}

class _PerguntaResultadoScreenState extends State<PerguntaResultadoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  late Vencedor _vencedor;
  late ParPerguntas _par;
  late List<JogadorPergunta> _civis;
  late List<JogadorPergunta> _espioes;
  late List<JogadorPergunta> _jogadores;

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

    final partida = context.read<PerguntaPartidaProvider>().partida!;
    _vencedor = partida.vencedor;
    _par = partida.par;
    _civis = List.from(partida.civis);
    _espioes = List.from(partida.espioes);
    _jogadores = List.from(partida.jogadores);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerguntaPartidaProvider>().finalizarPartida();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      Icon(
                        civisVenceram ? Icons.group : Icons.help_outline,
                        size: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        civisVenceram
                            ? 'Civis Venceram!'
                            : 'Impostores Venceram!',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pergunta de Todos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _par.principal,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: backgroundColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Pergunta do Impostor',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _par.impostor,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: backgroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Respostas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._jogadores.map(
                        (j) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${j.nome}${j.isEspiao ? ' (impostor)' : ''}: "${j.resposta ?? '—'}"',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Civis: ${_civis.map((j) => j.nome).join(', ')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Impostores: ${_espioes.map((j) => j.nome).join(', ')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<PerguntaPartidaProvider>(
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
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final sucesso = await provider.jogarNovamente();
                              if (!mounted) return;
                              if (sucesso) {
                                navigator.pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PerguntaDistribuicaoScreen(),
                                  ),
                                  (route) => route.isFirst,
                                );
                              } else {
                                messenger.showSnackBar(
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
                                      const PerguntaConfiguracaoScreen(),
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
}
