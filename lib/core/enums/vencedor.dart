enum Vencedor {
  civis,
  espioes,
  emAndamento;

  String get displayName {
    switch (this) {
      case Vencedor.civis:
        return 'Civis Venceram!';
      case Vencedor.espioes:
        return 'Espiões Venceram!';
      case Vencedor.emAndamento:
        return 'Em andamento';
    }
  }
}
