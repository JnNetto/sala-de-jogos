import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/sala_tokens.dart';
import 'ceu.dart';
import 'varal.dart';
import 'vento.dart';

/// Acompanha a pilha de rotas para o [PalcoDaSala] saber qual página está
/// por cima. Diálogos e folhas (rotas não opacas) não contam: o varal fica
/// atrás deles como estava.
class ObservadorDoPalco extends NavigatorObserver {
  final _pilha = <Route<dynamic>>[];
  final topo = ValueNotifier<Route<dynamic>?>(null);

  /// Um diálogo ou folha está aberto por cima da página.
  final coberto = ValueNotifier(false);

  void _atualizar() {
    Route<dynamic>? pagina;
    for (final r in _pilha.reversed) {
      if (r is ModalRoute && r.opaque) {
        pagina = r;
        break;
      }
    }
    topo.value = pagina;
    final ultima = _pilha.isEmpty ? null : _pilha.last;
    coberto.value = ultima is ModalRoute && !ultima.opaque;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.add(route);
    _atualizar();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.remove(route);
    _atualizar();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.remove(route);
    _atualizar();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _pilha.indexOf(oldRoute);
    if (newRoute != null) {
      i >= 0 ? _pilha[i] = newRoute : _pilha.add(newRoute);
    } else if (i >= 0) {
      _pilha.removeAt(i);
    }
    _atualizar();
  }
}

/// O varal como progresso: uma lâmpada por jogador, na cor dele, acesa
/// quando ele já fez a vez (viu o papel, por exemplo).
@immutable
class ProgressoDoVaral {
  const ProgressoDoVaral({required this.cores, required this.acesas});

  final List<Color> cores;
  final int acesas;

  @override
  bool operator ==(Object other) =>
      other is ProgressoDoVaral &&
      other.acesas == acesas &&
      listEquals(other.cores, cores);

  @override
  int get hashCode => Object.hash(acesas, Object.hashAll(cores));
}

/// O teto do app: um varal só, pendurado acima de todas as telas, e o vento
/// que balança ele e as estrelas de qualquer céu.
///
/// Como fica acima da navegação, o varal não se mexe quando as páginas
/// trocam: só o conteúdo transita. Cada tela pede o varal com [ComVaral];
/// numa tela que não pediu, ele sobe e some. Uma tela também pode pedir o
/// varal como [ProgressoDoVaral]: ele troca as lâmpadas coloridas pelas dos
/// jogadores, com um fade, e volta ao normal quando ela sai.
///
/// Vai no `builder` do `MaterialApp`, com [observador] em
/// `navigatorObservers`.
class PalcoDaSala extends StatefulWidget {
  const PalcoDaSala({super.key, required this.child});

  final Widget child;

  static final observador = ObservadorDoPalco();

  /// O vento do app, para um `Ceu` balançar as estrelas.
  static Vento? ventoDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_EscopoPalco>()?.vento;

  @override
  State<PalcoDaSala> createState() => _PalcoDaSalaState();
}

class _EscopoPalco extends InheritedWidget {
  const _EscopoPalco({
    required this.estado,
    required this.vento,
    required super.child,
  });

  final _PalcoDaSalaState estado;
  final Vento vento;

  @override
  bool updateShouldNotify(_EscopoPalco antigo) => antigo.vento != vento;
}

