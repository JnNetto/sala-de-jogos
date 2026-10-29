# Sala de Jogos: design system

Tudo o que define o visual novo do app, para usar no código ou consultar sem abrir o Claude.

## O que tem em cada pasta

| Pasta | Conteúdo |
|---|---|
| `docs/` | O guia em cinco partes: marca (cores, tipografia, forma, ícones, voz), movimento, padrões de tela, implementação no Flutter e a tabela de migração do sistema antigo. Comece pelo `01-guia-da-marca.md`. |
| `tokens/` | `tokens.json` com todas as cores dos temas Noite e Dia, tipografia, espaçamento, raios, sombras, durações e curvas. `tokens.css` é a mesma coisa em variáveis CSS. |
| `componentes/` | Uma pasta por componente com as regras de uso (`README.md`) e uma prévia viva (`preview.html`). Em `imagens/` estão as prévias em PNG, nos dois temas. |
| `fontes/` | Nunito e Pixelify Sans (variáveis, `.ttf`) e as licenças OFL. Essas são as fontes para empacotar no app. |
| `marca/` | Ícone do app, marca e wordmark em SVG, mais PNGs prontos (ícone em 1024 e 512 px, camada da frente do ícone adaptativo do Android). |

## Para começar no Flutter

1. Copie `fontes/*.ttf` para `assets/fonts/` e declare as famílias `Nunito` e `PixelifySans` no `pubspec.yaml`. Mantenha os arquivos de licença junto.
2. Siga `docs/04-flutter.md`: ele traz o `SalaCores`, a tipografia, o `ThemeData` completo, os widgets `Pressionavel`, `BotaoSala` e `Ceu` e as transições.
3. Use `docs/05-migracao.md` para trocar cada cor e componente antigo pelo novo.
4. Gere o ícone do app a partir de `marca/png/icone-app-1024.png` (por exemplo com `flutter_launcher_icons`). Para o ícone adaptativo do Android, use `icone-app-frente-1024.png` sobre o fundo `#0D0F2B`.

## Abrindo as prévias

Os arquivos `componentes/*/preview.html` abrem direto no navegador. As fontes vêm da pasta `fontes/`; os ícones Material Symbols carregam do Google Fonts, então precisam de internet. Algumas prévias são interativas: dá para alternar o tema, segurar para revelar a carta e arrastar o slider.
