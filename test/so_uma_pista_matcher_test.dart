import 'package:flutter_test/flutter_test.dart';
import 'package:impostor_app/core/utils/so_uma_pista_matcher.dart';

void main() {
  test('pista idêntica, plural e gênero se anulam; casa e carro não', () {
    expect(SoUmaPistaMatcher.compararPistas('Gato', 'gato').motivo, 'identica');
    expect(SoUmaPistaMatcher.compararPistas('gatos', 'gato').motivo, 'plural');
    expect(SoUmaPistaMatcher.compararPistas('gato', 'gata').motivo, 'genero');
    expect(SoUmaPistaMatcher.compararPistas('casa', 'carro').anulada, isFalse);
  });

  test('palpite ignora acento', () {
    expect(SoUmaPistaMatcher.palpiteCorreto('Café', 'cafe'), isTrue);
  });
}
