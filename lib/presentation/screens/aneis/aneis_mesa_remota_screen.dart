import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/aneis_constants.dart';
import '../../../core/enums/aneis_regiao.dart';
import '../../../data/models/aneis_carta_publica.dart';
import '../../../data/models/aneis_estado_remoto.dart';
import '../../../data/models/aneis_jogador_remoto.dart';
import '../../../data/models/aneis_knower_view.dart';
import '../../../data/models/aneis_pending_jogada.dart';
import '../../../data/models/aneis_ultima_jogada.dart';
import '../../providers/aneis_sala_provider.dart';
import '../../widgets/aneis_abort_action.dart';
import '../../widgets/aneis_regiao_sheet.dart';
import '../../widgets/aneis_venn_board.dart';

class AneisMesaRemotaScreen extends StatefulWidget {
  const AneisMesaRemotaScreen({super.key});

  @override
  State<AneisMesaRemotaScreen> createState() => _AneisMesaRemotaScreenState();
}

class _AneisMesaRemotaScreenState extends State<AneisMesaRemotaScreen> {
  String? _cartaSelecionadaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarTutorialSePreciso();
    });
  }

  Future<void> _mostrarTutorialSePreciso() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AneisConstants.prefsKeyTutorialVisto) == true) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Os três anéis'),
        content: const Text(
          'Cada anel tem uma regra escondida.\n\n'
          'A carta entra em todos os anéis cuja regra ela cumpre — inclusive na interseção.\n\n'
          'Se uma pessoa for o Knower, ela vê as regras, coloca as pistas e decide onde cada palavra vai. Os outros tentam esvaziar a mão.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
    await prefs.setBool(AneisConstants.prefsKeyTutorialVisto, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AneisConstants.jogoNome),
          automaticallyImplyLeading: false,
          actions: const [AneisAbortAction()],
        ),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Consumer<AneisSalaProvider>(
            builder: (context, provider, _) {
              return StreamBuilder<AneisEstadoRemoto?>(
                stream: provider.observarEstadoAtual(),
                initialData: provider.estado,
                builder: (context, estadoSnapshot) {
                  final estado = estadoSnapshot.data;
                  if (estado == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<List<AneisJogadorRemoto>>(
                    stream: provider.observarJogadoresAtuais(),
                    initialData: provider.jogadores,
                    builder: (context, jogadoresSnapshot) {
                      final jogadores =
                          jogadoresSnapshot.data ?? provider.jogadores;

                      return StreamBuilder<List<AneisCartaPublica>>(
                        stream: provider.observarMaoAtual(),
                        initialData: provider.mao,
                        builder: (context, maoSnapshot) {
                          final mao = maoSnapshot.data ?? provider.mao;
                          final souKnower =
                              estado.knowerHumano &&
                              estado.knowerUid == provider.uid;

                          Widget montarMesa(AneisKnowerView? visao) {
                            return _Mesa(
                              provider: provider,
                              estado: estado,
                              jogadores: jogadores,
                              mao: mao,
                              visaoKnower: visao,
                              cartaSelecionadaId: _cartaSelecionadaId,
                              onSelecionarCarta: (id) {
                                setState(() {
                                  _cartaSelecionadaId =
                                      _cartaSelecionadaId == id ? null : id;
                                });
                              },
                              onPosicionar: (regiao) =>
                                  _posicionar(provider, estado, mao, regiao),
                              onDesfazer: souKnower && estado.podeDesfazer
                                  ? () => _desfazer(provider)
                                  : null,
                            );
                          }

                          if (!souKnower) {
                            return montarMesa(null);
                          }

                          return StreamBuilder<AneisKnowerView?>(
                            stream: provider.observarVisaoKnowerAtual(),
                            initialData: provider.visaoKnower,
                            builder: (context, visaoSnapshot) {
                              return montarMesa(
                                visaoSnapshot.data ?? provider.visaoKnower,
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _posicionar(
    AneisSalaProvider provider,
    AneisEstadoRemoto estado,
    List<AneisCartaPublica> mao,
    AneisRegiao regiao,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final souKnower =
        estado.knowerHumano && estado.knowerUid == provider.uid;

    if (souKnower && (estado.emJulgamento || estado.emSetup)) {
      String? texto;
      if (estado.emJulgamento) {
        texto = estado.pendingJogada?.texto;
      } else {
        final cartaId = _cartaSelecionadaId;
        for (final carta in mao) {
          if (carta.id == cartaId) {
            texto = carta.texto;
            break;
          }
        }
      }
      if (texto == null) return;
      final confirmou = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar posição'),
          content: Text('Colocar "$texto" em ${regiao.rotulo}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (!mounted || confirmou != true) return;
    }

    if (estado.emJulgamento && estado.knowerUid == provider.uid) {
      final ok = await provider.julgarPosicao(regiao: regiao.id);
      if (!mounted) return;
      if (!ok && provider.erro != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final cartaId = _cartaSelecionadaId;
    if (cartaId == null) return;
    if (!mao.any((carta) => carta.id == cartaId)) return;

    final ok = await provider.posicionarCarta(
      coisaId: cartaId,
      regiao: regiao.id,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _cartaSelecionadaId = null);
    } else if (provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _desfazer(AneisSalaProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.desfazerJulgamento();
    if (!mounted) return;
    if (!ok && provider.erro != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.erro!), backgroundColor: Colors.red),
      );
    }
  }
}

class _Mesa extends StatelessWidget {
  final AneisSalaProvider provider;
  final AneisEstadoRemoto estado;
  final List<AneisJogadorRemoto> jogadores;
  final List<AneisCartaPublica> mao;
  final AneisKnowerView? visaoKnower;
  final String? cartaSelecionadaId;
  final ValueChanged<String> onSelecionarCarta;
  final ValueChanged<AneisRegiao> onPosicionar;
  final VoidCallback? onDesfazer;

  const _Mesa({
    required this.provider,
    required this.estado,
    required this.jogadores,
    required this.mao,
    required this.visaoKnower,
    required this.cartaSelecionadaId,
    required this.onSelecionarCarta,
    required this.onPosicionar,
    required this.onDesfazer,
  });

  @override
  Widget build(BuildContext context) {
    final souKnower = provider.souKnower;
    final posicionando =
        !provider.isLoading &&
        ((provider.minhaVez && cartaSelecionadaId != null) ||
            (provider.emSetupKnower && cartaSelecionadaId != null) ||
            provider.emJulgamentoKnower);
    final maoHabilitada =
        !provider.isLoading && (provider.minhaVez || provider.emSetupKnower);
    AneisJogadorRemoto? daVez;
    for (final jogador in jogadores) {
      if (jogador.uid == estado.currentUid) {
        daVez = jogador;
        break;
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              _StatusTurno(
                mensagem: _mensagemStatus(daVez?.displayName ?? 'Alguém'),
                souEu: provider.minhaVez ||
                    provider.emSetupKnower ||
                    provider.emJulgamentoKnower,
                baralhoCount: estado.baralhoCount,
              ),
              if (onDesfazer != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: provider.isLoading ? null : onDesfazer,
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Desfazer última'),
                  ),
                ),
              ],
              if (souKnower && visaoKnower != null && visaoKnower!.regras.isNotEmpty) ...[
                const SizedBox(height: 8),
                _RegrasKnowerPanel(visao: visaoKnower!),
              ],
              if (estado.pendingJogada != null) ...[
                const SizedBox(height: 8),
                _PendingJogadaBanner(
                  jogada: estado.pendingJogada!,
                  souKnower: souKnower,
                  souEu: estado.pendingJogada!.uid == provider.uid,
                ),
              ],
              if (estado.ultimaJogada != null && estado.pendingJogada == null) ...[
                const SizedBox(height: 8),
                _UltimaJogadaBanner(
                  jogada: estado.ultimaJogada!,
                  souEu: estado.ultimaJogada!.uid == provider.uid,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: AneisVennBoard(
              cartas: estado.tabuleiro,
              posicionando: posicionando,
              destaque: estado.pendingJogada != null
                  ? AneisRegiao.fromId(estado.pendingJogada!.regiaoEscolhida)
                  : null,
              onSelecionarRegiao: posicionando ? onPosicionar : null,
              onVerRegiao: (regiao) => mostrarCartasDaRegiao(
                context: context,
                regiao: regiao,
                cartas: estado.tabuleiro,
                aneis: estado.aneis,
                regraSecreta: visaoKnower?.regras
                    .where((regra) => regra.anel == regiao.id)
                    .firstOrNull,
              ),
            ),
          ),
        ),
        _JogadoresBar(
          jogadores: jogadores,
          currentUid: estado.currentUid,
          knowerUid: estado.knowerUid,
          julgando: estado.emJulgamento,
          setup: estado.emSetup,
        ),
        if (!souKnower || estado.emSetup)
          _MaoBar(
            mao: mao,
            habilitada: maoHabilitada,
            selecionadaId: cartaSelecionadaId,
            onSelecionar: onSelecionarCarta,
            isLoading: provider.isLoading &&
                (provider.minhaVez ||
                    provider.emSetupKnower ||
                    provider.emJulgamentoKnower),
            vaziaRotulo: souKnower
                ? 'Escolha uma pista e toque na região'
                : 'Sem cartas',
          ),
      ],
    );
  }

  String _mensagemStatus(String nomeDaVez) {
    final knowerNome = estado.knowerNome ?? 'Knower';
    if (estado.emSetup) {
      return provider.emSetupKnower
          ? 'Coloque ${AneisConstants.pistasIniciais} pistas. Toque numa carta e na região.'
          : 'Aguardando $knowerNome colocar as pistas';
    }
    if (estado.emJulgamento) {
      return provider.emJulgamentoKnower
          ? 'Toque na região certa para esta carta'
          : 'Aguardando $knowerNome posicionar a carta';
    }
    if (provider.souKnower) {
      return 'Vez de $nomeDaVez — você decide onde a carta vai';
    }
    if (provider.minhaVez) {
      return 'Escolha uma carta e toque numa região';
    }
    return 'Vez de $nomeDaVez';
  }
}

class _StatusTurno extends StatefulWidget {
  final String mensagem;
  final bool souEu;
  final int baralhoCount;

  const _StatusTurno({
    required this.mensagem,
    required this.souEu,
    required this.baralhoCount,
  });

  @override
  State<_StatusTurno> createState() => _StatusTurnoState();
}

class _StatusTurnoState extends State<_StatusTurno>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.souEu) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _StatusTurno oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.souEu && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.souEu && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = widget.souEu ? _pulse.value : 0.0;
        final fundo = widget.souEu
            ? Color.lerp(
                scheme.primary,
                scheme.primary.withValues(alpha: 0.78),
                t,
              )
            : scheme.surfaceContainerHighest;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.souEu
                  ? scheme.onPrimary.withValues(alpha: 0.35)
                  : scheme.outline.withValues(alpha: 0.35),
              width: widget.souEu ? 2.2 : 1,
            ),
            boxShadow: widget.souEu
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.28 + t * 0.22),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Icon(
            widget.souEu ? Icons.campaign : Icons.hourglass_top,
            color: widget.souEu ? scheme.onPrimary : scheme.primary,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.souEu ? 'Sua vez! ${widget.mensagem}' : widget.mensagem,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: widget.souEu ? 18 : 16,
                color: widget.souEu ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
          Text(
            '${widget.baralhoCount} no baralho',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: widget.souEu
                  ? scheme.onPrimary.withValues(alpha: 0.85)
                  : scheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegrasKnowerPanel extends StatelessWidget {
  final AneisKnowerView visao;

  const _RegrasKnowerPanel({required this.visao});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AneisConstants.corPalavra.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Regras secretas',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          for (final regra in visao.regras)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 12, color: regra.cor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${regra.nome}: ${regra.texto}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

class _PendingJogadaBanner extends StatelessWidget {
  final AneisPendingJogada jogada;
  final bool souKnower;
  final bool souEu;

  const _PendingJogadaBanner({
    required this.jogada,
    required this.souKnower,
    required this.souEu,
  });

  @override
  Widget build(BuildContext context) {
    final palpite = AneisRegiao.fromId(jogada.regiaoEscolhida).rotulo;
    final quem = souEu ? 'Você' : jogada.nome;
    final mensagem = souKnower
        ? '$quem jogou "${jogada.texto}" em $palpite. Toque na região certa.'
        : '$quem jogou "${jogada.texto}" em $palpite. Aguardando o Knower.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AneisConstants.corAtributo.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AneisConstants.corAtributo.withValues(alpha: 0.55),
          width: 1.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Palpite da rodada',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Color(0xFFB45309),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mensagem,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }
}

class _UltimaJogadaBanner extends StatefulWidget {
  final AneisUltimaJogada jogada;
  final bool souEu;

  const _UltimaJogadaBanner({required this.jogada, required this.souEu});

  @override
  State<_UltimaJogadaBanner> createState() => _UltimaJogadaBannerState();
}

class _UltimaJogadaBannerState extends State<_UltimaJogadaBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _UltimaJogadaBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final antiga = oldWidget.jogada;
    final nova = widget.jogada;
    if (antiga.uid != nova.uid ||
        antiga.texto != nova.texto ||
        antiga.regiaoCerta != nova.regiaoCerta ||
        antiga.acertou != nova.acertou) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jogada = widget.jogada;
    final souEu = widget.souEu;
    final acertou = jogada.acertou;
    final texto = jogada.texto;
    final nome = jogada.nome;
    final palpite = jogada.regiaoEscolhida;
    final certa = jogada.regiaoCerta;
    final cor = acertou ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final quem = souEu ? 'Você' : nome;
    final mensagem = acertou
        ? '$quem acertou: "$texto" em ${certa.rotulo}'
        : '$quem jogou "$texto" em ${palpite.rotulo}; foi para ${certa.rotulo}';

    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final brilho = (1 - _controller.value) * 0.28;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(
                cor.withValues(alpha: 0.12 + brilho),
                cor.withValues(alpha: 0.12),
                _controller.value,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cor.withValues(alpha: 0.4)),
            ),
            child: child,
          );
        },
        child: Text(
          acertou && souEu ? '$mensagem. Jogue outra!' : mensagem,
          style: TextStyle(fontWeight: FontWeight.w700, color: cor),
        ),
      ),
    );
  }
}

class _JogadoresBar extends StatelessWidget {
  final List<AneisJogadorRemoto> jogadores;
  final String currentUid;
  final String? knowerUid;
  final bool julgando;
  final bool setup;

  const _JogadoresBar({
    required this.jogadores,
    required this.currentUid,
    required this.knowerUid,
    required this.julgando,
    required this.setup,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: jogadores.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final jogador = jogadores[index];
          final ehKnower = jogador.uid == knowerUid;
          final daVez = ehKnower
              ? (julgando || setup)
              : (!julgando && !setup && jogador.uid == currentUid);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: daVez
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: daVez
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: daVez ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  jogador.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(ehKnower ? 'Knower' : '${jogador.maoCount} cartas'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MaoBar extends StatelessWidget {
  final List<AneisCartaPublica> mao;
  final bool habilitada;
  final String? selecionadaId;
  final ValueChanged<String> onSelecionar;
  final bool isLoading;
  final String vaziaRotulo;

  const _MaoBar({
    required this.mao,
    required this.habilitada,
    required this.selecionadaId,
    required this.onSelecionar,
    required this.isLoading,
    required this.vaziaRotulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Sua mão', style: Theme.of(context).textTheme.titleMedium),
              if (isLoading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: mao.isEmpty
                ? Center(child: Text(vaziaRotulo))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: mao.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final carta = mao[index];
                      final selecionada = carta.id == selecionadaId;
                      return InkWell(
                        onTap: habilitada
                            ? () => onSelecionar(carta.id)
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 108,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selecionada
                                ? AneisConstants.corPalavra.withValues(
                                    alpha: 0.16,
                                  )
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selecionada
                                  ? AneisConstants.corPalavra
                                  : Colors.grey.shade300,
                              width: selecionada ? 2.4 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              carta.texto,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: habilitada
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
