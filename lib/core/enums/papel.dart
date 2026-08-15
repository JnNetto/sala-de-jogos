enum Papel {
  civil,
  espiao;

  String get displayName {
    switch (this) {
      case Papel.civil:
        return 'Civil';
      case Papel.espiao:
        return 'Espião';
    }
  }
}
