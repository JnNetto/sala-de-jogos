import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/aneis_constants.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/aneis_carta_publica.dart';
import '../../../data/models/aneis_estado_remoto.dart';
import '../../../data/models/aneis_jogador_remoto.dart';
import '../../../data/models/aneis_knower_view.dart';
import '../../../data/models/aneis_sala.dart';
import '../../navegacao.dart';
import '../../providers/aneis_sala_provider.dart';
import '../../widgets/sala/aviso.dart';
import '../../widgets/sala/sala_online.dart';
import 'aneis_fim_remoto_screen.dart';
import 'aneis_lobby_remoto_screen.dart';
import 'aneis_mesa_remota_screen.dart';

/// A sala online do Nos Anéis, numa rota só. Assina a sala, os jogadores, o
/// estado e a mão uma única vez e troca de fase (lobby, mesa, fim) com um
/// fade-through, conforme o servidor manda.
class AneisSalaRouterScreen extends StatefulWidget {
  const AneisSalaRouterScreen({super.key, this.restaurarUltimaSala = false});

  /// Vem do "Continuar": busca a última sala salva antes de assinar.
  final bool restaurarUltimaSala;

  @override
  State<AneisSalaRouterScreen> createState() => _AneisSalaRouterScreenState();
}

class _AneisSalaRouterScreenState extends State<AneisSalaRouterScreen> {
  late final AneisSalaProvider _provider;
  final _assinaturas = <StreamSubscription<Object?>>[];
  StreamSubscription<AneisKnowerView?>? _assinaturaDaVisao;

  bool _restaurando = false;
  bool _semSala = false;
  bool _saindo = false;

  AneisSala? _sala;
  List<AneisJogadorRemoto> _jogadores = const [];
  bool _jogadoresChegaram = false;
  AneisEstadoRemoto? _estado;
  List<AneisCartaPublica> _mao = const [];
  AneisKnowerView? _visao;

  @override
  void initState() {
    super.initState();
    _provider = context.read<AneisSalaProvider>();
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
    _mao = p.mao;

    _assinaturas.addAll([
      p.observarSalaAtual().listen((sala) {
        if (!mounted || _saindo) return;
        if (sala == null) {
          // A sala foi apagada: não há para onde voltar.
          p.esquecerUltimaSala();
          setState(() => _semSala = true);
          return;
        }
        setState(() => _sala = sala);
      }, onError: _semAcesso),
      p.observarJogadoresAtuais().listen((jogadores) {
        if (!mounted || _saindo) return;
        setState(() {
          _jogadores = jogadores;
          _jogadoresChegaram = true;
        });
        _verificarSeFuiRemovido();
      }, onError: _semAcesso),
      p.observarEstadoAtual().listen((estado) {
        if (!mounted || _saindo) return;
        setState(() => _estado = estado);
        _ajustarVisaoDoKnower();
      }, onError: _semAcesso),
      p.observarMaoAtual().listen((mao) {
        if (!mounted || _saindo) return;
        setState(() => _mao = mao);
      }, onError: _semAcesso),
    ]);
    _ajustarVisaoDoKnower();
  }

  /// As regras secretas só existem para quem é o knower da partida.
  void _ajustarVisaoDoKnower() {
    if (_provider.souKnower) {
      _assinaturaDaVisao ??= _provider.observarVisaoKnowerAtual().listen((v) {
        if (mounted) setState(() => _visao = v);
      });
    } else if (_assinaturaDaVisao != null) {
      _assinaturaDaVisao!.cancel();
      _assinaturaDaVisao = null;
      _visao = null;
    }
  }

  /// As regras do Firestore só deixam ler a sala quem está nela: se a
  /// leitura passa a ser negada, a pessoa foi tirada (ou a sala sumiu).
  void _semAcesso(Object erro) {
    if (erro is! FirebaseException || erro.code != 'permission-denied') return;
    if (!mounted || _saindo) return;
    _saindo = true;
    final navigator = Navigator.of(context);
    mostrarAviso(
      context,
      'Você não está mais nesta sala.',
      tipo: TipoAviso.info,
    );
    _provider.esquecerUltimaSala().then((_) {
      if (mounted) navigator.popUntil(ehBaseDosJogos);
    });
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
    _assinaturaDaVisao?.cancel();
    super.dispose();
  }

  String get _fase {
    final sala = _sala;
    if (_semSala) return 'sem-sala';
    if (_restaurando || sala == null) return 'carregando';
    if (sala.status == 'lobby') return 'lobby';
    final estado = _estado;
    if (estado == null) return 'carregando';
    if (estado.terminou || sala.status == 'finished') return 'fim';
    return 'mesa';
  }

  @override
  Widget build(BuildContext context) {
    final fase = _fase;
    final Widget tela = switch (fase) {
      'sem-sala' => const SemSalaOnline(
        nomeDoJogo: AneisConstants.jogoNome,
        matiz: Matiz.ceu,
      ),
      'carregando' => const SalaCarregando(
        nomeDoJogo: AneisConstants.jogoNome,
        matiz: Matiz.ceu,
      ),
      'lobby' => AneisLobbyRemotoScreen(sala: _sala!, jogadores: _jogadores),
      'fim' => AneisFimRemotoScreen(estado: _estado!, jogadores: _jogadores),
      _ => AneisMesaRemotaScreen(
        estado: _estado!,
        jogadores: _jogadores,
        mao: _mao,
        visaoKnower: _visao,
      ),
    };

    return TrocaDeFase(fase: fase, child: tela);
  }
}
