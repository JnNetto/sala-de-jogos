enum ResistenciaPapel {
  resistencia,
  espiao;

  bool get ehEspiao => this == ResistenciaPapel.espiao;

  String get nome {
    switch (this) {
      case ResistenciaPapel.resistencia:
        return 'Resistência';
      case ResistenciaPapel.espiao:
        return 'Espião';
    }
  }
}
