import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/so_uma_estado_remoto.dart';
import '../../../data/models/so_uma_jogador_remoto.dart';
import '../../../data/models/so_uma_rodada_remota.dart';
import '../../providers/so_uma_sala_provider.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/sala_online.dart';
import '../../widgets/sala/tela_da_sala.dart';
import '../../widgets/sala/varal.dart';
import '../../widgets/so_uma/pecas_so_uma.dart';

/// A partida online do Só uma!, numa tela: cada fase da rodada (escolher,
/// escrever, conferir, chutar), o resultado e o fim, do ponto de vista de
/// quem adivinha ou de quem escreve.
class SoUmaMesaRemotaScreen extends StatefulWidget {
  const SoUmaMesaRemotaScreen({
    super.key,
    required this.estado,
    required this.jogadores,
    required this.rodada,
    required this.resultadoPendente,
    required this.aoVerResultado,
  });

  final SoUmaEstadoRemoto estado;
  final List<SoUmaJogadorRemoto> jogadores;

  /// A carta e as pistas; nunca chega para quem adivinha.
  final SoUmaRodadaRemota? rodada;

  /// A última rodada acabou e este celular ainda não viu o resultado.
  final bool resultadoPendente;
  final VoidCallback aoVerResultado;

  @override
  State<SoUmaMesaRemotaScreen> createState() => _SoUmaMesaRemotaScreenState();
}

class _SoUmaMesaRemotaScreenState extends State<SoUmaMesaRemotaScreen> {
  final _pista1 = TextEditingController();
  final _pista2 = TextEditingController();
  final _chute = TextEditingController();
  int? _numero;

  /// A rodada em que este celular já mandou as pistas.
  String? _enviouNaRodada;

