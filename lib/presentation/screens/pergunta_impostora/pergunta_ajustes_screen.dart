import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/pergunta_impostora_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../providers/pergunta_categoria_provider.dart';
import '../../providers/pergunta_configuracao_provider.dart';
import '../../providers/pergunta_partida_provider.dart';
import '../../widgets/sala/botao_opcao.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/cartao_config.dart';
import '../../widgets/sala/contador.dart';
import '../../widgets/sala/cronometro.dart';
import '../../widgets/sala/folha_categorias.dart';
import '../../widgets/sala/tela_da_sala.dart';
import 'pergunta_distribuicao_screen.dart';

/// Passo 2 do Pergunta Impostora: dificuldade das perguntas, quando o
/// impostor vence, tempo de conversa e categorias. "Começar" sorteia o par
/// de perguntas e os papéis.
class PerguntaAjustesScreen extends StatefulWidget {
  const PerguntaAjustesScreen({super.key});

  @override
  State<PerguntaAjustesScreen> createState() => _PerguntaAjustesScreenState();
}

class _PerguntaAjustesScreenState extends State<PerguntaAjustesScreen> {
  static const _recomendado =
      PerguntaImpostoraConstants.duracaoDiscussaoDefaultSegundos;
  static const _niveis = {1: 'Fácil', 2: 'Médio', 3: 'Difícil'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = context.read<PerguntaConfiguracaoProvider>().configuracao;
      context.read<PerguntaCategoriaProvider>().carregarCategorias(
        idsSalvos: config.categoriasAtivasIds,
        niveisSalvos: config.niveisAtivos,
      );
    });
  }

  static FonteDeCategorias _fonte(PerguntaCategoriaProvider p) =>
      FonteDeCategorias(
        ouvir: p,
        opcoes: () => [
          for (final c in p.categorias)
            (id: c.id, nome: c.nome, quantidade: p.getQuantidadePares(c.id)),
        ],
        selecionada: p.isSelecionada,
        alternar: p.toggleCategoria,
        todas: p.selecionarTodas,
        nenhuma: p.deselecionarTodas,
        sortear: () => p.sortearCategorias(quantidade: 3),
        total: p.getQuantidadeTotalPares,
        singular: 'pergunta',
        plural: 'perguntas',
      );

  Future<void> _comecar() async {
    final config = context.read<PerguntaConfiguracaoProvider>();
    final categorias = context.read<PerguntaCategoriaProvider>();
    final partida = context.read<PerguntaPartidaProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    config
      ..setCategoriasAtivas(categorias.categoriasSelecionadas)
      ..setNiveisAtivos(categorias.niveisSelecionados);
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
          builder: (_) => const PerguntaDistribuicaoScreen(),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            partida.erro ??
                'Não deu para sortear as perguntas. Mude a dificuldade ou as '
                    'categorias.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(Matiz.rosa);
    final provider = context.watch<PerguntaConfiguracaoProvider>();
    final categorias = context.watch<PerguntaCategoriaProvider>();
    final carregando = context.select<PerguntaPartidaProvider, bool>(
      (p) => p.isLoading,
    );
    final config = provider.configuracao;
    final limiar = config.limiarVitoriaImpostorClamped;
    final fonte = _fonte(categorias);
    final semPerguntas =
        categorias.categoriasSelecionadas.isEmpty ||
        categorias.getQuantidadeTotalPares() == 0;

    return TelaDaSala(
      sobretitulo: 'PASSO 2 DE 2',
      titulo: 'Pergunta Impostora',
      matiz: Matiz.rosa,
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
            icone: Symbols.tune_rounded,
            titulo: 'Dificuldade',
            subtitulo:
                'Quanto mais difícil, mais parecida é a pergunta do impostor.',
            luz: luz,
            controle: Row(
              children: [
                for (final (i, MapEntry(key: nivel, value: nome))
                    in _niveis.entries.indexed) ...[
                  if (i > 0) const SizedBox(width: Espaco.e2),
                  Expanded(
                    child: BotaoOpcao(
                      rotulo: nome,
                      semantica: 'Nível $nome',
                      selecionado: categorias.isNivelSelecionado(nivel),
                      luz: luz,
                      aoTocar: () {
                        HapticFeedback.selectionClick();
                        categorias.toggleNivel(nivel);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Espaco.e3),
          CartaoConfig(
            icone: Symbols.flag_rounded,
            titulo: 'Vitória do impostor',
            subtitulo:
                'O impostor vence se a mesa ficar com $limiar '
                '${limiar == 1 ? 'pessoa' : 'pessoas'}, contando com ele.',
            luz: luz,
            controleNaLinha: true,
            controle: Contador(
              valor: limiar,
              minimo: config.minLimiarVitoriaImpostor,
              maximo: config.maxLimiarVitoriaImpostor,
              rotulo: 'pessoas para o impostor vencer',
              aoMudar: provider.setJogadoresRestantesParaVitoriaImpostor,
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
              min: PerguntaImpostoraConstants.duracaoDiscussaoMinSegundos
                  .toDouble(),
              max: PerguntaImpostoraConstants.duracaoDiscussaoMaxSegundos
                  .toDouble(),
              divisions:
                  (PerguntaImpostoraConstants.duracaoDiscussaoMaxSegundos -
                      PerguntaImpostoraConstants.duracaoDiscussaoMinSegundos) ~/
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
            subtitulo: fonte.resumo,
            luz: luz,
            controle: BotaoSala(
              rotulo: 'Escolher categorias',
              icone: Symbols.tune_rounded,
              variante: VarianteBotao.secundario,
              bloco: true,
              onPressed: () => mostrarFolhaDeCategorias(
                context,
                fonte: fonte,
                matiz: Matiz.rosa,
                descricao: 'De onde vem o par de perguntas do sorteio.',
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
            onPressed: semPerguntas ? null : _comecar,
          ),
        ),
      ),
    );
  }
}
