import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/resistencia_constants.dart';
import '../../../data/models/resistencia_estado_remoto.dart';
import '../../../data/models/resistencia_jogador_remoto.dart';
import '../../../data/models/resistencia_privado.dart';
import '../../../data/models/resistencia_proposta_remota.dart';
import '../../../data/models/resistencia_sala.dart';
import '../../navegacao.dart';
import '../../providers/resistencia_sala_provider.dart';
import '../../widgets/expedicao/pecas_expedicao.dart';
import '../../widgets/sala/aviso.dart';
import '../../widgets/sala/sala_online.dart';
import 'expedicao_entrada_sala_screen.dart';
import 'expedicao_mesa_remota_screen.dart';

/// A sala online da Expedição, numa rota só. Assina a sala, os jogadores,
/// o papel, o estado e a proposta da vez uma vez cada, e troca de fase com
/// um fade-through.
class ExpedicaoSalaRouterScreen extends StatefulWidget {
  const ExpedicaoSalaRouterScreen({
    super.key,
    this.restaurarUltimaSala = false,
  });

  final bool restaurarUltimaSala;

  @override
  State<ExpedicaoSalaRouterScreen> createState() =>
      _ExpedicaoSalaRouterScreenState();
}

class _ExpedicaoSalaRouterScreenState extends State<ExpedicaoSalaRouterScreen> {
  late final ResistenciaSalaProvider _provider;
  final _assinaturas = <StreamSubscription<Object?>>[];
  StreamSubscription<ResistenciaPropostaRemota?>? _assinaturaDaProposta;
  String? _propostaId;

  bool _restaurando = false;
  bool _semSala = false;
  bool _saindo = false;

  ResistenciaSala? _sala;
  List<ResistenciaJogadorRemoto> _jogadores = const [];
  bool _jogadoresChegaram = false;
  ResistenciaPrivado? _privado;
  ResistenciaEstadoRemoto? _estado;
  ResistenciaPropostaRemota? _proposta;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ResistenciaSalaProvider>();
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
    _privado = p.privado;

    _assinaturas.addAll([
      p.observarSalaAtual().listen((sala) {
        if (!mounted || _saindo) return;
        if (sala == null) {
          p.esquecerUltimaSala();
          setState(() => _semSala = true);
          return;
        }
        if (sala.status == 'lobby') p.limparMarcadoresPartida();
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
      p.observarMeuPrivadoAtual().listen((privado) {
        if (mounted && !_saindo) setState(() => _privado = privado);
      }, onError: _semAcesso),
      p.observarEstadoAtual().listen((estado) {
        if (!mounted || _saindo) return;
        setState(() => _estado = estado);
        _ajustarProposta();
      }, onError: _semAcesso),
    ]);
    _ajustarProposta();
  }

  /// A proposta que importa: a da vez (votação, câmara) ou a última (o
  /// resultado do voto, a Lanterna).
  void _ajustarProposta() {
    final e = _estado;
    final id = e?.currentProposalId ?? e?.lastProposalId;
    if (id == _propostaId) return;
    _assinaturaDaProposta?.cancel();
    _propostaId = id;
    _proposta = null;
    if (id == null) return;
    _assinaturaDaProposta = _provider.observarPropostaPorId(id).listen((
      proposta,
    ) {
      if (mounted) setState(() => _proposta = proposta);
    }, onError: (Object _) {});
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
    _assinaturaDaProposta?.cancel();
    super.dispose();
  }

  /// O que mostrar, na ordem: o papel (se ainda não viu), o resultado do
  /// último voto e o da última câmara (se ainda não viu), e a fase.
  String _fase(ResistenciaSalaProvider p) {
    final sala = _sala;
    if (_semSala) return 'sem-sala';
    if (_restaurando || sala == null) return 'carregando';
    if (sala.status == 'lobby') return 'lobby';
    final e = _estado;
    if (e == null) return 'carregando';
    final jogo = e.gameId;

    if (e.phase != 'over') {
      final viu = p.papelReveladoSync(jogo);
      if (viu == null) {
        _depois(() => p.garantirPapelReveladoCarregado(jogo));
        return 'carregando';
      }
      if (!viu) return 'papel';
    }

    final ultima = e.lastProposalId;
    if (ultima != null) {
      final viu = p.resultadoPropostaVistoSync(jogo, ultima);
      if (viu == null) {
        _depois(() => p.garantirResultadoPropostaCarregado(jogo, ultima));
        return 'carregando';
      }
      if (!viu) return 'voto';
    }

    final camaras = e.missionResults.length;
    if (camaras > 0) {
      final viu = p.resultadoMissaoVistoSync(jogo, camaras);
      if (viu == null) {
        _depois(() => p.garantirResultadoMissaoCarregado(jogo, camaras));
        return 'carregando';
      }
      if (!viu) return 'camara';
    }
    return e.phase;
  }

  void _depois(VoidCallback f) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => f());

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ResistenciaSalaProvider>();
    final fase = _fase(p);
    final Widget tela = switch (fase) {
      'sem-sala' => const SemSalaOnline(
        nomeDoJogo: ResistenciaConstants.jogoNome,
        matiz: matizExpedicao,
      ),
      'carregando' => const SalaCarregando(
        nomeDoJogo: ResistenciaConstants.jogoNome,
        matiz: matizExpedicao,
      ),
      'lobby' => ExpedicaoLobbyRemotoScreen(
        sala: _sala!,
        jogadores: _jogadores,
      ),
      _ => ExpedicaoMesaRemotaScreen(
        etapa: fase,
        estado: _estado!,
        jogadores: _jogadores,
        privado: _privado,
        proposta: _proposta,
      ),
    };
    // A mesa troca de etapa por dentro; aqui só muda entre sala e partida.
    final chave = switch (fase) {
      'sem-sala' || 'carregando' || 'lobby' => fase,
      _ => 'mesa',
    };
    return TrocaDeFase(fase: chave, child: tela);
  }
}
