import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'relogio_ambiente.dart';

/// Uma rajada atravessando a tela da esquerda para a direita.
class _Rajada {
  _Rajada(this.inicio, this.velocidade, this.forca);

  /// Segundos no relógio do [Vento].
  final double inicio;

  /// Larguras de tela por segundo.
  final double velocidade;

  /// 0 a 1.
  final double forca;

  /// Quanto tempo a frente da rajada já passou por [x] (0 a 1 da largura).
  double desde(double agora, double x) => agora - inicio - x / velocidade;

  /// A última lâmpada ainda balança uns segundos depois da frente passar.
  bool viva(double agora) => agora - inicio < 1 / velocidade + 3.5;

  /// Enquanto passa e logo depois, o balanço é grande e pede 60 quadros por
  /// segundo; o resto, já pequeno, vai bem a 20.
  bool forte(double agora) => agora - inicio < 1 / velocidade + 2.5;
}

/// O vento da home: de tempos em tempos uma rajada atravessa a sala,
/// balança as lâmpadas do varal e empurra as estrelas.
///
/// Não há simulação: tudo sai de fórmulas do tempo e da posição, então fica
/// liso em qualquer taxa de quadros. Bate a cada quadro só enquanto há
/// rajada ou a intensidade está mudando; no resto, a 20 por segundo, para a
/// deriva lenta das estrelas.
///
/// [ligado] falso (tema Dia, movimento reduzido) leva a intensidade a zero
/// em ~1 s: as lâmpadas assentam suavemente e as estrelas param.
class Vento extends ChangeNotifier {
  Vento(TickerProvider vsync, {math.Random? sorte})
    : _sorte = sorte ?? math.Random() {
    _relogio = RelogioAmbiente(vsync)..addListener(_tick);
  }

  static const _anguloMax = 8 * math.pi / 180;
  static const _empurraoMax = 4.0; // px nas estrelas mais próximas
  static const _deriva = 3.0; // px por segundo

  final math.Random _sorte;
  late final RelogioAmbiente _relogio;
  final _rajadas = <_Rajada>[];

  double _agora = 0;
  Duration _ultimoTick = Duration.zero;
  double _proxima = 2.5; // a primeira rajada vem logo depois da home abrir
  double _nivel = 0;
  double _alvo = 0;
  double _derivaAcumulada = 0;
  double _calmoAte = 0;

  /// Segundos desde que o vento começou.
  double get agora => _agora;

  /// Quantos px as estrelas já derivaram (multiplique pela profundidade).
  double get deriva => _derivaAcumulada;

  /// Segura o vento por [duracao]: nenhuma rajada começa e ele não pede
  /// quadros extras. Usado nas trocas de tela, para a transição ter a GPU
  /// só para ela.
  void calmarPor(Duration duracao) {
    _calmoAte = _agora + duracao.inMicroseconds / 1e6;
  }

  set ligado(bool v) {
    _alvo = v ? 1 : 0;
    if (v) _relogio.ligado = true;
  }

  void _tick() {
    final t = _relogio.value;
    final dt = (t - _ultimoTick).inMicroseconds / 1e6;
    _ultimoTick = t;
    _agora += dt;

    // A intensidade persegue o alvo com constante de tempo de 0,35 s.
    final nivelAntes = _nivel;
    _nivel += (_alvo - _nivel) * (1 - math.exp(-dt / .35));
    if ((_alvo - _nivel).abs() < .001) _nivel = _alvo;
    _derivaAcumulada += _deriva * _nivel * dt;

    final calmo = _agora < _calmoAte;
    // Se a rajada ia começar no meio de uma troca de tela, espera ela acabar.
    if (calmo && _proxima < _calmoAte) _proxima = _calmoAte + .3;
    if (_alvo > 0 && _agora >= _proxima) {
      _rajadas.add(
        _Rajada(
          _agora,
          .45 + .25 * _sorte.nextDouble(),
          .6 + .4 * _sorte.nextDouble(),
        ),
      );
      _proxima = _agora + 8 + 6 * _sorte.nextDouble();
    }
    _rajadas.removeWhere((r) => !r.viva(_agora));

    // Rajada passando ou intensidade mudando: bate a cada quadro. No resto,
    // o relógio volta sozinho para o passo lento.
    final emMovimento =
        _nivel != nivelAntes || _rajadas.any((r) => r.forte(_agora));
    if (emMovimento && !calmo) {
      _relogio.fluidoAte = _relogio.agora + const Duration(milliseconds: 200);
    }
    if (_nivel > 0 || emMovimento || _rajadas.isNotEmpty) notifyListeners();

    // Vento desligado e tudo assentado: o relógio para.
    if (_alvo == 0 && _nivel == 0) {
      _rajadas.clear();
      _relogio.ligado = false;
      notifyListeners();
    }
  }

  /// Sobe e desce sem quinas: 0 → 1 → 0 ao longo de [duracao].
  static double _sino(double tau, double duracao) => tau <= 0 || tau >= duracao
      ? 0
      : .5 - .5 * math.cos(2 * math.pi * tau / duracao);

  /// Ângulo, em radianos, da lâmpada [i] presa em [x] (0 a 1 da largura).
  /// Negativo é balançar para a direita, a favor do vento.
  double angulo(double x, int i) {
    if (_nivel == 0 || _rajadas.isEmpty) return 0;
    // Cada lâmpada tem um período um pouco diferente, para não balançarem
    // em uníssono.
    final periodo = 1.15 + .3 * ((i * 37 % 11) / 11);
    var soma = 0.0;
    for (final r in _rajadas) {
      final tau = r.desde(_agora, x);
      if (tau <= 0) continue;
      final entrada = 1 - math.exp(-tau / .18); // começa sem tranco
      soma +=
          r.forca *
          entrada *
          math.exp(-tau / 1.1) *
          math.sin(2 * math.pi * tau / periodo);
    }
    return -_anguloMax * _nivel * soma;
  }

  /// Empurrão para a direita, de 0 a [_empurraoMax] px, em [x].
  double empurrao(double x) {
    if (_nivel == 0 || _rajadas.isEmpty) return 0;
    var soma = 0.0;
    for (final r in _rajadas) {
      soma += r.forca * _sino(r.desde(_agora, x), 1.6);
    }
    return _empurraoMax * _nivel * soma;
  }

  @override
  void dispose() {
    _relogio.dispose();
    super.dispose();
  }
}
