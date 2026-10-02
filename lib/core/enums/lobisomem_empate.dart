enum LobisomemEmpate {
  defesaRevoto,
  sorteio,
  todosSaem,
  ninguemMorre;

  String get nome {
    switch (this) {
      case LobisomemEmpate.defesaRevoto:
        return 'Defesa e revoto';
      case LobisomemEmpate.sorteio:
        return 'Sorteio';
      case LobisomemEmpate.todosSaem:
        return 'Todos os empatados saem';
      case LobisomemEmpate.ninguemMorre:
        return 'Ninguém morre';
    }
  }

  String get descricao {
    switch (this) {
      case LobisomemEmpate.defesaRevoto:
        return 'Os empatados se defendem e há nova votação só entre eles. Persistindo, ninguém morre.';
      case LobisomemEmpate.sorteio:
        return 'Um dos empatados é sorteado e sai.';
      case LobisomemEmpate.todosSaem:
        return 'Todos os empatados são eliminados.';
      case LobisomemEmpate.ninguemMorre:
        return 'Em caso de empate, ninguém é eliminado.';
    }
  }
}
