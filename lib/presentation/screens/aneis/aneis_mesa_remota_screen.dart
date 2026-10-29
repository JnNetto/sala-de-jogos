import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/aneis_constants.dart';
import '../../../core/enums/aneis_regiao.dart';
import '../../../core/theme/sala_tokens.dart';
import '../../../data/models/aneis_carta_publica.dart';
import '../../../data/models/aneis_estado_remoto.dart';
import '../../../data/models/aneis_jogador_remoto.dart';
import '../../../data/models/aneis_knower_view.dart';
import '../../providers/aneis_sala_provider.dart';
import '../../widgets/aneis/cores_dos_aneis.dart';
import '../../widgets/aneis/folha_regiao.dart';
import '../../widgets/aneis/pecas_aneis.dart';
import '../../widgets/aneis/tabuleiro_aneis.dart';
import '../../widgets/sala/aviso.dart';
import '../../widgets/sala/botao_sala.dart';
import '../../widgets/sala/dialogo.dart';
import '../../widgets/sala/fim_de_jogo.dart';
import '../../widgets/sala/jogador_sala.dart';
import '../../widgets/sala/pressionavel.dart';
import '../../widgets/sala/sala_online.dart';
import '../../widgets/sala/tela_da_sala.dart';

/// A mesa do Nos Anéis: de quem é a vez, o último lance, o tabuleiro, quem
/// está na mesa e, embaixo, a mão. Para jogar, escolhe-se uma carta e
/// toca-se numa região.
class AneisMesaRemotaScreen extends StatefulWidget {
  const AneisMesaRemotaScreen({
    super.key,
    required this.estado,
    required this.jogadores,
    required this.mao,
    required this.visaoKnower,
  });

  final AneisEstadoRemoto estado;
  final List<AneisJogadorRemoto> jogadores;
  final List<AneisCartaPublica> mao;
  final AneisKnowerView? visaoKnower;

  @override
  State<AneisMesaRemotaScreen> createState() => _AneisMesaRemotaScreenState();
}

