import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/quiz_da_vez_constants.dart';
import '../../../core/enums/modo_passe_quiz.dart';
import '../../providers/quiz_categoria_provider.dart';
import '../../providers/quiz_configuracao_provider.dart';
import '../../providers/quiz_partida_provider.dart';
import '../../widgets/config_card.dart';
import '../../widgets/primary_button.dart';
import 'quiz_passagem_screen.dart';
import 'quiz_selecao_categorias_screen.dart';

class QuizConfiguracaoScreen extends StatefulWidget {
  const QuizConfiguracaoScreen({super.key});

  @override
  State<QuizConfiguracaoScreen> createState() => _QuizConfiguracaoScreenState();
}

class _QuizConfiguracaoScreenState extends State<QuizConfiguracaoScreen> {
  final List<TextEditingController> _nomes = [];
  bool _mostrarNomes = false;

  static const _difLabels = {1: 'Fácil', 2: 'MéMédio', 3: 'Difícil'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final config = context.read<QuizConfiguracaoProvider>();
      final cats = context.read<QuizCategoriaProvider>();
      await config.carregar();
      cats.carregar(
        salvas: config.configuracao.categoriasAtivas,
        dificuldades: config.configuracao.dificuldadesAtivas,
      );
      _ajustar(config.configuracao.quantidadeJogadores, init: true);
    });
  }

  void _ajustar(int qtd, {bool init = false}) {
    final config = context.read<QuizConfiguracaoProvider>().configuracao;
    while (_nomes.length < qtd) {
      final i = _nomes.length;
      final nome = init && i < config.nomesJogadores.length
          ? config.nomesJogadores[i]
          : 'Jogador ${i + 1}';
      _nomes.add(TextEditingController(text: nome));
    }
    while (_nomes.length > qtd) {
      _nomes.removeLast().dispose();
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in _nomes) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Partida')),
      body: SafeArea(
        child: Consumer<QuizConfiguracaoProvider>(
          builder: (context, configProv, _) {
            if (configProv.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final config = configProv.configuracao;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ConfigCard(
                  title: 'Jogadores',
                  subtitle:
                      '${QuizDaVezConstants.minJogadores}–${QuizDaVezConstants.maxJogadores}',
                  icon: Icons.group,
                  child: Column(
                    children: [
                      Text(
                        '${config.quantidadeJogadores} jogadores',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: config.quantidadeJogadores.toDouble(),
                        min: QuizDaVezConstants.minJogadores.toDouble(),
                        max: QuizDaVezConstants.maxJogadores.toDouble(),
                        divisions:
                            QuizDaVezConstants.maxJogadores -
                            QuizDaVezConstants.minJogadores,
                        onChanged: (v) {
                          configProv.setQuantidadeJogadores(v.toInt());
                          _ajustar(v.toInt());
                        },
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _mostrarNomes = !_mostrarNomes),
                        icon: Icon(
                          _mostrarNomes ? Icons.expand_less : Icons.expand_more,
                        ),
                        label: Text(
                          _mostrarNomes ? 'Ocultar nomes' : 'Editar nomes',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_mostrarNomes)
                  ConfigCard(
                    title: 'Nomes',
                    icon: Icons.edit,
                    child: Column(
                      children: [
                        for (int i = 0; i < _nomes.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextField(
                              controller: _nomes[i],
                              decoration: InputDecoration(
                                labelText: 'Jogador ${i + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ConfigCard(
                  title: 'Perguntas por jogador',
                  subtitle: 'Total: ${config.totalRodadas} rodadas',
                  icon: Icons.format_list_numbered,
                  child: Column(
                    children: [
                      Text(
                        '${config.perguntasPorJogador}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: config.perguntasPorJogador.toDouble(),
                        min: QuizDaVezConstants.minPerguntasPorJogador
                            .toDouble(),
                        max: QuizDaVezConstants.maxPerguntasPorJogador
                            .toDouble(),
                        divisions:
                            QuizDaVezConstants.maxPerguntasPorJogador -
                            QuizDaVezConstants.minPerguntasPorJogador,
                        onChanged: (v) =>
                            configProv.setPerguntasPorJogador(v.toInt()),
                      ),
                    ],
                  ),
                ),
                ConfigCard(
                  title: 'Tempo por pergunta',
                  icon: Icons.timer,
                  child: Column(
                    children: [
                      Text(
                        '${config.tempoPerguntaSegundos}s',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: config.tempoPerguntaSegundos.toDouble(),
                        min: QuizDaVezConstants.tempoPerguntaMinSegundos
                            .toDouble(),
                        max: QuizDaVezConstants.tempoPerguntaMaxSegundos
                            .toDouble(),
                        divisions:
                            (QuizDaVezConstants.tempoPerguntaMaxSegundos -
                                QuizDaVezConstants.tempoPerguntaMinSegundos) ~/
                            5,
                        onChanged: (v) =>
                            configProv.setTempoPergunta(v.toInt()),
                      ),
                    ],
                  ),
                ),
                ConfigCard(
                  title: 'Modo de passe',
                  icon: Icons.swap_horiz,
                  child: Column(
                    children: ModoPasseQuiz.values.map((modo) {
                      final selecionado = config.modoPasse == modo;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: selecionado
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12)
                            : null,
                        child: ListTile(
                          leading: Icon(
                            selecionado
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(modo.displayName),
                          subtitle: Text(modo.descricao),
                          onTap: () => configProv.setModoPasse(modo),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                ConfigCard(
                  title: 'Placar',
                  subtitle: 'Exibir placar ao final de cada rodada?',
                  icon: Icons.leaderboard,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: config.mostrarPlacarAposRodada,
                    title: Text(
                      config.mostrarPlacarAposRodada
                          ? 'Mostrar placar após cada rodada'
                          : 'Ocultar placar até o fim',
                    ),
                    onChanged: configProv.setMostrarPlacarAposRodada,
                  ),
                ),
                Consumer<QuizCategoriaProvider>(
                  builder: (context, catProv, _) {
                    return ConfigCard(
                      title: 'Dificuldade',
                      icon: Icons.tune,
                      child: Wrap(
                        spacing: 8,
                        children: [1, 2, 3].map((d) {
                          return FilterChip(
                            label: Text(_difLabels[d]!),
                            selected: catProv.isDificuldadeSelecionada(d),
                            onSelected: (_) => catProv.toggleDificuldade(d),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                Consumer<QuizCategoriaProvider>(
                  builder: (context, catProv, _) {
                    return ConfigCard(
                      title: 'Categorias',
                      subtitle: catProv.selecionadas.isEmpty
                          ? 'Nenhuma selecionada'
                          : '${catProv.selecionadas.length} · ${catProv.totalDisponivel()} perguntas',
                      icon: Icons.category,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const QuizSelecaoCategoriasScreen(),
                            ),
                          );
                          setState(() {});
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Selecionar'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer3<
                  QuizConfiguracaoProvider,
                  QuizCategoriaProvider,
                  QuizPartidaProvider
                >(
                  builder: (context, configP, catP, partidaP, _) {
                    final erro = configP.validar();
                    final semCat = catP.selecionadas.isEmpty;
                    return PrimaryButton(
                      text: 'Iniciar Partida',
                      icon: Icons.play_arrow,
                      isLoading: partidaP.isLoading,
                      onPressed: (erro == null && !semCat)
                          ? () async {
                              final nav = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              configP.setCategorias(catP.selecionadas);
                              configP.setDificuldades(
                                catP.dificuldadesSelecionadas,
                              );
                              final nomes = _nomes
                                  .map((c) => c.text.trim())
                                  .where((n) => n.isNotEmpty)
                                  .toList();
                              configP.setNomes(nomes);
                              await configP.salvar();

                              final ok = await partidaP.iniciarPartida(
                                configuracao: configP.configuracao,
                                nomes: nomes.isNotEmpty ? nomes : null,
                              );
                              if (ok && mounted) {
                                nav.push(
                                  MaterialPageRoute(
                                    builder: (_) => const QuizPassagemScreen(),
                                  ),
                                );
                              } else if (partidaP.erro != null && mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(partidaP.erro!),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          : null,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
