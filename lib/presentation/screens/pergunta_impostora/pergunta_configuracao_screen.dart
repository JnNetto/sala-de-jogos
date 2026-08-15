import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/pergunta_impostora_constants.dart';
import '../../../core/utils/time_formatter.dart';
import '../../providers/pergunta_categoria_provider.dart';
import '../../providers/pergunta_configuracao_provider.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/config_card.dart';
import '../../widgets/primary_button.dart';
import 'pergunta_distribuicao_screen.dart';
import 'pergunta_selecao_categorias_screen.dart';

class PerguntaConfiguracaoScreen extends StatefulWidget {
  const PerguntaConfiguracaoScreen({super.key});

  @override
  State<PerguntaConfiguracaoScreen> createState() =>
      _PerguntaConfiguracaoScreenState();
}

class _PerguntaConfiguracaoScreenState
    extends State<PerguntaConfiguracaoScreen> {
  final List<TextEditingController> _nomeControllers = [];
  bool _mostrarNomes = false;

  static const _labelsNivel = {1: 'Fácil', 2: 'MéMédio', 3: 'Difícil'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final configProv = context.read<PerguntaConfiguracaoProvider>();
      final catProv = context.read<PerguntaCategoriaProvider>();
      await configProv.carregarConfiguracao();
      catProv.carregarCategorias(
        idsSalvos: configProv.configuracao.categoriasAtivasIds,
        niveisSalvos: configProv.configuracao.niveisAtivos,
      );
      _ajustarControllers(
        configProv.configuracao.quantidadeJogadores,
        inicializando: true,
      );
    });
  }

  void _ajustarControllers(int quantidade, {bool inicializando = false}) {
    final config = context.read<PerguntaConfiguracaoProvider>().configuracao;

    if (_nomeControllers.length < quantidade) {
      for (int i = _nomeControllers.length; i < quantidade; i++) {
        final nome = inicializando && i < config.nomesJogadores.length
            ? config.nomesJogadores[i]
            : 'Jogador ${i + 1}';
        _nomeControllers.add(TextEditingController(text: nome));
      }
    } else if (_nomeControllers.length > quantidade) {
      while (_nomeControllers.length > quantidade) {
        _nomeControllers.removeLast().dispose();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in _nomeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Partida')),
      body: SafeArea(
        child: Consumer<PerguntaConfiguracaoProvider>(
          builder: (context, configProvider, _) {
            if (configProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final config = configProvider.configuracao;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ConfigCard(
                  title: 'Jogadores',
                  subtitle: 'Mínimo 3 · ideal 5–8',
                  icon: Icons.group,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${config.quantidadeJogadores} jogadores',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${PerguntaImpostoraConstants.minJogadores}-${PerguntaImpostoraConstants.maxJogadores}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Slider(
                        value: config.quantidadeJogadores.toDouble(),
                        min: PerguntaImpostoraConstants.minJogadores.toDouble(),
                        max: PerguntaImpostoraConstants.maxJogadores.toDouble(),
                        divisions:
                            PerguntaImpostoraConstants.maxJogadores -
                            PerguntaImpostoraConstants.minJogadores,
                        onChanged: (value) {
                          configProvider.setQuantidadeJogadores(value.toInt());
                          _ajustarControllers(value.toInt());
                        },
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _mostrarNomes = !_mostrarNomes);
                          },
                          icon: Icon(
                            _mostrarNomes
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          label: Text(
                            _mostrarNomes
                                ? 'Ocultar Nomes'
                                : 'Editar Nomes dos Jogadores',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_mostrarNomes)
                  ConfigCard(
                    title: 'Nomes dos Jogadores',
                    icon: Icons.edit,
                    child: Column(
                      children: [
                        for (int i = 0; i < _nomeControllers.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: _nomeControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Jogador ${i + 1}',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                      ],
                    ),
                  ),
                ConfigCard(
                  title: 'Impostores',
                  subtitle: 'Quantidade de impostores',
                  icon: Icons.help_outline,
                  child: Column(
                    children: [
                      Text(
                        '${config.quantidadeImpostores} ${config.quantidadeImpostores == 1 ? 'impostor' : 'impostores'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: config.quantidadeImpostores.toDouble(),
                        min: 1,
                        max: config.maxImpostores.toDouble(),
                        divisions: config.maxImpostores > 1
                            ? config.maxImpostores - 1
                            : null,
                        onChanged: (value) {
                          configProvider.setQuantidadeImpostores(value.toInt());
                        },
                      ),
                    ],
                  ),
                ),
                ConfigCard(
                  title: 'Vitória do Impostor',
                  subtitle:
                      'Quantos jogadores devem sobrar (incluindo o impostor) para ele ganhar',
                  icon: Icons.flag,
                  child: Column(
                    children: [
                      Text(
                        '${config.limiarVitoriaImpostorClamped} ${config.limiarVitoriaImpostorClamped == 1 ? 'jogador' : 'jogadores'} restantes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: config.limiarVitoriaImpostorClamped.toDouble(),
                        min: config.minLimiarVitoriaImpostor.toDouble(),
                        max: config.maxLimiarVitoriaImpostor.toDouble(),
                        divisions:
                            config.maxLimiarVitoriaImpostor >
                                config.minLimiarVitoriaImpostor
                            ? config.maxLimiarVitoriaImpostor -
                                  config.minLimiarVitoriaImpostor
                            : null,
                        onChanged: (value) {
                          configProvider
                              .setJogadoresRestantesParaVitoriaImpostor(
                                value.toInt(),
                              );
                        },
                      ),
                      Text(
                        'Padrão: ${config.quantidadeJogadores - 1} (uma pessoa a menos que o total)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                ConfigCard(
                  title: 'Duração da Discussão',
                  icon: Icons.timer,
                  child: Column(
                    children: [
                      Text(
                        TimeFormatter.formatarSegundos(
                          config.duracaoDiscussaoSegundos,
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: config.duracaoDiscussaoSegundos.toDouble(),
                        min: PerguntaImpostoraConstants
                            .duracaoDiscussaoMinSegundos
                            .toDouble(),
                        max: PerguntaImpostoraConstants
                            .duracaoDiscussaoMaxSegundos
                            .toDouble(),
                        divisions:
                            (PerguntaImpostoraConstants
                                    .duracaoDiscussaoMaxSegundos -
                                PerguntaImpostoraConstants
                                    .duracaoDiscussaoMinSegundos) ~/
                            30,
                        onChanged: (value) {
                          configProvider.setDuracaoDiscussao(value.toInt());
                        },
                      ),
                    ],
                  ),
                ),
                Consumer<PerguntaCategoriaProvider>(
                  builder: (context, catProvider, _) {
                    return ConfigCard(
                      title: 'Dificuldade',
                      subtitle: 'Nível de sutileza das perguntas',
                      icon: Icons.tune,
                      child: Wrap(
                        spacing: 8,
                        children: [1, 2, 3].map((nivel) {
                          final selecionado = catProvider.isNivelSelecionado(
                            nivel,
                          );
                          return FilterChip(
                            label: Text(_labelsNivel[nivel]!),
                            selected: selecionado,
                            onSelected: (_) => catProvider.toggleNivel(nivel),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                Consumer<PerguntaCategoriaProvider>(
                  builder: (context, catProvider, _) {
                    return ConfigCard(
                      title: 'Categorias',
                      subtitle: catProvider.categoriasSelecionadas.isEmpty
                          ? 'Nenhuma categoria selecionada'
                          : '${catProvider.categoriasSelecionadas.length} selecionadas · ${catProvider.getQuantidadeTotalPares()} perguntas',
                      icon: Icons.category,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PerguntaSelecaoCategoriasScreen(),
                              ),
                            );
                            setState(() {});
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Selecionar Categorias'),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Consumer3<
                  PerguntaConfiguracaoProvider,
                  PerguntaCategoriaProvider,
                  PerguntaPartidaProvider
                >(
                  builder: (context, configProv, catProv, partidaProv, _) {
                    final erro = configProv.validarConfiguracao();
                    final semCategorias =
                        catProv.categoriasSelecionadas.isEmpty;
                    final semNiveis = catProv.niveisSelecionados.isEmpty;

                    return Column(
                      children: [
                        if (erro != null || semCategorias || semNiveis)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.orange),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    semCategorias
                                        ? 'Selecione pelo menos uma categoria'
                                        : semNiveis
                                        ? 'Selecione pelo menos um nível'
                                        : erro!,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: 'Iniciar Partida',
                            icon: Icons.play_arrow,
                            isLoading: partidaProv.isLoading,
                            onPressed:
                                (erro == null && !semCategorias && !semNiveis)
                                ? () async {
                                    final navigator = Navigator.of(context);
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );

                                    configProv.setCategoriasAtivas(
                                      catProv.categoriasSelecionadas,
                                    );
                                    configProv.setNiveisAtivos(
                                      catProv.niveisSelecionados,
                                    );

                                    final nomes = _nomeControllers
                                        .map((c) => c.text.trim())
                                        .where((n) => n.isNotEmpty)
                                        .toList();
                                    configProv.setNomesJogadores(nomes);
                                    await configProv.salvar();

                                    final sucesso = await partidaProv
                                        .iniciarNovaPartida(
                                          configuracao: configProv.configuracao,
                                          nomesJogadores: nomes.isNotEmpty
                                              ? nomes
                                              : null,
                                        );

                                    if (sucesso && mounted) {
                                      navigator.push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PerguntaDistribuicaoScreen(),
                                        ),
                                      );
                                    } else if (partidaProv.erro != null &&
                                        mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(partidaProv.erro!),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                          ),
                        ),
                      ],
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
