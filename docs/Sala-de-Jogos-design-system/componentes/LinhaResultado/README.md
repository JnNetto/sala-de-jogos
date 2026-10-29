# LinhaResultado

Uma linha de resultado no Quiz da Vez e nas revisões de rodada. Substitui `Colors.green`, `Colors.red` e `Colors.orange` soltos.

- Linha de 56, `superficie`, raio `raio-md`; texto `bodyLarge` peso 700.
- Estado à direita: etiqueta em pixel com ícone e palavra. Acertou: `sucesso` (`check`). Errou: `erro` (`close`). Passou: `aviso` (`skip_next`). Nunca só a cor.
- Acerto: anel `menta` que se expande 14 px e some em 520 ms, mais 10 faíscas pixel. Háptico leve.
- Erro: tremida horizontal (−8, 8, −5, 4, 0) em 360 ms. Háptico médio.
- Passou: a linha desliza 24 px para a esquerda e volta, em `dur-base`.
- Na lista de fim de rodada, as linhas entram em cascata de 60 ms e o placar soma com contagem de números.
