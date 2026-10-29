# Sala de Jogos: guia da marca

A Sala de Jogos é uma sala à noite onde os amigos se juntam para jogar. Tudo no app parte dessa cena: o céu escuro com estrelas pixel, um varal de luzes coloridas, telas que brilham no escuro e janelas de sistema retrô. Cada jogo é uma luz acesa com cor própria; fora dos jogos, a luz da sala é âmbar.

O tema padrão é **Noite**. O tema **Dia** troca o céu por papel creme, os brilhos por contorno de tinta e sombra dura, como adesivo de desenho animado. Os dois usam os mesmos tokens; só os valores mudam.

## Três ideias que guiam tudo

1. **Luz acesa.** Cor é luz, não tinta. Cores vivas aparecem como preenchimento com brilho (`brilho-jogo`, halo das lâmpadas) sobre superfícies escuras. Nunca encha a tela de cor: a cor de destaque ocupa no máximo um bloco por tela, mais ícones e detalhes.
2. **Tela que brilha.** Cards são telas acesas na sala: superfície `superficie`, filete claro no topo, poço de ícone com linhas de CRT. Profundidade no Noite vem de luz, não de sombra preta.
3. **Janela de sistema.** Momentos de foco (diálogo, regras, revelação, resultado) entram numa `Janela` com barra de título em pixel. É a referência retrô usada com moderação: no máximo uma janela por tela.

## Voz e texto

- Português do Brasil, tratando por "você". Tom de anfitrião de festa: animado, curto, sem gritar.
- Frases de até 12 palavras na interface. Instrução principal no imperativo: "Passe o celular para Ana", "Segure para revelar", "Escolham o suspeito".
- Botões com verbo e até três palavras: "Jogar", "Revelar papel", "Próxima pergunta", "Continuar jogando". Nunca "OK" ou "Sim".
- Caixa de frase em tudo. CAIXA ALTA só no estilo `labelMedium`/`labelSmall` em pixel, para rótulos de até três palavras: "RODADA 2 DE 5", "SEU PAPEL", "NOVO".
- Erros dizem o que fazer: "Não deu para entrar na sala. Confira o código e tente de novo." Nunca culpe o jogador.
- Estado vazio convida: "Nenhuma partida ainda. A primeira rodada fica registrada aqui."
- Sem emoji na interface. Ícones, estrelas pixel e o varal fazem esse papel.
- Números de jogo (placar, tempo, rodada) sempre na fonte pixel.

## Cor

### Fundo e superfícies

- Pinte o fundo de toda tela com o componente `Ceu`: degradê de `ceu-topo` até `fundo`, brilho `ceu-brilho` no rodapé e estrelas `estrela`. Nunca use cor chapada de fundo.
- Cards, janelas e barras ficam em `superficie`. Estado pressionado, menus, toasts e a carta de revelação em `superficie-elevada`. Poços (campos, trilhos, contadores) em `superficie-funda`.
- Bordas finas em `linha` (decorativas) e bordas de controle em `linha-forte`. No Dia, tudo que é tocável ganha contorno de 2 px em `contorno` e sombra dura deslocada.

### Texto

- `texto` para conteúdo principal; `texto-2` para descrições e subtítulos; `texto-3` para metadados, placeholder e versão (a partir de 12 px em peso 700).
- Nunca use `Colors.grey[...]`, `Colors.white` ou `Colors.black` direto. Todo texto sai desses três tokens ou de um `-tinta`.
- Texto sobre qualquer preenchimento vivo (`primaria`, cores de jogo, `carmim`) é sempre `sobre-cor`, escuro. Branco falha em amarelo, menta e ciano.

### A luz da sala e a marca

- `primaria` (âmbar lâmpada) é a ação principal fora dos jogos: diálogos, configurações, onboarding. Lábio em `primaria-labio`, texto em `sobre-cor`.
- `marca` (violeta) é a assinatura de interface: anel de `foco`, seleção, links, chip ativo (`marca-suave` de fundo). Também é a cor de Quem é o Espião?.

### Cada jogo é uma luz

Dentro das telas de um jogo, a cor do jogo substitui `primaria` em botões, interruptores, sliders, anéis e varal. Use `<cor>` para preenchimento e brilho, `<cor>-tinta` para texto e ícone sobre superfícies, `<cor>-suave` para fundo tingido.

| Jogo | Token | Família | Ícone |
|---|---|---|---|
| Quem é o Espião? | `jogo-espiao` | violeta | `visibility_off` |
| Pergunta Impostora | `jogo-impostora` | rosa | `help` |
| Quiz da Vez | `jogo-quiz` | menta | `quiz` |
| A Resistência | `jogo-resistencia` | brasa | `shield` |
| Só uma! | `jogo-souma` | lampada | `lightbulb` |
| Lobisomem | `jogo-lobisomem` | luar | `bedtime` |
| Nos Anéis | `jogo-aneis` | ceu | `join_inner` |

Agora nenhum jogo repete cor (antes Pergunta Impostora e Só uma! dividiam o rosa, e Lobisomem era cinza).

### Estados, papéis e Nos Anéis

- `sucesso` (menta), `erro` (carmim), `aviso` (lâmpada, também "passou"), `info` (céu). Como texto, use o `-tinta` da família.
- Estado sempre vem com ícone e palavra. Sucesso e erro diferem em luminosidade, não só em matiz.
- Papéis: `papel-espiao` (carmim) e `papel-civil` (céu).
- Nos Anéis: `anel-palavra` (céu), `anel-atributo` (lâmpada), `anel-contexto` (rosa), `anel-nenhum` (`texto-3`). A paleta sai de `AneisConstants` e entra no tema.
- Atrás de diálogos e folhas, `veu` com desfoque de 6 px.

