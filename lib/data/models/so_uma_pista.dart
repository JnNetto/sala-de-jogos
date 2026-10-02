class SoUmaPista {
  final String id;
  final String autorId;
  final String texto;
  final bool anulada;
  final String? motivoAutoAnulacao;

  const SoUmaPista({
    required this.id,
    required this.autorId,
    required this.texto,
    this.anulada = false,
    this.motivoAutoAnulacao,
  });

  SoUmaPista copyWith({bool? anulada, String? motivoAutoAnulacao}) {
    return SoUmaPista(
      id: id,
      autorId: autorId,
      texto: texto,
      anulada: anulada ?? this.anulada,
      motivoAutoAnulacao: motivoAutoAnulacao ?? this.motivoAutoAnulacao,
    );
  }
}
