class PerguntaImpostoraConstants {
  static const String jogoNome = 'Pergunta Impostora';
  static const String jogoDescricao =
      'Todos respondem a mesma pergunta... exceto um';

  static const int minJogadores = 3;
  static const int maxJogadores = 12;
  static const int minImpostores = 1;

  static const int duracaoExibicaoPerguntaSegundos = 6;

  static const int duracaoDiscussaoDefaultSegundos = 90;
  static const int duracaoDiscussaoMinSegundos = 30;
  static const int duracaoDiscussaoMaxSegundos = 600;

  static const String prefsKeyConfiguracao = 'pi_configuracao';
  static const String prefsKeyEstatisticas = 'pi_estatisticas';
  static const String prefsKeyParesUsados = 'pi_pares_usados';

  static const Map<String, String> nomesCategorias = {
    'animais': 'Animais',
    'comida': 'Comida',
    'viagem': 'Viagem',
    'relacionamentos': 'Relacionamentos',
    'dinheiro_trabalho': 'Dinheiro e Trabalho',
    'medos': 'Medos',
    'hipoteticos': 'Hipotéticos',
    'infancia': 'Infância',
    'habitos': 'Hábitos',
    'amigos': 'Amigos',
    'entretenimento': 'Entretenimento',
  };

  static String nomeCategoria(String id) => nomesCategorias[id] ?? id;

  PerguntaImpostoraConstants._();
}
