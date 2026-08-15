import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/pergunta_impostora_constants.dart';
import '../../core/constants/quiz_da_vez_constants.dart';
import '../models/configuracao_partida.dart';
import '../models/configuracao_pergunta_impostora.dart';
import '../models/configuracao_quiz.dart';
import '../models/estatisticas.dart';

class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _instance!._prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  Future<ConfiguracaoPartida> getConfiguracao() async {
    final json = _prefs?.getString(AppConstants.prefsKeyConfiguracao);
    if (json == null) {
      return ConfiguracaoPartida();
    }
    try {
      return ConfiguracaoPartida.fromJson(jsonDecode(json));
    } catch (e) {
      return ConfiguracaoPartida();
    }
  }

  Future<bool> saveConfiguracao(ConfiguracaoPartida config) async {
    try {
      final json = jsonEncode(config.toJson());
      return await _prefs?.setString(AppConstants.prefsKeyConfiguracao, json) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<Estatisticas> getEstatisticas() async {
    final json = _prefs?.getString(AppConstants.prefsKeyEstatisticas);
    if (json == null) {
      return Estatisticas();
    }
    try {
      return Estatisticas.fromJson(jsonDecode(json));
    } catch (e) {
      return Estatisticas();
    }
  }

  Future<bool> saveEstatisticas(Estatisticas stats) async {
    try {
      final json = jsonEncode(stats.toJson());
      return await _prefs?.setString(AppConstants.prefsKeyEstatisticas, json) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getPalavrasUsadas() async {
    final list = _prefs?.getStringList(AppConstants.prefsKeyPalavrasUsadas);
    return list ?? [];
  }

  Future<bool> savePalavrasUsadas(List<String> palavrasIds) async {
    try {
      return await _prefs?.setStringList(
            AppConstants.prefsKeyPalavrasUsadas,
            palavrasIds,
          ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> adicionarPalavraUsada(String palavraId) async {
    final palavrasUsadas = await getPalavrasUsadas();
    if (!palavrasUsadas.contains(palavraId)) {
      palavrasUsadas.add(palavraId);
      return await savePalavrasUsadas(palavrasUsadas);
    }
    return true;
  }

  Future<bool> limparPalavrasUsadas() async {
    return await savePalavrasUsadas([]);
  }

  Future<bool> limparTodosDados() async {
    try {
      await _prefs?.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<ConfiguracaoPerguntaImpostora> getConfiguracaoPergunta() async {
    final json = _prefs?.getString(
      PerguntaImpostoraConstants.prefsKeyConfiguracao,
    );
    if (json == null) {
      return ConfiguracaoPerguntaImpostora();
    }
    try {
      return ConfiguracaoPerguntaImpostora.fromJson(jsonDecode(json));
    } catch (e) {
      return ConfiguracaoPerguntaImpostora();
    }
  }

  Future<bool> saveConfiguracaoPergunta(
    ConfiguracaoPerguntaImpostora config,
  ) async {
    try {
      final json = jsonEncode(config.toJson());
      return await _prefs?.setString(
            PerguntaImpostoraConstants.prefsKeyConfiguracao,
            json,
          ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<Estatisticas> getEstatisticasPergunta() async {
    final json = _prefs?.getString(
      PerguntaImpostoraConstants.prefsKeyEstatisticas,
    );
    if (json == null) {
      return Estatisticas();
    }
    try {
      return Estatisticas.fromJson(jsonDecode(json));
    } catch (e) {
      return Estatisticas();
    }
  }

  Future<bool> saveEstatisticasPergunta(Estatisticas stats) async {
    try {
      final json = jsonEncode(stats.toJson());
      return await _prefs?.setString(
            PerguntaImpostoraConstants.prefsKeyEstatisticas,
            json,
          ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getParesPerguntaUsados() async {
    return _prefs?.getStringList(
          PerguntaImpostoraConstants.prefsKeyParesUsados,
        ) ??
        [];
  }

  Future<bool> saveParesPerguntaUsados(List<String> ids) async {
    try {
      return await _prefs?.setStringList(
            PerguntaImpostoraConstants.prefsKeyParesUsados,
            ids,
          ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> adicionarParPerguntaUsado(String id) async {
    final usados = await getParesPerguntaUsados();
    if (!usados.contains(id)) {
      usados.add(id);
      return saveParesPerguntaUsados(usados);
    }
    return true;
  }

  Future<bool> limparParesPerguntaUsados() async {
    return saveParesPerguntaUsados([]);
  }

  Future<ConfiguracaoQuiz> getConfiguracaoQuiz() async {
    final json = _prefs?.getString(QuizDaVezConstants.prefsKeyConfiguracao);
    if (json == null) return ConfiguracaoQuiz();
    try {
      return ConfiguracaoQuiz.fromJson(jsonDecode(json));
    } catch (_) {
      return ConfiguracaoQuiz();
    }
  }

  Future<bool> saveConfiguracaoQuiz(ConfiguracaoQuiz config) async {
    try {
      return await _prefs?.setString(
            QuizDaVezConstants.prefsKeyConfiguracao,
            jsonEncode(config.toJson()),
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> getQuizPerguntasUsadas() async {
    return _prefs?.getStringList(QuizDaVezConstants.prefsKeyPerguntasUsadas) ??
        [];
  }

  Future<bool> saveQuizPerguntasUsadas(List<String> ids) async {
    try {
      return await _prefs?.setStringList(
            QuizDaVezConstants.prefsKeyPerguntasUsadas,
            ids,
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> adicionarQuizPerguntaUsada(String id) async {
    final usados = await getQuizPerguntasUsadas();
    if (!usados.contains(id)) {
      usados.add(id);
      return saveQuizPerguntasUsadas(usados);
    }
    return true;
  }

  Future<bool> limparQuizPerguntasUsadas() async {
    return saveQuizPerguntasUsadas([]);
  }
}
