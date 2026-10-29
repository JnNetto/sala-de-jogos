import 'package:flutter_test/flutter_test.dart';
import 'package:impostor_app/data/services/sala_erro.dart';

void main() {
  test('código desconhecido da sala vira a mensagem genérica', () {
    expect(traduzirErroSala('not-found'), 'Sala não encontrada.');
    expect(traduzirErroSala('internal'), 'Erro ao acessar a sala.');
  });
}
