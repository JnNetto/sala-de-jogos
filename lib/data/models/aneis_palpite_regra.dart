/// Um "Desvendar uma regra" esperando o Guardião julgar.
class AneisPalpiteRegra {
  final String uid;
  final String nome;
  final String anel;
  final String palpite;

  const AneisPalpiteRegra({
    required this.uid,
    required this.nome,
    required this.anel,
    required this.palpite,
  });

  factory AneisPalpiteRegra.fromMap(Map<String, dynamic> data) {
    return AneisPalpiteRegra(
      uid: data['uid'] as String? ?? '',
      nome: data['nome'] as String? ?? 'Jogador',
      anel: data['anel'] as String? ?? '',
      palpite: data['palpite'] as String? ?? '',
    );
  }
}
