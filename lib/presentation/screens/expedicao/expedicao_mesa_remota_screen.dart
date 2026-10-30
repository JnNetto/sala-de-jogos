import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/resistencia_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/resistencia_estado_remoto.dart';
import '../../../data/models/resistencia_jogador_remoto.dart';
import '../../../data/models/resistencia_privado.dart';
import '../../../data/models/resistencia_proposta_remota.dart';
import '../../providers/resistencia_sala_provider.dart';
import '../../widgets/expedicao/pecas_expedicao.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/carta_revelacao.dart';
import '../../widgets/sala/janela.dart';
import '../../widgets/sala/jogador_sala.dart';
import '../../widgets/sala/sala_online.dart';
import '../../widgets/sala/tela_da_sala.dart';
import '../../widgets/sala/varal.dart';

/// A partida online da Expedição, numa tela: o papel, a proposta do guia,
/// o voto, a câmara, a Lanterna e o fim. Cada celular vê a sua parte; o
/// roteador decide a [etapa].
class ExpedicaoMesaRemotaScreen extends StatefulWidget {
  const ExpedicaoMesaRemotaScreen({
    super.key,
    required this.etapa,
    required this.estado,
    required this.jogadores,
    required this.privado,
    required this.proposta,
  });

  /// "papel", "voto", "camara" ou a fase do servidor ("proposing",
  /// "voting", "mission", "lantern", "over").
  final String etapa;
  final ResistenciaEstadoRemoto estado;
  final List<ResistenciaJogadorRemoto> jogadores;
  final ResistenciaPrivado? privado;
  final ResistenciaPropostaRemota? proposta;

  @override
  State<ExpedicaoMesaRemotaScreen> createState() =>
      _ExpedicaoMesaRemotaScreenState();
}

class _ExpedicaoMesaRemotaScreenState extends State<ExpedicaoMesaRemotaScreen> {
  final _equipe = <String>{};
  String? _votouNa;
  String? _jogouNa;
  bool _verLanterna = false;
  bool _cartasViradas = false;

  /// As cartas da última câmara, embaralhadas uma vez só.
  List<bool>? _cartas;
  int _cartasDaCamara = -1;

  ResistenciaSalaProvider get _p => context.read<ResistenciaSalaProvider>();

  @override
  void didUpdateWidget(ExpedicaoMesaRemotaScreen antigo) {
    super.didUpdateWidget(antigo);
    final e = widget.estado;
    // Mudou o guia ou a câmara: a seleção começa de novo.
    if (antigo.estado.leaderUid != e.leaderUid ||
        antigo.estado.round != e.round) {
      _equipe.clear();
    }
  }

  ({String nome, int indice}) _jogador(String? uid) {
    for (final (i, j) in widget.jogadores.indexed) {
      if (j.uid == uid) return (nome: j.displayName, indice: j.seat ?? i);
    }
    return (nome: 'Alguém', indice: 0);
  }

  bool get _saqueador => widget.privado?.team == 'evil';

  Future<void> _votar(bool segue) async {
    final id = widget.estado.currentProposalId;
    HapticFeedback.mediumImpact();
    final p = _p;
    final ok = await p.votarPropostaRemota(segue);
    if (!mounted) return;
    if (ok || (p.erro?.contains('já votou') ?? false)) {
      setState(() => _votouNa = id);
    } else {
      await agirNaSala(context, p, () async => false);
    }
  }

  Future<void> _jogar(bool avancar) async {
    final id = widget.estado.currentProposalId;
    final p = _p;
    final ok = await p.jogarCartaMissaoRemota(avancar);
    if (!mounted) return;
    if (ok || (p.erro?.contains('já jogou') ?? false)) {
      setState(() => _jogouNa = id);
    } else {
      await agirNaSala(context, p, () async => false);
    }
  }

