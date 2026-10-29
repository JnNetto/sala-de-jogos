import '../../../core/enums/aneis_regiao.dart';
import '../../../core/theme/sala_tokens.dart';

/// As luzes dos três anéis, do sistema e não do servidor: Palavra no céu,
/// Atributo na lâmpada, Contexto no rosa. Fora dos anéis, sem luz.
extension CoresDosAneis on SalaCores {
  Luz get anelPalavra => luz(Matiz.ceu);
  Luz get anelAtributo => luz(Matiz.lampada);
  Luz get anelContexto => luz(Matiz.rosa);
  Luz get foraDosAneis => Luz(texto3, texto2, superficieFunda);

  /// A luz de um anel pelo id ("palavra", "atributo", "contexto").
  Luz luzDoAnel(String id) => luzDaRegiao(AneisRegiao.fromId(id));

  /// Uma região de um anel só tem a luz dele; a de vários, a mistura.
  Luz luzDaRegiao(AneisRegiao regiao) {
    final luzes = [
      if (regiao.noPalavra) anelPalavra,
      if (regiao.noAtributo) anelAtributo,
      if (regiao.noContexto) anelContexto,
    ];
    if (luzes.isEmpty) return foraDosAneis;
    if (luzes.length == 1) return luzes.first;
    if (luzes.length == 3) return luz(Matiz.violeta);
    return Luz.lerp(luzes.first, luzes.last, .5);
  }
}