class _AneisMesaRemotaScreenState extends State<AneisMesaRemotaScreen> {
  String? _selecionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tutorial());
  }

  @override
  void didUpdateWidget(AneisMesaRemotaScreen antigo) {
    super.didUpdateWidget(antigo);
    // A carta escolhida saiu da mão (jogada ou devolvida): solta a escolha.
    if (_selecionada != null && !widget.mao.any((c) => c.id == _selecionada)) {
      _selecionada = null;
    }
  }

  Future<void> _tutorial() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AneisConstants.prefsKeyTutorialVisto) == true) return;
    if (!mounted) return;
    await mostrarDialogo(
      context,
      matiz: Matiz.ceu,
      icone: Symbols.join_inner_rounded,
      barra: 'COMO FUNCIONA',
      titulo: 'Os três anéis',
      corpo:
          'Cada anel tem uma regra escondida. Uma carta entra em todos os '
          'anéis cuja regra ela cumpre, inclusive nas interseções.\n\n'
          'Toque numa região para ver as cartas dela. Segure para espiar '
          'sem abrir.',
      acao: 'Entendi',
    );
    await prefs.setBool(AneisConstants.prefsKeyTutorialVisto, true);
  }

  Future<void> _posicionar(AneisRegiao regiao) async {
    final provider = context.read<AneisSalaProvider>();
    final estado = widget.estado;

    // Toda jogada confirma antes: um toque sem querer no tabuleiro, com uma
    // carta escolhida, não pode virar palpite.
    final julgando = provider.emJulgamentoKnower;
    final carta = julgando
        ? estado.pendingJogada?.texto
        : widget.mao.where((c) => c.id == _selecionada).firstOrNull?.texto;
    if (carta == null) return;
    final confirmou = await mostrarDialogo(
      context,
      matiz: Matiz.ceu,
      barra: julgando || provider.emSetupKnower ? 'CONFIRMAR' : 'SEU PALPITE',
      titulo: regiao == AneisRegiao.nenhum
          ? 'Fora dos anéis?'
          : 'Em ${regiao.rotulo}?',
      corpo: julgando
          ? '"$carta" vai para ${regiao.rotulo}. Todo mundo vê na hora.'
          : provider.emSetupKnower
          ? '"$carta" vira uma pista em ${regiao.rotulo}.'
          : 'Você aposta que "$carta" vai em ${regiao.rotulo}. Acertou, '
                'joga de novo; errou, a carta vai para o lugar certo e você '
                'compra outra.',
      acao: julgando || provider.emSetupKnower ? 'Colocar aqui' : 'Jogar',
      escape: 'Escolher outra região',
    );
    if (!mounted || confirmou != true) return;

    HapticFeedback.mediumImpact();
    if (provider.emJulgamentoKnower) {
      final ok = await provider.julgarPosicao(regiao: regiao.id);
      if (mounted && !ok && provider.erro != null) {
        mostrarAviso(context, provider.erro!);
      }
      return;
    }

    final id = _selecionada;
    if (id == null || !widget.mao.any((c) => c.id == id)) return;
    final ok = await provider.posicionarCarta(coisaId: id, regiao: regiao.id);
    if (!mounted) return;
    if (ok) {
      setState(() => _selecionada = null);
    } else if (provider.erro != null) {
      mostrarAviso(context, provider.erro!);
    }
  }

  Future<void> _desfazer() async {
    final provider = context.read<AneisSalaProvider>();
    final ok = await provider.desfazerJulgamento();
    if (mounted && !ok && provider.erro != null) {
      mostrarAviso(context, provider.erro!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AneisSalaProvider>();
    final estado = widget.estado;
    final souKnower = provider.souKnower;
    final ocupado = provider.isLoading;
    final posicionando =
        !ocupado &&
        (((provider.minhaVez || provider.emSetupKnower) &&
                _selecionada != null) ||
            provider.emJulgamentoKnower);
    final maoAtiva = !ocupado && (provider.minhaVez || provider.emSetupKnower);
    final regras = widget.visaoKnower?.regras ?? const [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) {
          sairDaMesa(
            context,
            nomeDoJogo: AneisConstants.jogoNome,
            matiz: Matiz.ceu,
          );
        }
      },
      child: TelaDaSala(
        sobretitulo: '${estado.baralhoCount} NO BARALHO',
        titulo: 'Nos Anéis',
        matiz: Matiz.ceu,
        inicio: const BotaoSairDaMesa(
          nomeDoJogo: AneisConstants.jogoNome,
          matiz: Matiz.ceu,
        ),
        acao: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (souKnower && estado.podeDesfazer)
              BotaoIcone(
                icone: Symbols.undo_rounded,
                rotulo: 'Desfazer a última',
                onPressed: ocupado ? null : _desfazer,
              )
            else if (provider.souHost)
              BotaoEncerrarPartida(sala: provider),
          ],
        ),
        corpo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Espaco.margemTela,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Vez(
                    estado: estado,
                    jogadores: widget.jogadores,
                    escolheuCarta: _selecionada != null,
                  ),
                  _Lance(estado: estado, meuUid: provider.uid),
                  if (souKnower && regras.isNotEmpty) ...[
                    const SizedBox(height: Espaco.e2),
                    _RegrasSecretas(visao: widget.visaoKnower!),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Espaco.e3,
                  Espaco.e2,
                  Espaco.e3,
                  0,
                ),
                child: TabuleiroAneis(
                  cartas: estado.tabuleiro,
                  posicionando: posicionando,
                  destaque: estado.pendingJogada == null
                      ? null
                      : AneisRegiao.fromId(
                          estado.pendingJogada!.regiaoEscolhida,
                        ),
                  aoEscolherRegiao: _posicionar,
                  aoVerRegiao: (regiao) => mostrarCartasDaRegiao(
                    context,
                    regiao: regiao,
                    cartas: estado.tabuleiro,
                    aneis: estado.aneis,
                    regraSecreta: regras
                        .where((r) => r.anel == regiao.id)
                        .firstOrNull,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Espaco.e2),
            _Mesa(estado: estado, jogadores: widget.jogadores),
          ],
        ),
        rodape: !souKnower || estado.emSetup
            ? _Mao(
                mao: widget.mao,
                ativa: maoAtiva,
                carregando:
                    ocupado && (maoAtiva || provider.emJulgamentoKnower),
                selecionada: _selecionada,
                vazia: souKnower
                    ? 'As pistas já estão no tabuleiro.'
                    : 'Sua mão está vazia.',
                aoEscolher: (id) {
                  HapticFeedback.selectionClick();
                  setState(() => _selecionada = _selecionada == id ? null : id);
                },
              )
            : SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ),
    );
  }
}

