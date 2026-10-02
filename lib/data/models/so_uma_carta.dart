class SoUmaCarta {
  final String id;
  final List<String> palavras;

  const SoUmaCarta({required this.id, required this.palavras});

  factory SoUmaCarta.fromJson(Map<String, dynamic> json) {
    final palavras = (json['palavras'] as List<dynamic>)
        .map((item) => item.toString())
        .toList(growable: false);
    return SoUmaCarta(id: json['id'].toString(), palavras: palavras);
  }
}