### Contraste

Todos os pares de texto declarados nos tokens passam WCAG AA nos dois temas: `texto` 12:1 ou mais, `texto-2` 6:1 ou mais, cada `-tinta` 4,5:1 ou mais sobre `fundo`, `superficie`, `superficie-elevada` e o próprio `-suave`, e `sobre-cor` 4,7:1 ou mais sobre qualquer preenchimento vivo. A exceção consciente é `texto-3`, com 4,36:1 no pior caso (`superficie-elevada` no Noite): por isso ele só aparece a partir de 12 px em peso 700. O anel de `foco` é sólido e tem 5:1 ou mais sobre as superfícies; `linha-forte` tem 3,6:1 ou mais para bordas de controle.

## Tipografia

Duas famílias, empacotadas no app como asset (sem buscar na rede, para funcionar offline):

- **Pixelify Sans** (`display`), a voz de videogame: nome do app, título de cada jogo, placar, cronômetro, rótulos em CAIXA ALTA.
- **Nunito** (`texto`), redonda e calorosa: todo o resto. Use pesos 600 (corpo), 800 (títulos de card) e 900 (títulos de tela e botões).

Regras:

- Pixel só em textos curtos (até três palavras) ou números, nunca em parágrafos, e nunca abaixo de 11 px.
- Nada que o jogador precise ler sem erro vai em pixel: a palavra secreta usa `revelacao` (Nunito Black em CAIXA ALTA), porque a fonte pixel confunde Z com 2 e S com 5. Códigos de sala também vão em Nunito.
- Corpo de texto em `bodyLarge` ou `bodyMedium`; nunca abaixo de `bodySmall` (12 px).
- Botões sempre em `labelLarge`.
- Números que mudam (cronômetro, contador) ficam em caixas de largura fixa por dígito: a fonte pixel não tem algarismos tabulares.
- Respeite a escala de texto do sistema até 1,3×; acima disso, títulos `display` param de crescer e o resto continua.

A escala completa, com o nome do `TextTheme` de cada estilo, está na aba de tipografia.

## Forma

- Raios: `raio-xs` em tags; `raio-sm` em chips e poços pequenos; `raio-md` em campos e botões compactos; `raio-lg` em botões e poços de jogo; `raio-xl` em cards e janelas; `raio-2xl` em folhas e na carta de revelação; `raio-pill` em selos, interruptores e lâmpadas.
- Bordas: `borda-fina` no Noite; `borda-controle` no Dia e em controles focados.
- Sombras: `sombra-card` em repouso, `sombra-flutuante` para o que flutua (diálogo, toast, carta). Botões usam o lábio (`labio-primaria` ou a cor do jogo escurecida). O halo `brilho-jogo` vai atrás do poço de ícone e do botão de jogo, na cor do jogo.

## Espaçamento e layout

- Grade de 4. Use os tokens `espaco-*`; nada de 10, 14 ou 18 soltos.
- Margem lateral de toda tela: `margem-tela` (20). Conteúdo limitado a 560 px e centralizado em tablets e na web.
- Área tocável mínima de `alvo-toque` (48 × 48), inclusive no × dos chips e no fechar da janela.
- Ritmo vertical de uma tela: título, `espaco-8`, conteúdo, `espaco-12`, ação principal colada à `SafeArea` inferior.
- Orientação só retrato.

## Iconografia

- **Material Symbols Rounded** (pacote `material_symbols_icons`), peso 500, grade 0. Contorno por padrão; preenchido (`FILL 1`) para estado ativo, papel revelado e ícones dentro de poço de toast.
- Tamanhos: 20 (em chips e tags), 24 (padrão), 28 (alternar tema), 32 (poço de card), 48 a 52 (home de jogo), 88 (papel revelado).
- A estrela pixel (cruz 3 × 3 de quadrados) é o único ícone desenhado à mão: usada no céu, nas faíscas de acerto e como marcador.
- Ícone do app, marca e wordmark estão em Assets › Marca. O wordmark é a Pixelify Sans Bold convertida em curvas.

## Movimento, em resumo

O app nunca fica parado e nunca faz o jogador esperar. Detalhes na seção Movimento.

- Toque: tudo que é tocável afunda (`dur-instante`) e volta com um pulinho (`curva-pulo`, `dur-rapida`), com háptico leve.
- Navegar: card de jogo abre em container transform (`dur-lenta`); passos de um fluxo usam eixo compartilhado horizontal (`dur-media`); diálogos abrem como janela.
- Momentos de jogo ganham coreografia: revelação com virada de carta, contagem 3-2-1, faíscas no acerto, tremida no erro, varal acendendo.
- Ambiente: estrelas e lâmpadas cintilam devagar (`dur-ambiente`).
- Movimento reduzido do sistema desliga cintilar, parallax, faíscas e viradas (viram fade de 120 ms).

## Hápticos

| Momento | Háptico |
|---|---|
| Toque em botão, card, chip | `lightImpact` |
| Interruptor, passo de slider, troca de tema | `selectionClick` |
| Virada da carta (civil), "JÁ!", erro | `mediumImpact` |
| Virada da carta (espião), fim do tempo | `heavyImpact` |
| Cronômetro crítico (cada segundo ≤5 s) | `lightImpact` |

Uma opção "Vibração" nas configurações desliga tudo.

## Acessibilidade

- Todo ícone sem texto tem rótulo semântico com a ação ("Abortar partida").
- Revelação de papel anuncia o papel ao leitor de tela só depois da virada, e o botão "segurar" aceita toque duplo longo do TalkBack.
- Cor nunca é a única pista: papel, estado e resultado sempre têm palavra e ícone.
- Foco de teclado (web) e de leitor de tela usa o anel `foco`.
