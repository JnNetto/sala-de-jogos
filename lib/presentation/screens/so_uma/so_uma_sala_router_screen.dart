import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/so_uma_constants.dart';
import '../../../data/models/so_uma_estado_remoto.dart';
import '../../../data/models/so_uma_jogador_remoto.dart';
import '../../../data/models/so_uma_rodada_remota.dart';
import '../../../data/models/so_uma_sala.dart';
import '../../navegacao.dart';
import '../../providers/so_uma_sala_provider.dart';
import '../../widgets/sala/aviso.dart';
import '../../widgets/sala/sala_online.dart';
import '../../widgets/so_uma/pecas_so_uma.dart';
import 'so_uma_lobby_remoto_screen.dart';
import 'so_uma_mesa_remota_screen.dart';

/// A sala online do Só uma!, numa rota só. Assina a sala, os jogadores, o
/// estado e a rodada uma vez e troca de fase com um fade-through.
class SoUmaSalaRouterScreen extends StatefulWidget {
  const SoUmaSalaRouterScreen({super.key, this.restaurarUltimaSala = false});

  /// Vem do "Continuar": busca a última sala salva antes de assinar.
  final bool restaurarUltimaSala;

  @override
  State<SoUmaSalaRouterScreen> createState() => _SoUmaSalaRouterScreenState();
}

class _SoUmaSalaRouterScreenState extends State<SoUmaSalaRouterScreen> {
  late final SoUmaSalaProvider _provider;
  final _assinaturas = <StreamSubscription<Object?>>[];
  StreamSubscription<SoUmaRodadaRemota?>? _assinaturaDaRodada;
  String? _rodadaId;

  bool _restaurando = false;
  bool _semSala = false;
  bool _saindo = false;

  SoUmaSala? _sala;
  List<SoUmaJogadorRemoto> _jogadores = const [];
  bool _jogadoresChegaram = false;
  SoUmaEstadoRemoto? _estado;
  SoUmaRodadaRemota? _rodada;

  /// Se o resultado de cada rodada (partida:rodadas) já foi visto aqui.
  final _vistos = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _provider = context.read<SoUmaSalaProvider>();
    if (widget.restaurarUltimaSala) {
      _restaurando = true;
      _provider.restaurarUltimaSala().then((ok) {
        if (!mounted) return;
        setState(() => _restaurando = false);
        if (ok && _provider.sala != null) {
          _ouvir();
        } else {
          setState(() => _semSala = true);
        }
      });
    } else if (_provider.sala != null) {
      _ouvir();
    } else {
      _semSala = true;
    }
  }

  void _ouvir() {
    final p = _provider;
    _sala = p.sala;
    _jogadores = p.jogadores;
    _estado = p.estado;
    void ignorar(Object _) {}

    _assinaturas.addAll([
      p.observarSalaAtual().listen((sala) {
        if (!mounted || _saindo) return;
        if (sala == null) {
          p.esquecerUltimaSala();
          setState(() => _semSala = true);
          return;
        }
        if (sala.status == 'lobby') {
          _vistos.clear();
          p.resetarMarcadoresResultadoRodada();
        }
        setState(() => _sala = sala);
      }, onError: ignorar),
      p.observarJogadoresAtuais().listen((jogadores) {
        if (!mounted || _saindo) return;
        setState(() {
          _jogadores = jogadores;
          _jogadoresChegaram = true;
        });
        _verificarSeFuiRemovido();
      }, onError: ignorar),
      p.observarEstadoAtual().listen((estado) {
        if (!mounted || _saindo) return;
        setState(() => _estado = estado);
        _ajustarRodada();
        _carregarVisto();
      }, onError: ignorar),
    ]);
    _ajustarRodada();
    _carregarVisto();
  }

  /// A rodada (a carta e as pistas) é escondida de quem adivinha: só os
  /// outros assinam.
  void _ajustarRodada() {
    final estado = _estado;
    final id = estado == null || estado.guesserUid == _provider.uid
        ? null
        : estado.currentRoundId;
    if (id == _rodadaId) return;
    _assinaturaDaRodada?.cancel();
    _assinaturaDaRodada = null;
    _rodadaId = id;
    _rodada = null;
    if (id == null) return;
    _assinaturaDaRodada = _provider.observarRodadaPorId(id).listen((r) {
      if (mounted) setState(() => _rodada = r);
    }, onError: (Object _) {});
  }

  String? get _chaveDoResultado {
    final e = _estado;
    if (e == null || e.historico.isEmpty) return null;
    return '${e.gameId}:${e.historico.length}';
  }

  void _carregarVisto() {
    final e = _estado;
    final sala = _sala;
    final chave = _chaveDoResultado;
    if (e == null || sala == null || chave == null) return;
    if (_vistos.containsKey(chave)) return;
    _provider
        .resultadoRodadaVisto(
          roomId: sala.id,
          gameId: e.gameId,
          quantidadeHistorico: e.historico.length,
        )
        .then((visto) {
          if (mounted) setState(() => _vistos[chave] = visto);
        });
  }

  Future<void> _marcarVisto() async {
    final e = _estado;
    final sala = _sala;
    final chave = _chaveDoResultado;
    if (e == null || sala == null || chave == null) return;
    setState(() => _vistos[chave] = true);
    await _provider.marcarResultadoRodadaVisto(
      roomId: sala.id,
      gameId: e.gameId,
      quantidadeHistorico: e.historico.length,
    );
  }

  void _verificarSeFuiRemovido() {
    final uid = _provider.uid;
    if (!_jogadoresChegaram || uid == null || _jogadores.isEmpty) return;
    if (!_provider.podeDetectarRemocao) return;
    if (_jogadores.any((j) => j.uid == uid)) return;
    _saindo = true;
    final navigator = Navigator.of(context);
    mostrarAviso(
      context,
      'Você foi tirado da sala pelo host.',
      tipo: TipoAviso.info,
    );
    _provider.esquecerUltimaSala().then((_) {
      if (mounted) navigator.popUntil(ehBaseDosJogos);
    });
  }

  @override
  void dispose() {
    for (final a in _assinaturas) {
      a.cancel();
    }
    _assinaturaDaRodada?.cancel();
    super.dispose();
  }

  String get _fase {
    final sala = _sala;
    if (_semSala) return 'sem-sala';
    if (_restaurando || sala == null) return 'carregando';
    if (sala.status == 'lobby') return 'lobby';
    final estado = _estado;
    if (estado == null) return 'carregando';
    final chave = _chaveDoResultado;
    if (chave != null && !_vistos.containsKey(chave)) return 'carregando';
    return 'jogo';
  }

  @override
  Widget build(BuildContext context) {
    final fase = _fase;
    final chave = _chaveDoResultado;
    final Widget tela = switch (fase) {
      'sem-sala' => const SemSalaOnline(
        nomeDoJogo: SoUmaConstants.jogoNome,
        matiz: matizSoUma,
      ),
      'carregando' => const SalaCarregando(
        nomeDoJogo: SoUmaConstants.jogoNome,
        matiz: matizSoUma,
      ),
      'lobby' => SoUmaLobbyRemotoScreen(sala: _sala!, jogadores: _jogadores),
      _ => SoUmaMesaRemotaScreen(
        estado: _estado!,
        jogadores: _jogadores,
        rodada: _rodada,
        resultadoPendente: chave != null && _vistos[chave] == false,
        aoVerResultado: _marcarVisto,
      ),
    };
    return TrocaDeFase(fase: fase, child: tela);
  }
}
