import 'aneis_regra_revelada.dart';

class AneisKnowerView {
  final List<AneisRegraRevelada> regras;

  const AneisKnowerView({this.regras = const []});

  factory AneisKnowerView.fromMap(Map<String, dynamic> data) {
    return AneisKnowerView(
      regras: (data['regras'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AneisRegraRevelada.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }
}
