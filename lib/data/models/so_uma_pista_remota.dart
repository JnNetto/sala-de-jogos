class SoUmaPistaRemota {
  final String clueId;
  final String autorUid;
  final String texto;
  final bool anulada;
  final String? motivoAutoAnulacao;

  const SoUmaPistaRemota({
    required this.clueId,
    required this.autorUid,
    required this.texto,
    required this.anulada,
    this.motivoAutoAnulacao,
  });

  factory SoUmaPistaRemota.fromMap(Map<String, dynamic> data) {
    return SoUmaPistaRemota(
      clueId: data['clueId'] as String? ?? '',
      autorUid: data['autorUid'] as String? ?? '',
      texto: data['texto'] as String? ?? '',
      anulada: data['anulada'] as bool? ?? false,
      motivoAutoAnulacao: data['motivoAutoAnulacao'] as String?,
    );
  }
}
