# Campo

Campo de texto: rótulo acima, caixa de 56 de altura e ajuda abaixo. Cobre o `InputDecorationTheme`.

- Rótulo `titleSmall`, sempre visível (não flutua para dentro da borda).
- Caixa: `superficie-funda` no Noite e `superficie` no Dia, raio `raio-md`, padding `espaco-4`, borda `linha-forte` de 1,5 px (Dia: `contorno` de 2 px). Texto `bodyLarge` em peso 700; placeholder em `texto-3`.
- Foco: borda `marca` de 2 px e halo `marca-suave` de 4 px, em `dur-base`.
- Erro: borda `carmim`, ajuda em `carmim-tinta` com ícone `error`. A mensagem diz o que fazer, não só o que deu errado.
- Ação dentro da caixa (colar, limpar) é um `BotaoIcone` nu.
- Teclado: `textCapitalization.words` para nomes; código da sala em `characters` e `TextInputAction.done` envia.
