enum ResistenciaVencedor {
  resistencia,
  espioes;

  String get nome {
    switch (this) {
      case ResistenciaVencedor.resistencia:
        return 'Exploradores';
      case ResistenciaVencedor.espioes:
        return 'Saqueadores';
    }
  }
}
