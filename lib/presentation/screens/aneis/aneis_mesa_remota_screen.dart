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
import '../../../data/models/aneis_regra_revelada.dart';
import '../../providers/aneis_sala_provider.dart';
import '../../widgets/aneis/cores_dos_aneis.dart';
import '../../widgets/aneis/desvendar_regra.dart';
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

/// A mesa do Cabe Aqui?: de quem é a vez, o último lance, o tabuleiro, quem
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
          'sem abrir.\n\n'
          'Na sua vez, em vez de jogar uma carta, dá para tentar desvendar '
          'a regra de um anel.',
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

  Future<void> _desvendar() async {
    final provider = context.read<AneisSalaProvider>();
    final palpite = await mostrarDesvendarRegra(context, estado: widget.estado);
    if (palpite == null || !mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _selecionada = null);
    await agirNaSala(
      context,
      provider,
      () =>
          provider.desvendarRegra(anel: palpite.anel, palpite: palpite.palpite),
    );
  }

  Future<void> _julgarPalpite(bool acertou) async {
    final provider = context.read<AneisSalaProvider>();
    HapticFeedback.mediumImpact();
    await agirNaSala(
      context,
      provider,
      () => provider.julgarRegra(acertou: acertou),
    );
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
    // Quem não é o Guardião vê só os anéis já desvendados.
    final regrasVisiveis = souKnower ? regras : estado.aneisDesvendados;
    final podeDesvendar =
        provider.minhaVez && !ocupado && aneisPorDesvendar(estado).isNotEmpty;
    final palpite = estado.pendingPalpite;

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
        titulo: AneisConstants.jogoNome,
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
        corpo: LayoutBuilder(
          builder: (context, caixa) {
            // O painel do Guardião já mostra o palpite: o lance repetiria.
            final mostrarLance = !provider.emJulgamentoDeRegraKnower;
            final topo = Padding(
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
                  if (mostrarLance)
                    _Lance(estado: estado, meuUid: provider.uid),
                  if (regrasVisiveis.isNotEmpty) ...[
                    const SizedBox(height: Espaco.e2),
                    _Regras(
                      regras: regrasVisiveis,
                      titulo: souKnower
                          ? 'SÓ VOCÊ VÊ AS REGRAS'
                          : 'REGRAS DESVENDADAS',
                    ),
                  ],
                ],
              ),
            );
            final tabuleiro = Padding(
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
                    : AneisRegiao.fromId(estado.pendingJogada!.regiaoEscolhida),
                aoEscolherRegiao: _posicionar,
                aoVerRegiao: (regiao) => mostrarCartasDaRegiao(
                  context,
                  regiao: regiao,
                  cartas: estado.tabuleiro,
                  aneis: estado.aneis,
                  regraSecreta: regrasVisiveis
                      .where((r) => r.anel == regiao.id)
                      .firstOrNull,
                ),
              ),
            );
            final mesa = Padding(
              padding: const EdgeInsets.only(top: Espaco.e2),
              child: _Mesa(estado: estado, jogadores: widget.jogadores),
            );

            // Uma estimativa do que vai em cima e embaixo do tabuleiro. Se
            // não sobrar o mínimo para ele, a tela rola e o tabuleiro fica
            // com a altura mínima, em vez de encolher até sumir.
            const minimo = 270.0;
            final ocupadoPorFora =
                78 +
                (mostrarLance && estado.ultimaJogada != null ? 84 : 0) +
                (regrasVisiveis.isEmpty
                    ? 0
                    : 34 + 24.0 * regrasVisiveis.length) +
                62;
            if (caixa.maxHeight - ocupadoPorFora >= minimo) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  topo,
                  Expanded(child: tabuleiro),
                  mesa,
                ],
              );
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  topo,
                  SizedBox(height: minimo, child: tabuleiro),
                  mesa,
                ],
              ),
            );
          },
        ),
        rodape: provider.emJulgamentoDeRegraKnower && palpite != null
            ? JulgarPalpite(
                estado: estado,
                palpite: palpite,
                regraCerta: regras
                    .where((r) => r.anel == palpite.anel)
                    .firstOrNull
                    ?.texto,
                carregando: ocupado,
                aoJulgar: _julgarPalpite,
              )
            : !souKnower || estado.emSetup
            ? _Mao(
                aoDesvendar: podeDesvendar ? _desvendar : null,
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

    final knower = estado.knowerNome ?? 'O Guardião';
    final daVez = jogadores
        .where((j) => j.uid == estado.currentUid)
        .firstOrNull;
    final nome = daVez?.displayName ?? 'alguém';
    final comKnower = estado.comGuardiao;
    final quem = comKnower ? estado.knowerUid : estado.currentUid;
    final pendente = estado.pendingJogada;
    final palpite = estado.pendingPalpite;
    final anelDoPalpite = palpite == null
        ? ''
        : nomeDoAnel(estado, palpite.anel);
    final comigo =
        p.minhaVez ||
        p.emSetupKnower ||
        p.emJulgamentoKnower ||
        p.emJulgamentoDeRegraKnower;

    final (String titulo, String apoio) = switch (estado) {
      _ when p.emSetupKnower => (
        'Coloque as pistas',
        escolheuCarta
            ? 'Agora toque na região certa desta carta.'
            : 'Uma em cada anel e uma fora. ${_faltam(estado)}',
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
      _ when p.emJulgamentoDeRegraKnower => (
        'Julgue o palpite',
        '${palpite?.nome ?? nome} acha que sabe a regra de $anelDoPalpite.',
      ),
      _ when estado.emJulgamentoDeRegra => (
        '$knower está julgando',
        '${palpite?.nome ?? nome} tentou desvendar $anelDoPalpite.',
      ),
      _ when p.souKnower => (
        'Vez de $nome',
        'Quando a pessoa jogar, você decide onde a carta vai.',
      ),
      _ when p.minhaVez => (
        'Sua vez!',
        escolheuCarta
            ? 'Agora toque na região do tabuleiro.'
            : 'Jogue uma carta da mão ou tente desvendar um anel.',
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

/// O que ainda falta na preparação do Guardião: "Faltam: Letra e uma fora."
String _faltam(AneisEstadoRemoto estado) {
  bool tem(String anel) => estado.tabuleiro.any(
    (c) =>
        c.regiao == AneisRegiao.todos || c.regiao.id.split('_').contains(anel),
  );
  final faltam = [
    for (final id in const ['palavra', 'atributo', 'contexto'])
      if (!tem(id)) nomeDoAnel(estado, id),
    if (!estado.tabuleiro.any((c) => c.regiao == AneisRegiao.nenhum))
      'uma fora',
  ];
  if (faltam.isEmpty) return '';
  final lista = faltam.length == 1
      ? faltam.first
      : '${faltam.sublist(0, faltam.length - 1).join(', ')} e ${faltam.last}';
  return 'Faltam: $lista.';
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
    final palpite = estado.pendingPalpite;
    final ultima = estado.ultimaJogada;

    Widget? fato;
    String chave = '';
    if (palpite != null) {
      final quem = palpite.uid == meuUid ? 'Você' : palpite.nome;
      chave = 'r${palpite.uid}${palpite.anel}${palpite.palpite}';
      fato = FatoDoFim(
        poco: PocoIcone(icone: Symbols.hourglass_top_rounded, luz: c.aviso),
        texto: comDestaque(
          context,
          '$quem acha que ${nomeDoAnel(estado, palpite.anel)} é ',
          palpite.palpite,
          '.',
        ),
      );
    } else if (ultima != null && ultima.desvendar) {
      final quem = ultima.uid == meuUid ? 'Você' : ultima.nome;
      final anel = nomeDoAnel(estado, ultima.anel ?? '');
      chave = 'd${ultima.uid}${ultima.anel}${ultima.acertou}';
      fato = FatoDoFim(
        poco: ultima.acertou
            ? PocoIcone(icone: Symbols.key_rounded, luz: c.sucesso)
            : PocoIcone(
                icone: Symbols.key_off_rounded,
                luz: c.luz(Matiz.brasa),
              ),
        texto: ultima.acertou
            ? comDestaque(
                context,
                '$quem desvendou $anel: ',
                ultima.palpite ?? '',
                '. Duas cartas a menos!',
              )
            : comDestaque(
                context,
                '$quem errou a regra de ',
                anel,
                ' e comprou uma carta.',
              ),
      );
    } else if (pendente != null) {
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

/// Regras à vista: todas para o Guardião, as desvendadas para os outros.
/// Uma linha por anel, na luz dele.
class _Regras extends StatelessWidget {
  const _Regras({required this.regras, required this.titulo});

  final List<AneisRegraRevelada> regras;
  final String titulo;

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
              Text(titulo, style: texto.labelSmall?.copyWith(color: c.texto3)),
            ],
          ),
          const SizedBox(height: Espaco.e1),
          for (final regra in regras)
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
    final comKnower = estado.comGuardiao;

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
                          ? 'GUARDIÃO'
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
    this.aoDesvendar,
  });

  /// Na sua vez: tentar desvendar a regra de um anel.
  final VoidCallback? aoDesvendar;
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
                    if (carregando)
                      BolinhasCarregando(cor: luz.cor)
                    else if (aoDesvendar != null)
                      _BotaoDesvendar(aoTocar: aoDesvendar!),
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

/// A pílula "Desvendar" no cabeçalho da mão.
class _BotaoDesvendar extends StatelessWidget {
  const _BotaoDesvendar({required this.aoTocar});

  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final luz = c.luz(Matiz.lampada);
    return Semantics(
      button: true,
      label: 'Desvendar uma regra',
      excludeSemantics: true,
      child: Pressionavel(
        onTap: aoTocar,
        escala: .95,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: Espaco.e3),
          decoration: BoxDecoration(
            color: luz.suave,
            borderRadius: BorderRadius.circular(Raio.pill),
            border: Border.all(
              color: c.ehDia ? c.contorno : luz.cor,
              width: c.ehDia ? 2 : 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.key_rounded, size: 18, color: luz.tinta),
              const SizedBox(width: Espaco.e1),
              Text(
                'DESVENDAR',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: luz.tinta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