/// O cartaz da vez: quem joga agora e o que fazer. Aceso quando é com você.
class _Vez extends StatelessWidget {
  const _Vez({
    required this.estado,
    required this.jogadores,
    required this.escolheuCarta,
  });

  final AneisEstadoRemoto estado;
  final List<AneisJogadorRemoto> jogadores;
  final bool escolheuCarta;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(Matiz.ceu);
    final p = context.watch<AneisSalaProvider>();

    final knower = estado.knowerNome ?? 'Quem sabe as regras';
    final daVez = jogadores
        .where((j) => j.uid == estado.currentUid)
        .firstOrNull;
    final nome = daVez?.displayName ?? 'alguém';
    final comKnower = estado.emSetup || estado.emJulgamento;
    final quem = comKnower ? estado.knowerUid : estado.currentUid;
    final pendente = estado.pendingJogada;
    final comigo = p.minhaVez || p.emSetupKnower || p.emJulgamentoKnower;

    final (String titulo, String apoio) = switch (estado) {
      _ when p.emSetupKnower => (
        'Coloque as pistas',
        escolheuCarta
            ? 'Agora toque na região certa desta carta.'
            : 'Escolha uma carta da mão. São '
                  '${AneisConstants.pistasIniciais} pistas, uma por vez.',
      ),
      _ when estado.emSetup => (
        '$knower põe as pistas',
        'Elas mostram um pouco de cada regra.',
      ),
      _ when p.emJulgamentoKnower => (
        'Onde vai esta carta?',
        'Toque na região certa de "${pendente?.texto ?? ''}".',
      ),
      _ when estado.emJulgamento => (
        '$knower está decidindo',
        'Para onde vai a carta de ${pendente?.nome ?? nome}.',
      ),
      _ when p.souKnower => (
        'Vez de $nome',
        'Quando a pessoa jogar, você decide onde a carta vai.',
      ),
      _ when p.minhaVez => (
        'Sua vez!',
        escolheuCarta
            ? 'Agora toque na região do tabuleiro.'
            : 'Escolha uma carta da sua mão.',
      ),
      _ => ('Vez de $nome', 'Fique de olho no tabuleiro.'),
    };

    final indice = indiceDoJogador(jogadores, quem);
    final nomeDoAvatar = comKnower
        ? (estado.knowerNome ?? '?')
        : (daVez?.displayName ?? '?');