  @override
  void initState() {
    super.initState();
    for (final c in [_pista1, _pista2, _chute]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void didUpdateWidget(SoUmaMesaRemotaScreen antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.estado.currentRoundId != widget.estado.currentRoundId) {
      _numero = null;
      _pista1.clear();
      _pista2.clear();
      _chute.clear();
    }
  }

  @override
  void dispose() {
    _pista1.dispose();
    _pista2.dispose();
    _chute.dispose();
    super.dispose();
  }

  SoUmaSalaProvider get _p => context.read<SoUmaSalaProvider>();

  ({String nome, int indice}) _jogador(String uid) {
    for (final (i, j) in widget.jogadores.indexed) {
      if (j.uid == uid) return (nome: j.displayName, indice: j.seat ?? i);
    }
    return (nome: 'Alguém', indice: 0);
  }

  bool get _duasPistas =>
      widget.estado.playerCount == SoUmaConstants.jogadoresParaDuasPistas;

  Future<void> _escolher() async {
    final n = _numero;
    if (n == null) return;
    HapticFeedback.mediumImpact();
    await agirNaSala(context, _p, () => _p.escolherNumeroRemoto(n + 1));
  }

  Future<void> _enviarPistas() async {
    final palavras = [
      _pista1.text.trim(),
      if (_duasPistas) _pista2.text.trim(),
    ];
    if (palavras.any((p) => p.isEmpty)) return;
    FocusScope.of(context).unfocus();
    final rodada = widget.estado.currentRoundId;
    final p = _p;
    final ok = await p.enviarPistasRemoto(palavras);
    if (!mounted) return;
    // Já enviada antes (o app foi fechado no meio): conta como enviada.
    if (ok || (p.erro?.contains('já enviou') ?? false)) {
      setState(() => _enviouNaRodada = rodada);
    } else if (p.erro != null) {
      await agirNaSala(context, p, () async => false);
    }
  }

  Future<void> _chutar({bool passar = false}) async {
    final palpite = _chute.text.trim();
    if (!passar && palpite.isEmpty) return;
    FocusScope.of(context).unfocus();
    await agirNaSala(
      context,
      _p,
      () => _p.enviarPalpiteRemoto(
        palpite: passar ? null : palpite,
        passar: passar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SoUmaSalaProvider>();
    final e = widget.estado;
    final acabou = e.phase == 'over' && !widget.resultadoPendente;
    final carta = e.historico.length + (widget.resultadoPendente ? 0 : 1);
    final etapa = _etapa(provider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) {
          sairDaMesa(
            context,
            nomeDoJogo: SoUmaConstants.jogoNome,
            matiz: matizSoUma,
          );
        }
      },
      child: TelaDaSala(
        sobretitulo: acabou
            ? 'FIM DE JOGO'
            : 'CARTA $carta · ${e.deckRemaining} NO BARALHO',
        titulo: SoUmaConstants.jogoNome,
        matiz: matizSoUma,
        progresso: placarNoVaral(context, e.cartasGanhas),
        inicio: const BotaoSairDaMesa(
          nomeDoJogo: SoUmaConstants.jogoNome,
          matiz: matizSoUma,
        ),
        acao: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlacarSoUma(cartas: e.cartasGanhas),
            if (provider.souHost && !acabou) ...[
              const SizedBox(width: Espaco.e2),
              BotaoEncerrarPartida(sala: provider),
            ],
          ],
        ),
        corpo: TrocaDeFase(
          fase: '$etapa|${e.currentRoundId}|${e.historico.length}',
          child: _conteudo(provider, etapa),
        ),
      ),
    );
  }

  String _etapa(SoUmaSalaProvider p) {
    final e = widget.estado;
    if (widget.resultadoPendente) return 'resultado';
    final adivinho = e.guesserUid == p.uid;
    return switch (e.phase) {
      'over' => 'fim',
      'drawing' => adivinho ? 'escolher' : 'esperando-escolha',
      'writing' when adivinho => 'esperando-pistas',
      'writing' when _enviouNaRodada == e.currentRoundId => 'pista-enviada',
      'writing' => widget.rodada == null ? 'carregando' : 'escrever',
      'comparing' when adivinho => 'esperando-conferencia',
      'comparing' => widget.rodada == null ? 'carregando' : 'conferir',
      'guessing' => adivinho ? 'chutar' : 'esperando-chute',
      _ => 'carregando',
    };
  }

  Widget _conteudo(SoUmaSalaProvider p, String etapa) {
    final c = context.cores;
    final luz = c.luz(matizSoUma);
    final e = widget.estado;
    final rodada = widget.rodada;
    final adivinhador = _jogador(e.guesserUid);

    if (etapa == 'resultado') {
      final r = e.historico.last;
      final quem = _jogador(r.guesserUid);
      return EtapaSoUma(
        rodape: BotaoSala(
          rotulo: e.phase == 'over' ? 'Ver o placar final' : 'Próxima carta',
          icone: Symbols.arrow_forward_rounded,
          iconeNoFim: true,
          luz: luz,
          bloco: true,
          onPressed: widget.aoVerResultado,
        ),
        children: [
          ResultadoDaRodada(
            resultado: r.resultado,
            palavraAlvo: r.palavraAlvo,
            adivinhador: quem.nome,
            palpite: r.palpite,
            palavras: r.palavras,
            pistas: const [],
          ),
        ],
      );
    }

    if (etapa == 'fim') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: EtapaSoUma(
              children: [
                FimSoUma(
                  cartasGanhas: e.cartasGanhas,
                  rodadas: [
                    for (final r in e.historico)
                      (
                        nome: _jogador(r.guesserUid).nome,
                        indice: _jogador(r.guesserUid).indice,
                        palavraAlvo: r.palavraAlvo,
                        palpite: r.palpite,
                        resultado: r.resultado,
                      ),
                  ],
                ),
              ],
            ),
          ),
          RodapeDoFimOnline(sala: p, matiz: matizSoUma),
        ],
      );
    }

    switch (etapa) {
      case 'escolher':
        return EtapaSoUma(
          rodape: BotaoSala(
            rotulo: _numero == null
                ? 'Escolha um número'
                : 'Ficar com o ${_numero! + 1}',
            icone: Symbols.check_rounded,
            luz: luz,
            bloco: true,
            carregando: p.isLoading,
            onPressed: _numero == null ? null : _escolher,
          ),
          children: [
            CabecaDaEtapa(
              nome: adivinhador.nome,
              indice: adivinhador.indice,
              titulo: 'Sua vez de adivinhar',
              texto:
                  'São cinco palavras escondidas. Escolha uma pelo número, '
                  'às cegas.',
            ),
            const SizedBox(height: Espaco.e6),
            CartaSoUma(
              escolhido: _numero,
              aoEscolher: p.isLoading
                  ? null
                  : (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _numero = i);
                    },
            ),
          ],
        );

      case 'esperando-escolha':
        return PasseOCelular(
          nome: adivinhador.nome,
          indice: adivinhador.indice,
          titulo: '${adivinhador.nome} está escolhendo',
          texto: 'Uma palavra às cegas. Já já vocês veem qual saiu.',
        );

      case 'escrever':
        final duas = _duasPistas;
        final pronto =
            _pista1.text.trim().isNotEmpty &&
            (!duas || _pista2.text.trim().isNotEmpty);
        return EtapaSoUma(
          rodape: BotaoSala(
            rotulo: duas ? 'Enviar as pistas' : 'Enviar a pista',
            icone: Symbols.send_rounded,
            luz: luz,
            bloco: true,
            carregando: p.isLoading,
            onPressed: pronto ? _enviarPistas : null,
          ),
          children: [
            CabecaDaEtapa(
              titulo: duas ? 'Suas duas pistas' : 'Sua pista',
              texto:
                  'Uma palavra só, que leve ${adivinhador.nome} até a '
                  'palavra acesa. Iguais às dos outros se anulam.',
            ),
            const SizedBox(height: Espaco.e6),
            CartaSoUma(palavras: rodada!.palavras, alvo: rodada.mysteryIndex),
            const SizedBox(height: Espaco.e6),
            CampoDaPalavra(
              controlador: _pista1,
              dica: duas ? 'Primeira pista' : 'Sua pista',
              aoEnviar: duas ? () {} : _enviarPistas,
            ),
            if (duas) ...[
              const SizedBox(height: Espaco.e3),
              CampoDaPalavra(
                controlador: _pista2,
                dica: 'Segunda pista',
                autofoco: false,
                aoEnviar: _enviarPistas,
              ),
            ],
          ],
        );

      case 'esperando-pistas' || 'pista-enviada':
        final enviada = etapa == 'pista-enviada';
        return PasseOCelular(
          icone: enviada
              ? Symbols.mark_email_read_rounded
              : Symbols.edit_rounded,
          titulo: enviada ? 'Pista enviada' : 'Os outros estão escrevendo',
          texto: enviada
              ? 'Esperando o resto da turma.'
              : 'Cada um manda uma pista de uma palavra. Sem espiar!',
          extra: _Envios(feitos: e.submittedCount, total: e.expectedCount),
          bolinhas: false,
        );

      case 'esperando-conferencia':
        return const PasseOCelular(
          icone: Symbols.fact_check_rounded,
          titulo: 'Conferindo as pistas',
          texto: 'A turma está anulando as repetidas. Já já é com você.',
        );

      case 'conferir':
        final nomes = {for (final j in widget.jogadores) j.uid: j.displayName};
        return EtapaSoUma(
          rodape: BotaoSala(
            rotulo: 'Pronto, pode chutar',
            icone: Symbols.check_rounded,
            luz: luz,
            bloco: true,
            carregando: p.isLoading,
            onPressed: () =>
                agirNaSala(context, p, p.finalizarComparacaoRemota),
          ),
          children: [
            CabecaDaEtapa(
              titulo: 'Conferir as pistas',
              texto:
                  'Toquem para anular as iguais, as da mesma família e as '
                  'que não valem. Todo mundo vê as mudanças na hora.',
            ),
            const SizedBox(height: Espaco.e6),
            for (final (i, pista) in rodada!.clues.indexed) ...[
              if (i > 0) const SizedBox(height: Espaco.e2),
              PistaParaConferir(
                texto: pista.texto,
                anulada: pista.anulada,
                autor: nomes[pista.autorUid],
                motivo: pista.anulada ? pista.motivoAutoAnulacao : null,
                aoTocar: p.isLoading
                    ? null
                    : () => agirNaSala(
                        context,
                        p,
                        () => p.alternarAnulacaoPistaRemota(pista.clueId),
                      ),
              ),
            ],
          ],
        );

      case 'chutar':
        return EtapaSoUma(
          rodape: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BotaoSala(
                rotulo: 'Chutar',
                icone: Symbols.lightbulb_rounded,
                luz: luz,
                bloco: true,
                carregando: p.isLoading,
                onPressed: _chute.text.trim().isEmpty ? null : _chutar,
              ),
              const SizedBox(height: Espaco.e2),
              BotaoSala(
                rotulo: 'Passar',
                icone: Symbols.skip_next_rounded,
                variante: VarianteBotao.fantasma,
                luz: Luz(c.texto, c.texto2, c.superficieFunda),
                bloco: true,
                onPressed: p.isLoading ? null : () => _chutar(passar: true),
              ),
            ],
          ),
          children: [
            const CabecaDaEtapa(
              titulo: 'Qual é a palavra?',
              texto:
                  'Errar custa duas cartas; passar, só uma. Na dúvida, '
                  'passe.',
            ),
            const SizedBox(height: Espaco.e6),
            PistasNaMesa(pistas: e.pistasReveladas),
            const SizedBox(height: Espaco.e6),
            CampoDaPalavra(
              controlador: _chute,
              dica: 'Seu chute',
              aoEnviar: _chutar,
            ),
          ],
        );

      case 'esperando-chute':
        return PasseOCelular(
          nome: adivinhador.nome,
          indice: adivinhador.indice,
          titulo: '${adivinhador.nome} está pensando',
          texto: 'Estas foram as pistas que sobraram:',
          extra: PistasNaMesa(pistas: e.pistasReveladas),
        );
    }

    return const Center(child: Varal.carregando());
  }
}

/// Quantas pistas já chegaram: bolinhas acesas e o número.
class _Envios extends StatelessWidget {
  const _Envios({required this.feitos, required this.total});

  final int feitos, total;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(matizSoUma);
    return Semantics(
      label: '$feitos de $total pistas enviadas',
      excludeSemantics: true,
      child: Column(
        children: [
          Wrap(
            spacing: Espaco.e2,
            children: [
              for (var i = 0; i < total; i++)
                AnimatedContainer(
                  duration: Movimento.media,
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < feitos ? luz.cor : c.superficieFunda,
                    border: Border.all(
                      color: c.ehDia ? c.contorno : c.linhaForte,
                      width: 1.5,
                    ),
                    boxShadow: i < feitos ? c.brilho(luz.cor, alpha: .5) : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Espaco.e2),
          Text(
            '$feitos/$total',
            style: context.estilos.hud.copyWith(color: luz.tinta),
          ),
        ],
      ),
    );
  }
}