  Future<void> _lanterna(String? alvo) async {
    final p = _p;
    final ok = await agirNaSala(context, p, () => p.usarLanternaRemota(alvo));
    if (ok && alvo != null && mounted) setState(() => _verLanterna = true);
  }

  String _etapa() {
    if (_verLanterna && widget.privado?.lanternaAlvoUid != null) {
      return 'visao';
    }
    return widget.etapa;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResistenciaSalaProvider>();
    final e = widget.estado;
    final etapa = _etapa();
    final acabou = e.phase == 'over' && etapa == 'over';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) {
          sairDaMesa(
            context,
            nomeDoJogo: ResistenciaConstants.jogoNome,
            matiz: matizExpedicao,
          );
        }
      },
      child: TelaDaSala(
        sobretitulo: acabou
            ? 'FIM DA EXPEDIÇÃO'
            : 'CÂMARA ${e.round} DE ${ResistenciaConstants.totalMissoes}',
        titulo: ResistenciaConstants.jogoNome,
        matiz: matizExpedicao,
        inicio: const BotaoSairDaMesa(
          nomeDoJogo: ResistenciaConstants.jogoNome,
          matiz: matizExpedicao,
        ),
        acao: provider.souHost && !acabou
            ? BotaoEncerrarPartida(sala: provider)
            : null,
        corpo: TrocaDeFase(
          fase: '$etapa|${e.round}|${e.attempt}|${e.missionResults.length}',
          child: _conteudo(provider, etapa),
        ),
      ),
    );
  }

  Widget _painel() {
    final e = widget.estado;
    String? nota;
    if (e.lanternByUid != null) {
      final quem = _jogador(e.lanternByUid).nome;
      final alvo = _jogador(e.lanternTargetUid).nome;
      final minha =
          e.lanternByUid == _p.uid && widget.privado?.lanternaCarta != null;
      nota = minha
          ? 'Você usou a Lanterna em $alvo: '
                '${widget.privado!.lanternaCarta! ? 'Avançar' : 'Armadilha'}.'
          : '$quem usou a Lanterna em $alvo.';
    }
    final tamanhos =
        ResistenciaConstants.tamanhosEquipePorJogadores[e.playerCount] ??
        const <int>[];
    return PainelDaExpedicao(
      resultados: e.missionResults,
      tamanhos: tamanhos,
      atual: e.round,
      jogadores: e.playerCount,
      rejeicoes: e.rejections,
      nota: nota,
    );
  }

  Widget _conteudo(ResistenciaSalaProvider p, String etapa) {
    final c = context.cores;
    final t = Theme.of(context).textTheme;
    final luz = c.luz(matizExpedicao);
    final e = widget.estado;
    final proposta = widget.proposta;
    final eu = p.uid;
    final guia = _jogador(e.leaderUid);
    const carregando = Center(child: Varal.carregando());

    switch (etapa) {
      case 'papel':
        final privado = widget.privado;
        if (privado == null) return carregando;
        final mim = _jogador(eu);
        final outros = [
          for (final k in privado.knowledge)
            if (k['uid'] is String) _jogador(k['uid'] as String).nome,
        ];
        return Etapa(
          children: [
            const CabecaDaEtapa(
              titulo: 'Seu papel',
              texto: 'Segure a carta para ver. Ninguém mais pode olhar.',
            ),
            const SizedBox(height: Espaco.e5),
            Center(
              child: CartaRevelacao(
                nome: mim.nome,
                indice: mim.indice,
                total: e.playerCount,
                espiao: _saqueador,
                frente: (esconder, efeito) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FrenteDoPapel(
                      saqueador: _saqueador,
                      outrosSaqueadores: outros,
                    ),
                    const SizedBox(height: Espaco.e4),
                    BotaoSala(
                      rotulo: 'Esconder e começar',
                      icone: Symbols.visibility_rounded,
                      variante: VarianteBotao.secundario,
                      onPressed: esconder,
                    ),
                  ],
                ),
                aoEsconder: () => p.marcarPapelRevelado(e.gameId),
              ),
            ),
          ],
        );

      case 'voto':
        if (proposta == null || proposta.id != e.lastProposalId) {
          return carregando;
        }
        final aprovada = proposta.aprovada;
        final votos = proposta.votes ?? const <String, bool>{};
        return Etapa(
          rodape: BotaoSala(
            rotulo: 'Continuar',
            icone: Symbols.arrow_forward_rounded,
            iconeNoFim: true,
            luz: luz,
            bloco: true,
            onPressed: () =>
                p.marcarResultadoPropostaVisto(e.gameId, proposta.id),
          ),
          children: [
            Janela(
              titulo: aprovada ? 'EQUIPE APROVADA' : 'EQUIPE RECUSADA',
              child: Column(
                children: [
                  Text(
                    aprovada ? 'A equipe segue!' : 'Uma tocha se apagou',
                    style: t.headlineMedium,
                  ),
                  const SizedBox(height: Espaco.e1),
                  Text(
                    '${proposta.aprovacoes} a favor, ${proposta.rejeicoes} contra.',
                    style: t.bodyLarge?.copyWith(color: c.texto2),
                  ),
                  if (!aprovada) ...[
                    const SizedBox(height: Espaco.e3),
                    Tochas(apagadas: e.rejections),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Espaco.e6),
            Text('Como cada um votou', style: t.headlineSmall),
            const SizedBox(height: Espaco.e3),
            for (final (i, j) in widget.jogadores.indexed) ...[
              if (i > 0) const SizedBox(height: Espaco.e2),
              LinhaDeVoto(
                nome: j.displayName,
                indice: j.seat ?? i,
                segue: votos[j.uid] ?? false,
              ),
            ],
          ],
        );

      case 'camara':
        final fracassos = e.failCounts.isEmpty ? 0 : e.failCounts.last;
        final membros = proposta?.memberUids.length ?? 0;
        if (proposta == null || membros == 0) return carregando;
        final numero = e.missionResults.length;
        if (_cartasDaCamara != numero) {
          _cartasDaCamara = numero;
          _cartasViradas = false;
          _cartas = [
            for (var i = 0; i < membros - fracassos; i++) true,
            for (var i = 0; i < fracassos; i++) false,
          ]..shuffle();
        }
        return Etapa(
          rodape: BotaoSala(
            rotulo: 'Continuar',
            icone: Symbols.arrow_forward_rounded,
            iconeNoFim: true,
            luz: luz,
            bloco: true,
            onPressed: _cartasViradas
                ? () => p.marcarResultadoMissaoVisto(e.gameId, numero)
                : null,
          ),
          children: [
            const SizedBox(height: Espaco.e4),
            CartasReveladas(
              key: ValueKey('cartas$numero'),
              cartas: _cartas!,
              aoTerminar: () {
                if (mounted) setState(() => _cartasViradas = true);
              },
            ),
            const SizedBox(height: Espaco.e6),
            AnimatedOpacity(
              duration: Movimento.lenta,
              opacity: _cartasViradas ? 1 : 0,
              child: ResultadoDaCamara(
                numero: numero,
                explorada: e.missionResults.last,
                armadilhas: fracassos,
              ),
            ),
          ],
        );

      case 'proposing':
        if (e.leaderUid != eu) {
          return PasseOCelular(
            matiz: matizExpedicao,
            nome: guia.nome,
            indice: guia.indice,
            titulo: '${guia.nome} está montando a equipe',
            texto:
                '${e.teamSize} pessoas entram na câmara ${e.round}. Conversem: '
                'depois todo mundo vota.',
            extra: _painel(),
          );
        }
        final falta = e.teamSize - _equipe.length;
        return Etapa(
          rodape: BotaoSala(
            rotulo: falta > 0 ? 'Escolha mais $falta' : 'Propor a equipe',
            icone: Symbols.how_to_vote_rounded,
            luz: luz,
            bloco: true,
            carregando: p.isLoading,
            onPressed: falta == 0
                ? () => agirNaSala(
                    context,
                    p,
                    () => p.proporEquipeRemota(_equipe.toList()),
                  )
                : null,
          ),
          children: [
            _painel(),
            const SizedBox(height: Espaco.e5),
            CabecaDaEtapa(
              nome: guia.nome,
              indice: guia.indice,
              titulo: 'Você é o guia',
              texto:
                  'Escolha ${e.teamSize} pessoas para entrar na câmara. '
                  'Todos vão votar.',
            ),
            const SizedBox(height: Espaco.e4),
            for (final (i, j) in widget.jogadores.indexed) ...[
              if (i > 0) const SizedBox(height: Espaco.e2),
              LinhaJogador(
                nome: j.displayName,
                indice: j.seat ?? i,
                selecionado: _equipe.contains(j.uid),
                apoio: j.uid == eu ? 'Você' : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (!_equipe.remove(j.uid) && _equipe.length < e.teamSize) {
                      _equipe.add(j.uid);
                    }
                  });
                },
                direita: _equipe.contains(j.uid)
                    ? Icon(
                        Symbols.check_circle_rounded,
                        fill: 1,
                        color: luz.tinta,
                      )
                    : null,
              ),
            ],
          ],
        );

      case 'voting':
        final equipe = proposta?.memberUids ?? const <String>[];
        if (_votouNa == e.currentProposalId) {
          return PasseOCelular(
            matiz: matizExpedicao,
            icone: Symbols.how_to_vote_rounded,
            titulo: 'Voto enviado',
            texto:
                '${e.submittedCount} de ${e.expectedCount} já votaram. O '
                'resultado aparece para todos juntos.',
          );
        }
        return Etapa(
          rodape: Row(
            children: [
              Expanded(
                child: BotaoSala(
                  rotulo: 'Recusar',
                  icone: Symbols.thumb_down_rounded,
                  variante: VarianteBotao.secundario,
                  bloco: true,
                  onPressed: p.isLoading ? null : () => _votar(false),
                ),
              ),
              const SizedBox(width: Espaco.e3),
              Expanded(
                child: BotaoSala(
                  rotulo: 'Seguir',
                  icone: Symbols.thumb_up_rounded,
                  luz: c.explorador,
                  bloco: true,
                  carregando: p.isLoading,
                  onPressed: () => _votar(true),
                ),
              ),
            ],
          ),
          children: [
            _painel(),
            const SizedBox(height: Espaco.e5),
            CabecaDaEtapa(
              nome: guia.nome,
              indice: guia.indice,
              titulo: 'A equipe segue?',
              texto:
                  'Proposta de ${guia.nome}. O voto aparece aberto para '
                  'todos no fim.',
            ),
            const SizedBox(height: Espaco.e4),
            Wrap(
              spacing: Espaco.e2,
              runSpacing: Espaco.e2,
              children: [
                for (final uid in equipe)
                  ChipJogador(
                    nome: _jogador(uid).nome,
                    indice: _jogador(uid).indice,
                  ),
              ],
            ),
          ],
        );

      case 'mission':
        final equipe = proposta?.memberUids ?? const <String>[];
        final entro = equipe.contains(eu);
        if (entro && _jogouNa != e.currentProposalId) {
          return Etapa(
            children: [
              const CabecaDaEtapa(
                titulo: 'Dentro da câmara',
                texto: 'Escolha sua carta em segredo.',
              ),
              const SizedBox(height: Espaco.e6),
              EscolhaDaCarta(
                saqueador: _saqueador,
                ocupado: p.isLoading,
                aoEscolher: _jogar,
              ),
            ],
          );
        }
        return PasseOCelular(
          matiz: matizExpedicao,
          icone: Symbols.door_open_rounded,
          titulo: entro ? 'Carta jogada' : 'A equipe está na câmara',
          texto:
              '${e.submittedCount} de ${e.expectedCount} já jogaram. As '
              'cartas viram juntas, embaralhadas.',
          extra: Wrap(
            alignment: WrapAlignment.center,
            spacing: Espaco.e2,
            runSpacing: Espaco.e2,
            children: [
              for (final uid in equipe)
                ChipJogador(
                  nome: _jogador(uid).nome,
                  indice: _jogador(uid).indice,
                ),
            ],
          ),
        );

      case 'lantern':
        final dono = _jogador(e.lanternHolderUid);
        if (e.lanternHolderUid != eu) {
          return PasseOCelular(
            matiz: matizExpedicao,
            nome: dono.nome,
            indice: dono.indice,
            titulo: '${dono.nome} está com a Lanterna',
            texto:
                'Guiou a última câmara e pode ver a carta de alguém da equipe '
                '(uma vez na partida).',
          );
        }
        final equipe = [
          for (final uid in proposta?.memberUids ?? const <String>[])
            if (uid != eu) uid,
        ];
        return Etapa(
          rodape: BotaoSala(
            rotulo: 'Guardar a Lanterna',
            icone: Symbols.flashlight_off_rounded,
            variante: VarianteBotao.secundario,
            bloco: true,
            onPressed: p.isLoading ? null : () => _lanterna(null),
          ),
          children: [
            const CabecaDaEtapa(
              titulo: 'Usar a Lanterna?',
              texto:
                  'Você guiou essa câmara. Toque em alguém da equipe para ver '
                  'a carta que jogou. Todos vão saber em quem você usou, mas '
                  'só você vê a carta. Funciona uma vez na partida.',
            ),
            const SizedBox(height: Espaco.e4),
            for (final (i, uid) in equipe.indexed) ...[
              if (i > 0) const SizedBox(height: Espaco.e2),
              LinhaJogador(
                nome: _jogador(uid).nome,
                indice: _jogador(uid).indice,
                onTap: p.isLoading ? null : () => _lanterna(uid),
                direita: Icon(Symbols.flashlight_on_rounded, color: luz.tinta),
              ),
            ],
            if (equipe.isEmpty)
              Text(
                'Só você entrou nesta câmara. Guarde a Lanterna.',
                style: t.bodyMedium?.copyWith(color: c.texto2),
              ),
          ],
        );

      case 'visao':
        final privado = widget.privado!;
        return Etapa(
          rodape: BotaoSala(
            rotulo: 'Entendi',
            icone: Symbols.visibility_off_rounded,
            luz: luz,
            bloco: true,
            onPressed: () => setState(() => _verLanterna = false),
          ),
          children: [
            const CabecaDaEtapa(
              titulo: 'A Lanterna mostrou',
              texto: 'Só você viu. Decida o que contar à mesa.',
            ),
            const SizedBox(height: Espaco.e5),
            VisaoDaLanterna(
              nome: _jogador(privado.lanternaAlvoUid).nome,
              avancou: privado.lanternaCarta ?? true,
            ),
          ],
        );

      case 'over':
        final tamanhos =
            ResistenciaConstants.tamanhosEquipePorJogadores[e.playerCount] ??
            const <int>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Etapa(
                children: [
                  FimDaExpedicao(
                    exploradoresVenceram: e.winner == 'resistance',
                    porTochas:
                        e.winner == 'spies' &&
                        e.rejections >= ResistenciaConstants.maxRejeicoes,
                    resultados: e.missionResults,
                    tamanhos: tamanhos,
                    jogadores: e.playerCount,
                    papeis: [
                      for (final (i, j) in widget.jogadores.indexed)
                        (
                          nome: j.displayName,
                          indice: j.seat ?? i,
                          saqueador: j.revealedTeam == 'evil',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            RodapeDoFimOnline(sala: p, matiz: matizExpedicao),
          ],
        );

      default:
        return carregando;
    }
  }
}
