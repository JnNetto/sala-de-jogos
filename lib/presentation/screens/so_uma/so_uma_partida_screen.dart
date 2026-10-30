import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../../core/enums/so_uma_fase.dart';
import '../../../core/enums/so_uma_resultado_rodada.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/so_uma_jogador.dart';
import '../../../data/models/so_uma_partida.dart';
import '../../navegacao.dart';
import '../../providers/so_uma_partida_provider.dart';
import '../../widgets/sala/aviso.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/dialogo.dart';
import '../../widgets/sala/sala_online.dart';
import '../../widgets/sala/tela_da_sala.dart';
import '../../widgets/so_uma/pecas_so_uma.dart';

enum _Etapa {
  escolher,
  passarParaEscritor,
  escrever,
  todosEscreveram,
  conferir,
  chamarAdivinhador,
  adivinhar,
  resultado,
  fim,
}

/// Uma partida de Só uma! num celular só, do começo ao fim, numa rota:
/// escolher a palavra, passar o celular, escrever, conferir, chutar e ver
/// o resultado. As etapas trocam com um fade, e o varal é o placar.
class SoUmaPartidaScreen extends StatefulWidget {
  const SoUmaPartidaScreen({super.key});

  @override
  State<SoUmaPartidaScreen> createState() => _SoUmaPartidaScreenState();
}

class _SoUmaPartidaScreenState extends State<SoUmaPartidaScreen> {
  final _campo = TextEditingController();
  int _resultadosVistos = 0;
  int? _numero;
  int _escritor = 0;
  bool _escritorPegou = false;
  bool _adivinhadorVoltou = false;

