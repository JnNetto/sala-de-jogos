import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/time_formatter.dart';
import '../providers/categoria_provider.dart';
import '../providers/configuracao_provider.dart';
import '../providers/partida_provider.dart';
import '../widgets/config_card.dart';
import '../widgets/primary_button.dart';
import 'distribuicao_papeis_screen.dart';
import 'selecao_categorias_screen.dart';

class ConfiguracaoScreen extends StatefulWidget {
  const ConfiguracaoScreen({super.key});

  @override
  State<ConfiguracaoScreen> createState() => _ConfiguracaoScreenState();
}

class _ConfiguracaoScreenState extends State<ConfiguracaoScreen> {
  final List<TextEditingController> _nomeControllers = [];
  bool _mostrarNomes = false;
  bool _temMudancas = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ConfiguracaoProvider>().carregarConfiguracao();
      context.read<CategoriaProvider>().carregarCategorias();
      _inicializarControllers();
    });
  }

  void _inicializarControllers() {
    final config = context.read<ConfiguracaoProvider>().configuracao;
    _ajustarControllers(config.quantidadeJogadores, inicializando: true);
  }

  void _ajustarControllers(int quantidade, {bool inicializando = false}) {
    final config = context.read<ConfiguracaoProvider>().configuracao;

    // Remover listeners dos controllers existentes
    for (var controller in _nomeControllers) {
      controller.removeListener(_verificarMudancas);
    }

    if (_nomeControllers.length < quantidade) {
      // Adicionar novos controllers
      for (int i = _nomeControllers.length; i < quantidade; i++) {
        String nome;

        // Se estamos inicializando, usar nomes salvos da configuração
        if (inicializando && i < config.nomesJogadores.length) {
          nome = config.nomesJogadores[i];
        } else {
          // Senão, usar nome padrão para novos jogadores
          nome = 'Jogador ${i + 1}';
        }

        final controller = TextEditingController(text: nome);
        controller.addListener(_verificarMudancas);
        _nomeControllers.add(controller);
      }
    } else if (_nomeControllers.length > quantidade) {
      // Remover controllers do final
      while (_nomeControllers.length > quantidade) {
        _nomeControllers.removeLast().dispose();
      }
    }

    // Adicionar listeners aos controllers remanescentes
    for (var controller in _nomeControllers) {
      controller.addListener(_verificarMudancas);
    }

    // Se estamos inicializando, não marcar como tendo mudanças
    if (inicializando) {
      setState(() {
        _temMudancas = false;
      });
    } else {
      // Se ajustou o slider, verificar se há mudanças
      setState(() {});
      _verificarMudancas();
    }
  }

  void _verificarMudancas() {
    final config = context.read<ConfiguracaoProvider>().configuracao;
    final nomesAtuais = _nomeControllers.map((c) => c.text.trim()).toList();
    final nomesSalvos = config.nomesJogadores;

    bool mudou = false;

    // Comparar cada nome
    for (int i = 0; i < nomesAtuais.length; i++) {
      final nomeAtual = nomesAtuais[i];

      // Nome salvo ou nome padrão se não existir
      final nomeSalvo = i < nomesSalvos.length && nomesSalvos[i].isNotEmpty
          ? nomesSalvos[i]
          : 'Jogador ${i + 1}';

      if (nomeAtual != nomeSalvo) {
        mudou = true;
        break;
      }
    }

    if (_temMudancas != mudou) {
      setState(() {
        _temMudancas = mudou;
      });
    }
  }

  Future<void> _salvarNomes() async {
    final nomes = _nomeControllers.map((c) => c.text.trim()).toList();
    final provider = context.read<ConfiguracaoProvider>();
    provider.setNomesJogadores(nomes);
    await provider.salvar();

    setState(() {
      _temMudancas = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomes salvos com sucesso!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _nomeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Partida')),
      body: SafeArea(
        child: Consumer<ConfiguracaoProvider>(
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
                  subtitle: 'Quantidade total de jogadores',
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
                            '${AppConstants.minJogadores}-${AppConstants.maxJogadores}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Slider(
                        value: config.quantidadeJogadores.toDouble(),
                        min: AppConstants.minJogadores.toDouble(),
                        max: AppConstants.maxJogadores.toDouble(),
                        divisions:
                            AppConstants.maxJogadores -
                            AppConstants.minJogadores,
                        onChanged: (value) {
                          configProvider.setQuantidadeJogadores(value.toInt());
                          final maxEspioes = value.toInt() - 3;
                          if (config.quantidadeEspioes > maxEspioes) {
                            configProvider.setQuantidadeEspioes(
                              maxEspioes.clamp(1, maxEspioes),
                            );
                          }
                          _ajustarControllers(value.toInt());
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _mostrarNomes = !_mostrarNomes;
                            });
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
                    subtitle: 'Personalize o nome de cada jogador',
                    icon: Icons.edit,
                    child: Column(
                      children: [
                        for (int i = 0; i < _nomeControllers.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: TextField(
                              controller: _nomeControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Jogador ${i + 1}',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        if (_temMudancas) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _salvarNomes,
                              icon: const Icon(Icons.save),
                              label: const Text('Salvar Nomes'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ConfigCard(
                  title: 'Espiões',
                  subtitle: 'Quantidade de espiões na partida',
                  icon: Icons.visibility_off,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${config.quantidadeEspioes} ${config.quantidadeEspioes == 1 ? 'espião' : 'espiões'}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '1-${config.quantidadeJogadores - 3}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Slider(
                        value: config.quantidadeEspioes.toDouble(),
                        min: 1,
                        max: (config.quantidadeJogadores - 3).toDouble(),
                        divisions: config.quantidadeJogadores - 4 > 0
                            ? config.quantidadeJogadores - 4
                            : null,
                        onChanged: (value) {
                          configProvider.setQuantidadeEspioes(value.toInt());
                        },
                      ),
                    ],
                  ),
                ),
                ConfigCard(
                  title: 'Palavra para Espião',
                  subtitle: 'Espião vê uma palavra relacionada?',
                  icon: Icons.remove_red_eye,
                  child: SwitchListTile(
                    value: config.espiaoVePalavraRelacionada,
                    onChanged: (value) {
                      configProvider.setEspiaoVePalavraRelacionada(value);
                    },
                    title: Text(
                      config.espiaoVePalavraRelacionada
                          ? 'Espião vê palavra relacionada'
                          : 'Espião não vê nenhuma palavra',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                ConfigCard(
                  title: 'Duração da Discussão',
                  subtitle: 'Tempo para discussão',
                  icon: Icons.timer,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            TimeFormatter.formatarSegundos(
                              config.duracaoDiscussaoSegundos,
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '30s-10m',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Slider(
                        value: config.duracaoDiscussaoSegundos.toDouble(),
                        min: AppConstants.duracaoDiscussaoMinSegundos
                            .toDouble(),
                        max: AppConstants.duracaoDiscussaoMaxSegundos
                            .toDouble(),
                        divisions:
                            (AppConstants.duracaoDiscussaoMaxSegundos -
                                AppConstants.duracaoDiscussaoMinSegundos) ~/
                            30,
                        onChanged: (value) {
                          configProvider.setDuracaoDiscussao(value.toInt());
                        },
                      ),
                    ],
                  ),
                ),
                Consumer<CategoriaProvider>(
                  builder: (context, catProvider, _) {
                    return ConfigCard(
                      title: 'Categorias',
                      subtitle: catProvider.categoriasSelecionadas.isEmpty
                          ? 'Nenhuma categoria selecionada'
                          : '${catProvider.categoriasSelecionadas.length} de ${catProvider.categorias.length} selecionadas',
                      icon: Icons.category,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SelecaoCategoriasScreen(),
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
                  ConfiguracaoProvider,
                  CategoriaProvider,
                  PartidaProvider
                >(
                  builder: (context, configProv, catProv, partidaProv, _) {
                    final erro = configProv.validarConfiguracao();
                    final semCategorias =
                        catProv.categoriasSelecionadas.isEmpty;

                    return Column(
                      children: [
                        if (erro != null || semCategorias) ...[
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
                                        : erro!,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: 'Iniciar Partida',
                            icon: Icons.play_arrow,
                            isLoading: partidaProv.isLoading,
                            onPressed: (erro == null && !semCategorias)
                                ? () async {
                                    final navigator = Navigator.of(context);
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );

                                    configProv.setCategoriasAtivas(
                                      catProv.categoriasSelecionadas,
                                    );
                                    await configProv.salvar();

                                    final nomes = _nomeControllers
                                        .map((c) => c.text.trim())
                                        .where((name) => name.isNotEmpty)
                                        .toList();

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
                                              const DistribuicaoPapeisScreen(),
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
