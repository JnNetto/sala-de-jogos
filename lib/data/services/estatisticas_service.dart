import '../models/estatisticas.dart';
import 'storage_service.dart';

class EstatisticasService {
  final StorageService _storageService;

  EstatisticasService(this._storageService);

  Future<Estatisticas> getEstatisticas() async {
    return await _storageService.getEstatisticas();
  }

  Future<bool> limparEstatisticas() async {
    return await _storageService.saveEstatisticas(Estatisticas());
  }

  Future<bool> registrarPartida({
    required bool civisVenceram,
    required int duracaoSegundos,
  }) async {
    final stats = await _storageService.getEstatisticas();

    final novasStats = stats.registrarPartida(
      civisVenceram: civisVenceram,
      duracaoSegundos: duracaoSegundos,
    );

    return await _storageService.saveEstatisticas(novasStats);
  }
}