  @override
  void initState() {
    super.initState();
    _campo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  _Etapa _etapa(SoUmaPartida p) {
    if (p.historico.length > _resultadosVistos) return _Etapa.resultado;
    return switch (p.fase) {
      SoUmaFase.escolhendoNumero => _Etapa.escolher,
      SoUmaFase.escrevendoPistas =>
        _escritor >= p.escritores.length
            ? _Etapa.todosEscreveram
            : _escritorPegou
            ? _Etapa.escrever
            : _Etapa.passarParaEscritor,
      SoUmaFase.comparandoPistas => _Etapa.conferir,
      SoUmaFase.adivinhando =>
        _adivinhadorVoltou ? _Etapa.adivinhar : _Etapa.chamarAdivinhador,
      SoUmaFase.finalizada => _Etapa.fim,
    };
  }

  int _indice(SoUmaPartida p, SoUmaJogador j) =>
      p.jogadores.indexWhere((x) => x.id == j.id);

  Future<void> _sair() async {
    final provider = context.read<SoUmaPartidaProvider>();
    final terminou = provider.partida?.fase == SoUmaFase.finalizada;
    if (!terminou) {
      final sair = await mostrarDialogo(
        context,
        perigo: true,
        icone: Symbols.logout_rounded,
        barra: 'SAIR',
        titulo: 'Sair da partida?',
        corpo: 'O placar desta partida se perde.',
        acao: 'Sair',
        escape: 'Continuar jogando',
      );
      if (sair != true || !mounted) return;
    }
    provider.limparPartida();
    Navigator.of(context).popUntil(ehBaseDosJogos);
  }

  void _escolher() {
    final n = _numero;
    if (n == null) return;
    HapticFeedback.mediumImpact();
    final ok = context.read<SoUmaPartidaProvider>().escolherNumero(n + 1);
    if (!ok) return;
    setState(() {
      _numero = null;
      _escritor = 0;
      _escritorPegou = false;
    });
  }

  void _escrever(SoUmaPartida p) {
    final texto = _campo.text.trim();
    if (texto.isEmpty) return;
    final provider = context.read<SoUmaPartidaProvider>();
    final escritor = p.escritores[_escritor];
    if (!provider.adicionarPista(escritor.id, texto)) return;
    _campo.clear();
    final necessarias =
        p.quantidadeJogadores == SoUmaConstants.jogadoresParaDuasPistas ? 2 : 1;
    if (provider.pistasEscritasPorAutor(escritor.id) >= necessarias) {
      setState(() {
        _escritor++;
        _escritorPegou = false;
      });
    }
  }

  void _responder({bool passar = false}) {
    final palpite = _campo.text.trim();
    if (!passar && palpite.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<SoUmaPartidaProvider>().responderRodada(
      palpite: passar ? null : palpite,
      passar: passar,
    );
    _campo.clear();
  }

  void _proximaCarta(SoUmaPartida p) {
    setState(() {
      _resultadosVistos = p.historico.length;
      _adivinhadorVoltou = false;
    });
  }

  Future<void> _jogarDeNovo(SoUmaPartida p) async {
    final provider = context.read<SoUmaPartidaProvider>();
    final nomes = [for (final j in p.jogadores) j.nome];
    final ok = await provider.iniciarNovaPartida(nomes);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _resultadosVistos = 0;
        _adivinhadorVoltou = false;
        _numero = null;
      });
    } else if (provider.erro != null) {
      mostrarAviso(context, provider.erro!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SoUmaPartidaProvider>();
    final p = provider.partida;
    if (p == null) return const SizedBox.shrink();
    final etapa = _etapa(p);
    final rodada = etapa == _Etapa.resultado || etapa == _Etapa.fim
        ? p.historico.length
        : p.numeroRodadaAtual;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) _sair();
      },
      child: TelaDaSala(
        sobretitulo: etapa == _Etapa.fim
            ? 'FIM DE JOGO'
            : 'CARTA $rodada · ${p.cartasRestantesBaralho} NO BARALHO',
        titulo: SoUmaConstants.jogoNome,
        matiz: matizSoUma,
        progresso: placarNoVaral(context, p.cartasGanhas),
        inicio: BotaoIcone(
          icone: Symbols.close_rounded,
          rotulo: 'Sair da partida',
          onPressed: _sair,
        ),
        acao: PlacarSoUma(cartas: p.cartasGanhas),
        corpo: TrocaDeFase(
          fase: '$etapa-$rodada-$_escritor-${p.rodadaAtual?.pistas.length}',
          child: _conteudo(p, etapa),
        ),
      ),
    );
  }

  Widget _conteudo(SoUmaPartida p, _Etapa etapa) {
    final c = context.cores;
    final luz = c.luz(matizSoUma);
    final adivinhador = p.adivinhadorAtual;
    final rodada = p.rodadaAtual;

    switch (etapa) {
      case _Etapa.escolher:
        return Etapa(
          rodape: BotaoSala(
            rotulo: _numero == null
                ? 'Escolha um número'
                : 'Ficar com o ${_numero! + 1}',
            icone: Symbols.check_rounded,
            luz: luz,
            bloco: true,
            onPressed: _numero == null ? null : _escolher,
          ),
          children: [
            CabecaDaEtapa(
              nome: adivinhador.nome,
              indice: _indice(p, adivinhador),
              titulo: p.numerosUsados.isEmpty
                  ? '${adivinhador.nome}, escolha'
                  : 'Tente outra palavra',
              texto: p.numerosUsados.isEmpty
                  ? 'São cinco palavras escondidas. Escolha uma pelo número, '
                        'às cegas.'
                  : 'A carta é a mesma. As que já saíram ficam de fora.',
            ),
            const SizedBox(height: Espaco.e6),
            CartaSoUma(
              tentadas: {for (final n in p.numerosUsados) n - 1},
              escolhido: _numero,
              aoEscolher: (i) {
                HapticFeedback.selectionClick();
                setState(() => _numero = i);
              },
            ),
          ],
        );

      case _Etapa.passarParaEscritor:
        final escritor = p.escritores[_escritor];
        final primeiro = _escritor == 0;
        return PasseOCelular(
          nome: escritor.nome,
          indice: _indice(p, escritor),
          titulo: primeiro
              ? 'Passe para ${escritor.nome}'
              : 'Agora, ${escritor.nome}',
          texto: primeiro
              ? '${adivinhador.nome} não pode mais ver a tela até as pistas '
                    'serem conferidas.'
              : 'Escreva sem olhar a pista de quem veio antes.',
          acao: 'Sou eu',
          aoContinuar: () => setState(() => _escritorPegou = true),
        );

      case _Etapa.escrever:
        final escritor = p.escritores[_escritor];
        final duas =
            p.quantidadeJogadores == SoUmaConstants.jogadoresParaDuasPistas;
        final feitas = context
            .read<SoUmaPartidaProvider>()
            .pistasEscritasPorAutor(escritor.id);
        final ultima = !duas || feitas == 1;
        return Etapa(
          rodape: BotaoSala(
            rotulo: ultima ? 'Pronto' : 'Próxima pista',
            icone: ultima
                ? Symbols.check_rounded
                : Symbols.arrow_forward_rounded,
            iconeNoFim: !ultima,
            luz: luz,
            bloco: true,
            onPressed: _campo.text.trim().isEmpty ? null : () => _escrever(p),
          ),
          children: [
            CabecaDaEtapa(
              nome: escritor.nome,
              indice: _indice(p, escritor),
              titulo: duas ? 'Sua pista ${feitas + 1} de 2' : 'Sua pista',
              texto:
                  'Uma palavra só, que leve ${adivinhador.nome} até a '
                  'palavra acesa.',
            ),
            const SizedBox(height: Espaco.e6),
            CartaSoUma(
              palavras: rodada!.carta.palavras,
              alvo: rodada.numeroEscolhido - 1,
            ),
            const SizedBox(height: Espaco.e6),
            CampoDaPalavra(
              controlador: _campo,
              dica: 'Sua pista',
              aoEnviar: () => _escrever(p),
            ),
          ],
        );

      case _Etapa.todosEscreveram:
        return PasseOCelular(
          icone: Symbols.groups_rounded,
          titulo: 'Todo mundo escreveu',
          texto:
              'Agora conferam as pistas juntos. ${adivinhador.nome} continua '
              'sem olhar.',
          acao: 'Conferir as pistas',
          aoContinuar: () =>
              context.read<SoUmaPartidaProvider>().finalizarEscritaPistas(),
        );

      case _Etapa.conferir:
        final provider = context.read<SoUmaPartidaProvider>();
        final nomes = {for (final j in p.jogadores) j.id: j.nome};
        return Etapa(
          rodape: BotaoSala(
            rotulo: 'Pronto, pode chutar',
            icone: Symbols.check_rounded,
            luz: luz,
            bloco: true,
            onPressed: () {
              provider.finalizarComparacao();
              setState(() => _adivinhadorVoltou = false);
            },
          ),
          children: [
            const CabecaDaEtapa(
              titulo: 'Conferir as pistas',
              texto:
                  'Toquem para anular as iguais, as da mesma família e as '
                  'que não valem. O jogo já marcou algumas, mas vocês '
                  'decidem.',
            ),
            const SizedBox(height: Espaco.e6),
            for (final (i, pista) in rodada!.pistas.indexed) ...[
              if (i > 0) const SizedBox(height: Espaco.e2),
              PistaParaConferir(
                texto: pista.texto,
                anulada: pista.anulada,
                autor: nomes[pista.autorId],
                motivo: pista.anulada ? pista.motivoAutoAnulacao : null,
                aoTocar: () => provider.alternarAnulacaoPista(pista.id),
              ),
            ],
          ],
        );

      case _Etapa.chamarAdivinhador:
        final sobraram = rodada!.pistasSobreviventes.length;
        return PasseOCelular(
          nome: adivinhador.nome,
          indice: _indice(p, adivinhador),
          titulo: 'Chamem ${adivinhador.nome}',
          texto: sobraram == 0
              ? 'Nenhuma pista sobrou. Pode chutar mesmo assim, ou passar.'
              : 'Sobraram $sobraram ${sobraram == 1 ? 'pista' : 'pistas'}. '
                    'Só ${adivinhador.nome} olha agora.',
          acao: 'Sou eu',
          aoContinuar: () => setState(() => _adivinhadorVoltou = true),
        );

      case _Etapa.adivinhar:
        return Etapa(
          rodape: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BotaoSala(
                rotulo: 'Chutar',
                icone: Symbols.lightbulb_rounded,
                luz: luz,
                bloco: true,
                onPressed: _campo.text.trim().isEmpty ? null : _responder,
              ),
              const SizedBox(height: Espaco.e2),
              BotaoSala(
                rotulo: 'Passar',
                icone: Symbols.skip_next_rounded,
                variante: VarianteBotao.fantasma,
                luz: Luz(c.texto, c.texto2, c.superficieFunda),
                bloco: true,
                onPressed: () => _responder(passar: true),
              ),
            ],
          ),
          children: [
            CabecaDaEtapa(
              nome: adivinhador.nome,
              indice: _indice(p, adivinhador),
              titulo: 'Qual é a palavra?',
              texto:
                  'Errou? A carta volta e você tenta outra palavra dela. '
                  'Passar descarta a carta.',
            ),
            const SizedBox(height: Espaco.e6),
            PistasNaMesa(
              pistas: [for (final x in rodada!.pistasSobreviventes) x.texto],
            ),
            const SizedBox(height: Espaco.e6),
            CampoDaPalavra(
              controlador: _campo,
              dica: 'Seu chute',
              aoEnviar: _responder,
            ),
          ],
        );

      case _Etapa.resultado:
        final r = p.historico[_resultadosVistos];
        return Etapa(
          rodape: BotaoSala(
            rotulo: p.fase == SoUmaFase.finalizada
                ? 'Ver o placar final'
                : p.numerosUsados.isNotEmpty
                ? 'Tentar de novo'
                : 'Próxima carta',
            icone: Symbols.arrow_forward_rounded,
            iconeNoFim: true,
            luz: luz,
            bloco: true,
            onPressed: () => _proximaCarta(p),
          ),
          children: [
            ResultadoDaRodada(
              resultado: switch (r.resultado!) {
                SoUmaResultadoRodada.acerto => 'acerto',
                SoUmaResultadoRodada.erro => 'erro',
                SoUmaResultadoRodada.passou => 'passou',
              },
              palavraAlvo: r.palavraAlvo,
              adivinhador: r.adivinhador.nome,
              palpite: r.palpite,
              cartaVolta: p.numerosUsados.isNotEmpty,
              palavras: r.carta.palavras,
              pistas: [
                for (final x in r.pistas) (texto: x.texto, anulada: x.anulada),
              ],
            ),
          ],
        );

      case _Etapa.fim:
        return Etapa(
          rodape: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BotaoSala(
                rotulo: 'Jogar de novo',
                icone: Symbols.replay_rounded,
                luz: luz,
                bloco: true,
                carregando: context.watch<SoUmaPartidaProvider>().isLoading,
                onPressed: () => _jogarDeNovo(p),
              ),
              const SizedBox(height: Espaco.e2),
              BotaoSala(
                rotulo: 'Sair',
                variante: VarianteBotao.fantasma,
                luz: Luz(c.texto, c.texto2, c.superficieFunda),
                bloco: true,
                onPressed: _sair,
              ),
            ],
          ),
          children: [
            FimSoUma(
              cartasGanhas: p.cartasGanhas,
              rodadas: [
                for (final r in p.historico)
                  (
                    nome: r.adivinhador.nome,
                    indice: _indice(p, r.adivinhador),
                    palavraAlvo: r.palavraAlvo,
                    palpite: r.palpite,
                    resultado: r.resultado?.name ?? 'passou',
                  ),
              ],
            ),
          ],
        );
    }
  }
}
