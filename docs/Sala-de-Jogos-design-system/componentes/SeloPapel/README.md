# SeloPapel

O selo que diz o papel do jogador e o bloco da palavra secreta. Substitui o pill de raio 30 e o bloco de raio 20.

- Selo: pílula de 40 de altura, fundo `<papel>-suave`, borda 2 px na cor do papel, texto `labelMedium` em pixel e CAIXA ALTA em `<papel>-tinta`, ícone preenchido 20. Espião usa `papel-espiao`, civil usa `papel-civil`.
- Palavra: bloco `raio-lg`, fundo `<papel>-suave`, borda 3 px e brilho de 32 px; texto `revelacao` (Nunito Black, CAIXA ALTA) em `texto`. Não use pixel aqui: a palavra precisa ser lida sem erro. Palavras longas reduzem até 32 px (`FittedBox`) e nunca quebram no meio.
- O espião nunca vê bloco de palavra: no lugar vem a dica "Descubra o lugar sem se entregar" em `bodyLarge`.
- Papel sempre com palavra e ícone, nunca só cor.
