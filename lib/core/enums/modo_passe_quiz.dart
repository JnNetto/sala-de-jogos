enum ModoPasseQuiz {
  alvoLivre,
  proximoDaFila;

  String get displayName {
    switch (this) {
      case ModoPasseQuiz.alvoLivre:
        return 'Escolher alvo';
      case ModoPasseQuiz.proximoDaFila:
        return 'Próximo da fila';
    }
  }

  String get descricao {
    switch (this) {
      case ModoPasseQuiz.alvoLivre:
        return 'Você escolhe para quem passar';
      case ModoPasseQuiz.proximoDaFila:
        return 'O passe vai automaticamente para o próximo';
    }
  }
}
