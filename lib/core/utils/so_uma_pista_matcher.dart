import '../../data/models/so_uma_pista.dart';

class SoUmaMatchResultado {
  final bool anulada;
  final String? motivo;

  const SoUmaMatchResultado({required this.anulada, this.motivo});

  static const nenhuma = SoUmaMatchResultado(anulada: false);
}

/// Normaliza e compara pistas para decidir anulações automáticas.
///
/// Cobre com confiança apenas os casos inequívocos (idêntica, plural e
/// gênero regulares, e uma sugestão de mesma raiz por prefixo comum).
/// Homófonas, palavras inventadas, idioma estrangeiro e casos de raiz mais
/// distantes não são detectáveis por heurística e continuam exigindo decisão
/// manual do grupo — por isso toda anulação automática permanece togglável.
class SoUmaPistaMatcher {
  SoUmaPistaMatcher._();

  static const _comAcento = 'àáâãäåèéêëìíîïòóôõöùúûüçñ';
  static const _semAcento = 'aaaaaaeeeeiiiiooooouuuucn';

  static String normalizar(String texto) {
    var resultado = texto.trim().toLowerCase();
    for (var i = 0; i < _comAcento.length; i++) {
      resultado = resultado.replaceAll(_comAcento[i], _semAcento[i]);
    }
    resultado = resultado.replaceAll(RegExp(r'^[^a-z0-9]+|[^a-z0-9]+$'), '');
    resultado = resultado.replaceAll(RegExp(r'\s+'), ' ');
    return resultado;
  }

  static String _radicalPlural(String palavra) {
    if (palavra.endsWith('oes') ||
        palavra.endsWith('aes') ||
        palavra.endsWith('ais')) {
      return palavra;
    }
    if (palavra.endsWith('es') && palavra.length > 3) {
      return palavra.substring(0, palavra.length - 2);
    }
    if (palavra.endsWith('s') && palavra.length > 3) {
      return palavra.substring(0, palavra.length - 1);
    }
    return palavra;
  }

  static bool _mesmoPlural(String a, String b) {
    if (a == b) return false;
    return _radicalPlural(a) == _radicalPlural(b);
  }

  static bool _mesmoGenero(String a, String b) {
    bool termina(String s, String sufixo) => s.length > 3 && s.endsWith(sufixo);
    if (termina(a, 'o') && termina(b, 'a')) {
      return a.substring(0, a.length - 1) == b.substring(0, b.length - 1);
    }
    if (termina(a, 'a') && termina(b, 'o')) {
      return a.substring(0, a.length - 1) == b.substring(0, b.length - 1);
    }
    return false;
  }

  static bool _possivelMesmaRaiz(String a, String b) {
    if (a.length < 4 || b.length < 4 || a == b) return false;
    final menor = a.length < b.length ? a : b;
    final maior = a.length < b.length ? b : a;
    var comuns = 0;
    while (comuns < menor.length && menor[comuns] == maior[comuns]) {
      comuns++;
    }
    return comuns >= 3 && comuns / menor.length >= 0.7;
  }

  static SoUmaMatchResultado compararComAlvo(String pista, String alvo) {
    final p = normalizar(pista);
    final a = normalizar(alvo);
    if (p.isEmpty) return SoUmaMatchResultado.nenhuma;
    if (p == a) {
      return const SoUmaMatchResultado(anulada: true, motivo: 'palavra_alvo');
    }
    if (_mesmoPlural(p, a) || _mesmoGenero(p, a)) {
      return const SoUmaMatchResultado(anulada: true, motivo: 'palavra_alvo');
    }
    if (_possivelMesmaRaiz(p, a)) {
      return const SoUmaMatchResultado(
        anulada: true,
        motivo: 'palavra_alvo_raiz',
      );
    }
    return SoUmaMatchResultado.nenhuma;
  }

  static SoUmaMatchResultado compararPistas(String x, String y) {
    final nx = normalizar(x);
    final ny = normalizar(y);
    if (nx.isEmpty || ny.isEmpty) return SoUmaMatchResultado.nenhuma;
    if (nx == ny) {
      return const SoUmaMatchResultado(anulada: true, motivo: 'identica');
    }
    if (_mesmoPlural(nx, ny)) {
      return const SoUmaMatchResultado(anulada: true, motivo: 'plural');
    }
    if (_mesmoGenero(nx, ny)) {
      return const SoUmaMatchResultado(anulada: true, motivo: 'genero');
    }
    if (_possivelMesmaRaiz(nx, ny)) {
      return const SoUmaMatchResultado(anulada: true, motivo: 'raiz');
    }
    return SoUmaMatchResultado.nenhuma;
  }

  static bool palpiteCorreto(String palpite, String palavraAlvo) {
    return normalizar(palpite) == normalizar(palavraAlvo);
  }

  /// Aplica as anulações automáticas sobre a lista de pistas de uma rodada.
  static List<SoUmaPista> aplicar(List<SoUmaPista> pistas, String palavraAlvo) {
    final resultado = [for (final pista in pistas) pista];
    final atualizadas = List<SoUmaPista>.from(resultado);

    for (var i = 0; i < atualizadas.length; i++) {
      final contraAlvo = compararComAlvo(atualizadas[i].texto, palavraAlvo);
      if (contraAlvo.anulada) {
        atualizadas[i] = atualizadas[i].copyWith(
          anulada: true,
          motivoAutoAnulacao: contraAlvo.motivo,
        );
      }
    }

    for (var i = 0; i < atualizadas.length; i++) {
      for (var j = i + 1; j < atualizadas.length; j++) {
        final match = compararPistas(
          atualizadas[i].texto,
          atualizadas[j].texto,
        );
        if (match.anulada) {
          atualizadas[i] = atualizadas[i].copyWith(
            anulada: true,
            motivoAutoAnulacao:
                atualizadas[i].motivoAutoAnulacao ?? match.motivo,
          );
          atualizadas[j] = atualizadas[j].copyWith(
            anulada: true,
            motivoAutoAnulacao:
                atualizadas[j].motivoAutoAnulacao ?? match.motivo,
          );
        }
      }
    }

    return atualizadas;
  }
}
