import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Relógio das animações de ambiente (cintilar, varal, vento).
///
/// Parado de verdade quando não há pressa: fora de um movimento rápido
/// ([fluidoAte]), quem bate é um `Timer` de 50 ms, e o app só pede um quadro
/// quando algo muda. Um `Ticker` pediria quadro a cada vsync, o tempo todo,
/// e roubaria fôlego das transições. O `Ticker` só liga durante o movimento
/// rápido (uma rajada, o pulo de uma lâmpada).
///
/// Quem pinta com ele deve ficar atrás de um `RepaintBoundary`, para o
/// repinte não arrastar a tela inteira.
class RelogioAmbiente extends ValueNotifier<Duration> {
  RelogioAmbiente(TickerProvider vsync) : super(Duration.zero) {
    _ticker = vsync.createTicker(_aoQuadro);
  }

  static const _intervalo = Duration(milliseconds: 50);

  late final Ticker _ticker;
  Timer? _timer;

  /// O tempo é o que o próprio relógio bate (50 ms por batida lenta, a
  /// distância entre quadros na rápida), e não o do sistema: assim ele
  /// também anda certo num teste com tempo simulado.
  Duration _agora = Duration.zero;
  Duration? _ultimoQuadro;
  bool _ligado = false;
  Duration _fluidoAte = Duration.zero;

  /// O tempo real desde que ligou, mesmo entre batidas.
  Duration get agora => _agora;

  /// Até quando bater a cada quadro.
  Duration get fluidoAte => _fluidoAte;
  set fluidoAte(Duration ate) {
    _fluidoAte = ate;
    _ajustar();
  }

  set ligado(bool v) {
    if (_ligado == v) return;
    _ligado = v;
    _ajustar();
  }

  void _ajustar() {
    final rapido = _ligado && agora < _fluidoAte;
    if (rapido) {
      _timer?.cancel();
      _timer = null;
      if (!_ticker.isActive) {
        _ultimoQuadro = null;
        _ticker.start();
      }
      return;
    }
    if (_ticker.isActive) _ticker.stop();
    if (_ligado) {
      _timer ??= Timer.periodic(_intervalo, (_) {
        _agora += _intervalo;
        _bater();
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _aoQuadro(Duration decorrido) {
    final anterior = _ultimoQuadro;
    _ultimoQuadro = decorrido;
    if (anterior != null) _agora += decorrido - anterior;
    _bater();
  }

  void _bater() {
    value = agora;
    // Acabou o movimento rápido: volta para o passo de 50 ms.
    if (_ticker.isActive && agora >= _fluidoAte) _ajustar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ticker.dispose();
    super.dispose();
  }
}
