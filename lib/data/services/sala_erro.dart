String traduzirErroSala(String code) {
  switch (code) {
    case 'unauthenticated':
      return 'Não foi possível autenticar.';
    case 'not-found':
      return 'Sala não encontrada.';
    case 'failed-precondition':
      return 'A sala não está disponível.';
    case 'permission-denied':
      return 'Você não pode fazer isso nesta sala.';
    case 'invalid-argument':
      return 'Confira os dados e tente novamente.';
    case 'already-exists':
      return 'Essa ação já foi registrada.';
    case 'resource-exhausted':
      return 'Tente novamente em instantes.';
    default:
      return 'Erro ao acessar a sala.';
  }
}