    return Semantics(
      liveRegion: true,
      label: '$titulo. $apoio',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: Movimento.media,
        curve: Movimento.padrao,
        padding: const EdgeInsets.all(Espaco.e3),
        decoration: BoxDecoration(
          color: comigo ? luz.suave : c.superficie,
          borderRadius: BorderRadius.circular(Raio.lg),
          border: Border.all(
            color: comigo
                ? (c.ehDia ? c.contorno : luz.cor)
                : (c.ehDia ? c.contorno : c.linha),
            width: comigo ? 2 : c.bordaControle,
          ),
          boxShadow: comigo ? c.brilho(luz.cor, alpha: .35, blur: 22) : null,
        ),
        child: Row(
          children: [
            if (estado.knowerHumano || !comKnower)
              AvatarJogador(
                nome: nomeDoAvatar,
                indice: indice,
                tamanho: 40,
                brilho: comigo,
              )
            else
              PocoIcone(icone: Symbols.smart_toy_rounded, luz: luz),
            const SizedBox(width: Espaco.e3),
            Expanded(
              child: AnimatedSwitcher(
                duration: Movimento.base,
                layoutBuilder: (atual, anteriores) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...anteriores, ?atual],
                ),
                child: Column(
                  key: ValueKey('$titulo|$apoio'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: texto.titleLarge?.copyWith(
                        color: comigo ? luz.tinta : c.texto,
                      ),
                    ),
                    Text(
                      apoio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: texto.bodyMedium?.copyWith(color: c.texto2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O último lance, numa linha: o palpite esperando julgamento, ou como
/// foi a jogada anterior.
class _Lance extends StatelessWidget {
  const _Lance({required this.estado, required this.meuUid});

  final AneisEstadoRemoto estado;
  final String? meuUid;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final pendente = estado.pendingJogada;
    final ultima = estado.ultimaJogada;

    Widget? fato;
    String chave = '';
    if (pendente != null) {
      final quem = pendente.uid == meuUid ? 'Você' : pendente.nome;
      chave = 'p${pendente.coisaId}';
      fato = FatoDoFim(
        poco: PocoIcone(icone: Symbols.hourglass_top_rounded, luz: c.aviso),
        texto: comDestaque(
          context,
          '$quem jogou ',
          pendente.texto,
          ' em ${AneisRegiao.fromId(pendente.regiaoEscolhida).rotulo}.',
        ),
      );
    } else if (ultima != null) {
      final souEu = ultima.uid == meuUid;
      final quem = souEu ? 'Você' : ultima.nome;
      chave = 'u${ultima.uid}${ultima.texto}${ultima.regiaoCerta.id}';
      fato = FatoDoFim(
        poco: ultima.acertou
            ? PocoIcone(icone: Symbols.check_circle_rounded, luz: c.sucesso)
            : PocoIcone(
                icone: Symbols.swap_horiz_rounded,
                luz: c.luz(Matiz.brasa),
              ),
        texto: ultima.acertou
            ? comDestaque(
                context,
                '$quem acertou: ',
                ultima.texto,
                ' em ${ultima.regiaoCerta.rotulo}.${souEu ? ' Jogue outra!' : ''}',
              )
            : comDestaque(
                context,
                '',
                ultima.texto,
                ' não era ${ultima.regiaoEscolhida.rotulo}. '
                    'Foi para ${ultima.regiaoCerta.rotulo}.',
              ),
      );
    }

    return AnimatedSize(
      duration: Movimento.media,
      curve: Movimento.padrao,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: Movimento.media,
        switchInCurve: Movimento.entrada,
        transitionBuilder: (filho, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -.15),
              end: Offset.zero,
            ).animate(a),
            child: filho,
          ),
        ),
        child: fato == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey(chave),
                padding: const EdgeInsets.only(top: Espaco.e2),
                child: fato,
              ),
      ),
    );
  }
}

/// As regras secretas, para quem sabe: uma linha por anel, na luz dele.
class _RegrasSecretas extends StatelessWidget {
  const _RegrasSecretas({required this.visao});

  final AneisKnowerView visao;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Espaco.e3,
        Espaco.e2,
        Espaco.e3,
        Espaco.e2,
      ),
      decoration: BoxDecoration(
        color: c.superficieFunda,
        borderRadius: BorderRadius.circular(Raio.lg),
        border: c.ehDia ? Border.all(color: c.contorno, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.lock_open_rounded, size: 14, color: c.texto3),
              const SizedBox(width: Espaco.e1),
              Text(
                'SÓ VOCÊ VÊ AS REGRAS',
                style: texto.labelSmall?.copyWith(color: c.texto3),
              ),
            ],
          ),
          const SizedBox(height: Espaco.e1),
          for (final regra in visao.regras)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 3, right: Espaco.e2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.ehDia
                            ? c.luzDoAnel(regra.anel).tinta
                            : c.luzDoAnel(regra.anel).cor,
                        width: 2.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${regra.nome}: ',
                            style: TextStyle(
                              color: c.luzDoAnel(regra.anel).tinta,
                            ),
                          ),
                          TextSpan(text: regra.texto),
                        ],
                      ),
                      style: texto.titleSmall?.copyWith(color: c.texto),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Quem está na mesa, numa fileira: a vez acende, e cada um mostra quantas
/// cartas ainda tem (ou que sabe as regras).
class _Mesa extends StatelessWidget {
  const _Mesa({required this.estado, required this.jogadores});

