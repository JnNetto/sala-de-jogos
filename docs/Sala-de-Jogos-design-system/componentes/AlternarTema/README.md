# AlternarTema

O seletor de tema da home: uma pílula de 76 × 40 com um céu dentro. No Noite a lua fica à esquerda sobre estrelas; no Dia o sol desliza para a direita sobre papel.

- Fica no topo direito da home, alinhado à `margem-tela`. Substitui o ícone solto `wb_sunny`/`nightlight_round`.
- Toque: o polegar desliza 36 px em `dur-media` com `curva-pulo`; lua e sol giram 90° e trocam de opacidade; as estrelas somem em `dur-media`.
- A troca do tema inteiro acontece junto: `AnimatedTheme` com `dur-media` e `curva-padrao`. Háptico `selectionClick`.
- Grava a escolha (`ThemeProvider` + `SharedPreferences`) e a splash passa a respeitar essa escolha.
- Rótulo de acessibilidade diz a ação, não o estado: "Trocar para tema Dia".
