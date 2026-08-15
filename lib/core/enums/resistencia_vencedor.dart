enum ResistenciaVencedor {
  resistencia,
  espioes;

  String get nome {
    switch (this) {
      case ResistenciaVencedor.resistencia:
        return 'Resistência';
      case ResistenciaVencedor.espioes:
        return 'Espiões';
    }
  }
}