  final AneisEstadoRemoto estado;
  final List<AneisJogadorRemoto> jogadores;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(Matiz.ceu);
    final comKnower = estado.emSetup || estado.emJulgamento;

    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.margemTela),
        scrollDirection: Axis.horizontal,
        itemCount: jogadores.length,
        separatorBuilder: (_, _) => const SizedBox(width: Espaco.e2),
        itemBuilder: (context, i) {
          final j = jogadores[i];
          final knower = j.uid == estado.knowerUid && estado.knowerHumano;
          final daVez = knower
              ? comKnower
              : (!comKnower && j.uid == estado.currentUid);
          return AnimatedContainer(
            duration: Movimento.base,
            curve: Movimento.padrao,
            padding: const EdgeInsets.only(left: 6, right: Espaco.e3),
            decoration: BoxDecoration(
              color: daVez ? luz.suave : c.superficie,
              borderRadius: BorderRadius.circular(Raio.md),
              border: Border.all(
                color: daVez
                    ? (c.ehDia ? c.contorno : luz.cor)
                    : (c.ehDia ? c.contorno : c.linha),
                width: daVez ? 2 : c.bordaControle,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarJogador(
                  nome: j.displayName,
                  indice: j.seat ?? i,
                  tamanho: 32,
                  brilho: daVez,
                ),
                const SizedBox(width: Espaco.e2),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 96),
                      child: Text(
                        j.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: texto.titleSmall,
                      ),
                    ),
                    Text(
                      knower
                          ? 'SABE AS REGRAS'
                          : j.maoCount == 1
                          ? '1 CARTA'
                          : '${j.maoCount} CARTAS',
                      style: texto.labelSmall?.copyWith(
                        color: knower ? luz.tinta : c.texto3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A mão, numa bandeja presa embaixo. A carta escolhida sobe e acende.
class _Mao extends StatelessWidget {
  const _Mao({
    required this.mao,
    required this.ativa,
    required this.carregando,
    required this.selecionada,
    required this.vazia,
    required this.aoEscolher,
  });

  final List<AneisCartaPublica> mao;
  final bool ativa, carregando;
  final String? selecionada;
  final String vazia;
  final ValueChanged<String> aoEscolher;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final luz = c.luz(Matiz.ceu);

    return Container(
      margin: const EdgeInsets.only(top: Espaco.e3),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Raio.xxl),
        ),
        border: Border(
          top: BorderSide(
            color: c.ehDia ? c.contorno : c.linha,
            width: c.bordaControle,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: Espaco.e3, bottom: Espaco.e3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Espaco.margemTela,
                ),
                child: Row(
                  children: [
                    Text(
                      'SUA MÃO',
                      style: texto.labelMedium?.copyWith(color: c.texto2),
                    ),
                    const SizedBox(width: Espaco.e2),
                    Text(
                      '${mao.length}',
                      style: context.estilos.hud.copyWith(
                        fontSize: 16,
                        color: luz.tinta,
                      ),
                    ),
                    const Spacer(),
                    if (carregando) BolinhasCarregando(cor: luz.cor),
                  ],
                ),
              ),
              SizedBox(
                height: 92,
                child: mao.isEmpty
                    ? Center(
                        child: Text(
                          vazia,
                          style: texto.bodyMedium?.copyWith(color: c.texto3),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          Espaco.margemTela,
                          Espaco.e3,
                          Espaco.margemTela,
                          0,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: mao.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: Espaco.e2),
                        itemBuilder: (context, i) {
                          final carta = mao[i];
                          return _Carta(
                            texto: carta.texto,
                            escolhida: carta.id == selecionada,
                            ativa: ativa,
                            aoTocar: () => aoEscolher(carta.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Carta extends StatelessWidget {
  const _Carta({
    required this.texto,
    required this.escolhida,
    required this.ativa,
    required this.aoTocar,
  });

  final String texto;
  final bool escolhida, ativa;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(Matiz.ceu);
    final carta = AnimatedContainer(
      duration: Movimento.base,
      curve: Movimento.pulo,
      width: 112,
      height: 72,
      transform: Matrix4.translationValues(0, escolhida ? -8 : 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: Espaco.e2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: escolhida ? luz.suave : c.superficieElevada,
        borderRadius: BorderRadius.circular(Raio.md),
        border: Border.all(
          color: escolhida
              ? (c.ehDia ? c.contorno : luz.cor)
              : (c.ehDia ? c.contorno : c.linhaForte.withValues(alpha: .5)),
          width: escolhida ? 2.5 : c.bordaControle,
        ),
        boxShadow: escolhida
            ? [
                ...c.brilho(luz.cor, alpha: .45, blur: 20),
                if (c.ehDia)
                  BoxShadow(color: c.contorno, offset: const Offset(0, 4)),
              ]
            : c.sombraCard,
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          height: 1.15,
          color: escolhida ? luz.tinta : c.texto,
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: escolhida,
      enabled: ativa,
      label: texto,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: Movimento.base,
        opacity: ativa ? 1 : .5,
        child: Pressionavel(onTap: ativa ? aoTocar : null, child: carta),
      ),
    );
  }
}