class _PalcoDaSalaState extends State<PalcoDaSala>
    with TickerProviderStateMixin {
  late final _vento = Vento(this);

  /// Pedidos de varal por rota: a rota pediu, e se como progresso.
  /// O pedido de cada rota e quem o fez: numa troca dentro da mesma rota
  /// (as fases de uma sala online), o [ComVaral] novo pede antes de o velho
  /// sair, e a saída do velho não pode apagar o pedido do novo.
  final _pedidos =
      <Route<dynamic>, ({ProgressoDoVaral? progresso, Object dono})>{};

  bool _visivel = false;
  ProgressoDoVaral? _progresso;

  /// O último progresso mostrado, para ele sair com fade sem sumir antes.
  ProgressoDoVaral? _ultimoProgresso;
  bool _recalculoAgendado = false;

  @override
  void initState() {
    super.initState();
    PalcoDaSala.observador.topo.addListener(_agendarRecalculo);
    PalcoDaSala.observador.topo.addListener(_acalmarVento);
    PalcoDaSala.observador.coberto.addListener(_agendarRecalculo);
  }

  /// Toda troca de página acalma o vento até a transição terminar.
  void _acalmarVento() => _vento.calmarPor(const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vento.ligado = !context.cores.ehDia && !Movimento.reduzido(context);
  }

  @override
  void dispose() {
    PalcoDaSala.observador.topo.removeListener(_agendarRecalculo);
    PalcoDaSala.observador.topo.removeListener(_acalmarVento);
    PalcoDaSala.observador.coberto.removeListener(_agendarRecalculo);
    _vento.dispose();
    super.dispose();
  }

  void _registrar(
    Route<dynamic> rota,
    ProgressoDoVaral? progresso,
    Object dono,
  ) {
    final antes = _pedidos[rota];
    _pedidos[rota] = (progresso: progresso, dono: dono);
    if (antes != null && antes.progresso == progresso) return;
    _agendarRecalculo();
  }

  void _remover(Route<dynamic> rota, Object dono) {
    if (_pedidos[rota]?.dono != dono) return;
    _pedidos.remove(rota);
    _agendarRecalculo();
  }

  /// A rota nova entra na pilha antes de a página dela construir (e pedir o
  /// varal). Esperar o fim do quadro evita o varal piscar nesse meio-tempo.
  void _agendarRecalculo() {
    if (_recalculoAgendado) return;
    _recalculoAgendado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculoAgendado = false;
      if (!mounted) return;
      final pedido = _pedidos[PalcoDaSala.observador.topo.value];
      // Atrás do véu de um diálogo o varal não aparece.
      final visivel = pedido != null && !PalcoDaSala.observador.coberto.value;
      final progresso = pedido?.progresso;
      if (visivel != _visivel || progresso != _progresso) {
        setState(() {
          _visivel = visivel;
          _progresso = progresso;
          if (progresso != null) _ultimoProgresso = progresso;
        });
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final dur = Movimento.d(context, Movimento.media);
    final emProgresso = _progresso != null;
    final ultimo = _ultimoProgresso;
    return _EscopoPalco(
      estado: this,
      vento: _vento,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          // O mesmo céu das telas, por baixo de todas: aparece quando uma
          // troca de tela deixa as duas transparentes ao mesmo tempo.
          const Positioned.fill(child: Ceu(child: SizedBox.expand())),
          widget.child,
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedSlide(
                offset: _visivel ? Offset.zero : const Offset(0, -.4),
                duration: dur,
                curve: _visivel ? Movimento.entrada : Movimento.saida,
                child: AnimatedOpacity(
                  opacity: _visivel ? 1 : 0,
                  duration: dur,
                  curve: Movimento.padrao,
                  child: Stack(
                    children: [
                      // O colorido fica sempre montado: ao voltar do
                      // progresso, ele não reacende a sequência da splash.
                      AnimatedOpacity(
                        opacity: emProgresso ? 0 : 1,
                        duration: dur,
                        curve: Movimento.padrao,
                        child: Varal.decorativo(
                          acenderEmSequencia: true,
                          vento: _vento,
                        ),
                      ),
                      if (ultimo != null)
                        AnimatedOpacity(
                          opacity: emProgresso ? 1 : 0,
                          duration: dur,
                          curve: Movimento.padrao,
                          onEnd: () {
                            if (!emProgresso && mounted) {
                              setState(() => _ultimoProgresso = null);
                            }
                          },
                          child: Varal.progresso(
                            cores: ultimo.cores,
                            acesas: ultimo.acesas,
                            vento: _vento,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pede o varal do [PalcoDaSala] enquanto a página desta tela estiver por
/// cima; com [progresso], no modo de progresso.
///
/// Também tira a tela de cena quando outra página a cobre. A transição de
/// cada rota só faz a de baixo sumir quando as duas são do mesmo tipo
/// (`canTransitionTo`); entre tipos diferentes (a rota do Material sob a
/// `rotaDaSala`, a lista de jogos sob o `OpenContainer`), a de baixo ficava
/// inteira, sobreposta à nova. Aqui a saída vale para qualquer rota: some em
/// 150 ms ao ser coberta e volta, com um respiro, quando fica por cima de
/// novo.
///
/// A tela deixa [Varal.altura] livre abaixo da SafeArea para ele.
class ComVaral extends StatefulWidget {
  const ComVaral({super.key, this.progresso, required this.child});

  final ProgressoDoVaral? progresso;
  final Widget child;

  @override
  State<ComVaral> createState() => _ComVaralState();
}

class _ComVaralState extends State<ComVaral>
    with SingleTickerProviderStateMixin {
  static const _sumir = Duration(milliseconds: 150);
  static const _voltar = Duration(milliseconds: 450);

  _PalcoDaSalaState? _palco;
  Route<dynamic>? _rota;
  late final _visivel = AnimationController(vsync: this, value: 1);

  @override
  void initState() {
    super.initState();
    PalcoDaSala.observador.topo.addListener(_aoMudarTopo);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _palco = context.getInheritedWidgetOfExactType<_EscopoPalco>()?.estado;
    _rota = ModalRoute.of(context);
    _pedir();
  }

  @override
  void didUpdateWidget(ComVaral antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.progresso != widget.progresso) _pedir();
  }

  void _pedir() {
    final rota = _rota;
    if (rota != null) _palco?._registrar(rota, widget.progresso, this);
  }

  void _aoMudarTopo() {
    final rota = _rota;
    final topo = PalcoDaSala.observador.topo.value;
    if (rota == null || topo == null) return;
    if (topo == rota) {
      if (_visivel.value < 1) {
        _visivel.animateTo(
          1,
          duration: _voltar,
          curve: const Interval(.35, 1, curve: Curves.easeOut),
        );
      }
    } else if (_visivel.value > 0) {
      _visivel.animateTo(0, duration: _sumir, curve: Curves.easeIn);
    }
  }

  @override
  void dispose() {
    PalcoDaSala.observador.topo.removeListener(_aoMudarTopo);
    _visivel.dispose();
    final rota = _rota;
    if (rota != null) _palco?._remover(rota, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _visivel, child: widget.child);
}
