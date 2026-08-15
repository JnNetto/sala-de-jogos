class TimeFormatter {
  static String formatarSegundos(int segundos) {
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  static String formatarSegundosComTexto(int segundos) {
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;

    if (minutos == 0) {
      return '$segs segundo${segs != 1 ? 's' : ''}';
    }

    if (segs == 0) {
      return '$minutos minuto${minutos != 1 ? 's' : ''}';
    }

    return '$minutos minuto${minutos != 1 ? 's' : ''} e $segs segundo${segs != 1 ? 's' : ''}';
  }

  TimeFormatter._();
}
