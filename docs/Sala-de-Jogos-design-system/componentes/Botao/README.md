# Botao

O botão chunky com lábio: afunda 3 px ao toque e volta com um pulinho. É o `PrimaryButton` novo e cobre também `ElevatedButton`, `OutlinedButton`, `TextButton` e `FilledButton` pelo tema.

## Variantes

| Variante | Quando | Fundo · texto |
|---|---|---|
| Primário | A ação da tela fora de um jogo (diálogos, configurações, onboarding). No máximo um por tela. | `primaria` · `sobre-cor`, lábio `primaria-labio` |
| Jogo | A ação da tela dentro de um jogo: "Jogar", "Revelar papel", "Próxima". | cor do jogo · `sobre-cor`, lábio = cor do jogo escurecida 38% |
| Secundário | Ação de apoio ao lado ou abaixo da principal ("Estatísticas", "Regras"). | `superficie`, borda `linha-forte` · `texto` |
| Fantasma | Ação terciária, link, "Cancelar" em diálogo. | sem fundo · `primaria-tinta` ou `<cor>-tinta` |
| Perigo | Confirmação destrutiva ("Abortar", "Remover todos"). | `carmim` · `sobre-cor` |

## Medidas

Altura 56 (compacto 48), padding horizontal `espaco-6`, raio `raio-lg` (compacto `raio-md`), rótulo `labelLarge`, ícone 22 antes do texto com `espaco-2` de folga. Na home de jogo o botão ocupa a largura toda (`--bloco`).

## Estados

- **Repouso:** lábio de 4 px (`labio-primaria`) e reflexo branco a 28% no topo, como o vidro de uma lâmpada.
- **Pressionado:** desce 3 px, escala 0,985, lábio cai para 1 px. Entrada em `dur-instante` com `curva-padrao`; volta em `dur-rapida` com `curva-pulo`. Háptico leve no toque.
- **Carregando:** o rótulo dá lugar a três bolinhas que acendem em sequência (900 ms). Largura do botão fica fixa.
- **Desabilitado:** fundo `superficie-elevada` (Dia: `superficie-funda`), rótulo `texto-3`, filete `linha`, sem lábio, sem reflexo e sem háptico. Nada de cor de marca apagada: ela parece um botão com defeito.
- **Foco:** anel `foco` de 2 px a 3 px de distância.
- **Dia:** contorno de 2 px em `contorno` e lábio duro em `contorno` em todas as variantes, menos fantasma.

## Faça e não faça

- Faça: verbo no infinitivo ou imperativo curto, até três palavras ("Jogar", "Revelar papel").
- Não faça: texto branco em botão colorido. Use sempre `sobre-cor`.
- Não faça: dois botões preenchidos lado a lado. O segundo vira secundário ou fantasma.
