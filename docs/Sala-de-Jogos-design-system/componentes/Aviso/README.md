# Aviso

O toast do app, em formato de janelinha: poço colorido com ícone, mensagem e uma ação opcional. Substitui o `SnackBar` vermelho com `Colors.red`.

- Flutua a `espaco-4` do rodapé (acima do botão principal), largura da tela menos a `margem-tela`, máx. 420.
- Fundo `superficie-elevada`, raio `raio-lg`, `sombra-flutuante`. Poço 44 em `<estado>-suave` com ícone preenchido em `<estado>-tinta`.
- Texto `bodyMedium` peso 700, até duas linhas. Ação é um botão fantasma na cor do estado ("Tentar"); sem ação, um `×`.
- Estados: `erro` (`wifi_off`, `error`), `sucesso` (`check_circle`), `info` (`info`), `aviso` (`warning`).
- Entra subindo 18 px com escala 0,96 em `dur-media` e `curva-entrada`; sai descendo em `dur-rapida`. Arrastar para baixo dispensa.
- Duração: 3 s sem ação, 6 s com ação, fica até ser dispensado se for erro de conexão. Háptico leve no erro.
