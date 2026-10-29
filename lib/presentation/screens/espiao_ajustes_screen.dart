import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/sala_tokens.dart';
import '../providers/categoria_provider.dart';
import '../providers/configuracao_provider.dart';
import '../providers/partida_provider.dart';
import '../widgets/sala/botao_sala.dart';
import '../widgets/sala/cartao_config.dart';
import '../widgets/sala/cronometro.dart';
import '../widgets/sala/folha_categorias.dart';
import '../widgets/sala/tela_da_sala.dart';
import 'distribuicao_papeis_screen.dart';

/// Passo 2 do Quem é o Espião?: o que o espião recebe, quanto tempo dura a
/// conversa e de onde vem a palavra. "Começar" sorteia tudo e leva à
/// revelação.
class EspiaoAjustesScreen extends StatefulWidget {
  const EspiaoAjustesScreen({super.key});

  @override
  State<EspiaoAjustesScreen> createState() => _EspiaoAjustesScreenState();
}

class _EspiaoAjustesScreenState extends State<EspiaoAjustesScreen> {
  static const _recomendado = 300;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categorias = context.read<CategoriaProvider>();
      categorias.carregarCategorias();
      // Volta com a seleção da última partida, se ainda existir.
      final salvas = context
          .read<ConfiguracaoProvider>()
          .configuracao
          .categoriasAtivasIds
          .where((id) => categorias.categorias.any((c) => c.id == id))
          .toList();
      if (salvas.isNotEmpty) {
        categorias.deselecionarTodas();
        salvas.forEach(categorias.toggleCategoria);
      }
    });
  }

  Future<void> _comecar() async {
    final config = context.read<ConfiguracaoProvider>();
    final categorias = context.read<CategoriaProvider>();
    final partida = context.read<PartidaProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    config.setCategoriasAtivas(List.of(categorias.categoriasSelecionadas));
    await config.salvar();
    final nomes = config.configuracao.nomesJogadores;
    final sucesso = await partida.iniciarNovaPartida(
      configuracao: config.configuracao,
      nomesJogadores: nomes.isNotEmpty ? nomes : null,
    );
    if (!mounted) return;
    if (sucesso) {
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const DistribuicaoPapeisScreen(),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            partida.erro ??
                'Não deu para sortear a palavra. Escolha outras categorias.',
          ),
        ),
      );
    }
  }

  static FonteDeCategorias _fonte(CategoriaProvider p) => FonteDeCategorias(
    ouvir: p,
    opcoes: () => [
      for (final c in p.categorias)
        (id: c.id, nome: c.nome, quantidade: p.getQuantidadePalavras(c.id)),
    ],
    selecionada: p.isSelecionada,
    alternar: p.toggleCategoria,
    todas: p.selecionarTodas,
    nenhuma: p.deselecionarTodas,
    sortear: () => p.sortearCategorias(quantidade: 3),
    total: p.getQuantidadeTotalPalavras,
    singular: 'palavra',
    plural: 'palavras',
  );

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(Matiz.violeta);
    final provider = context.watch<ConfiguracaoProvider>();
    final categorias = context.watch<CategoriaProvider>();
    final carregando = context.select<PartidaProvider, bool>(
      (p) => p.isLoading,
    );
    final config = provider.configuracao;
    final pista = config.espiaoVePalavraRelacionada;

    return TelaDaSala(
      sobretitulo: 'PASSO 2 DE 2',
      titulo: 'Quem é o Espião?',
      matiz: Matiz.violeta,
      corpo: ListView(
        padding: const EdgeInsets.fromLTRB(
          Espaco.margemTela,
          Espaco.e4,
          Espaco.margemTela,
          Espaco.e6,
        ),
        children: [
          Text('Como vai ser?', style: texto.headlineLarge),
          const SizedBox(height: Espaco.e2),
          Text(
            'Dá para mudar a cada partida.',
            style: texto.bodyLarge?.copyWith(color: c.texto2),
          ),
          const SizedBox(height: Espaco.e6),
          CartaoConfig(
            icone: Symbols.key_rounded,
            titulo: 'Pista para o espião',
            subtitulo: pista
                ? 'O espião recebe uma palavra parecida. Fica mais difícil '
                      'de pegar.'
                : 'O espião não recebe nada. Fica mais fácil de pegar.',
            luz: luz,
            controleNaLinha: true,
            controle: Switch(
              value: pista,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                provider.setEspiaoVePalavraRelacionada(v);
              },
            ),
          ),
          const SizedBox(height: Espaco.e3),
          CartaoConfig(
            icone: Symbols.timer_rounded,
            titulo: 'Tempo de conversa',
            subtitulo: 'Recomendado: ${formatarTempo(_recomendado)}.',
            luz: luz,
            valor: formatarTempo(config.duracaoDiscussaoSegundos),
            controle: Slider(
              value: config.duracaoDiscussaoSegundos.toDouble(),
              min: AppConstants.duracaoDiscussaoMinSegundos.toDouble(),
              max: AppConstants.duracaoDiscussaoMaxSegundos.toDouble(),
              divisions:
                  (AppConstants.duracaoDiscussaoMaxSegundos -
                      AppConstants.duracaoDiscussaoMinSegundos) ~/
                  30,
              label: formatarTempo(config.duracaoDiscussaoSegundos),
              onChanged: (v) {
                if (v.toInt() != config.duracaoDiscussaoSegundos) {
                  HapticFeedback.selectionClick();
                }
                provider.setDuracaoDiscussao(v.toInt());
              },
            ),
          ),
          const SizedBox(height: Espaco.e3),
          CartaoConfig(
            icone: Symbols.category_rounded,
            titulo: 'Categorias',
            subtitulo: _fonte(categorias).resumo,
            luz: luz,
            controle: BotaoSala(
              rotulo: 'Escolher categorias',
              icone: Symbols.tune_rounded,
              variante: VarianteBotao.secundario,
              bloco: true,
              onPressed: () => mostrarFolhaDeCategorias(
                context,
                fonte: _fonte(categorias),
                matiz: Matiz.violeta,
                descricao: 'De onde vem a palavra do sorteio.',
              ),
            ),
          ),
        ],
      ),
      rodape: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Espaco.margemTela,
            Espaco.e3,
            Espaco.margemTela,
            Espaco.e4,
          ),
          child: BotaoSala(
            rotulo: 'Começar',
            icone: Symbols.play_arrow_rounded,
            luz: luz,
            bloco: true,
            carregando: carregando,
            onPressed: categorias.nenhumaSelecionada ? null : _comecar,
          ),
        ),
      ),
    );
  }
}
