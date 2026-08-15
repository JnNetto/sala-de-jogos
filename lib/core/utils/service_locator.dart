import '../../data/repositories/palavra_repository.dart';
import '../../data/repositories/pergunta_repository.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/services/estatisticas_service.dart';
import '../../data/services/partida_service.dart';
import '../../data/services/pergunta_partida_service.dart';
import '../../data/services/quiz_partida_service.dart';
import '../../data/services/sorteio_service.dart';
import '../../data/services/storage_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final StorageService storageService;
  late final PalavraRepository palavraRepository;
  late final PerguntaRepository perguntaRepository;
  late final QuizRepository quizRepository;
  late final SorteioService sorteioService;
  late final PartidaService partidaService;
  late final PerguntaPartidaService perguntaPartidaService;
  late final QuizPartidaService quizPartidaService;
  late final EstatisticasService estatisticasService;

  Future<void> init() async {
    storageService = await StorageService.getInstance();
    palavraRepository = PalavraRepository();
    perguntaRepository = PerguntaRepository();
    await perguntaRepository.carregar();
    quizRepository = QuizRepository();
    await quizRepository.carregar();
    sorteioService = SorteioService(palavraRepository);
    partidaService = PartidaService(
      palavraRepository: palavraRepository,
      sorteioService: sorteioService,
      storageService: storageService,
    );
    perguntaPartidaService = PerguntaPartidaService(
      perguntaRepository: perguntaRepository,
      sorteioService: sorteioService,
      storageService: storageService,
    );
    quizPartidaService = QuizPartidaService(
      repository: quizRepository,
      storage: storageService,
    );
    estatisticasService = EstatisticasService(storageService);
  }
}
