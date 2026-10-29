# Do sistema antigo para o novo

Tabela de troca para refatorar o código atual. À esquerda, o que existe hoje em `app_theme.dart` e nas telas; à direita, o que entra no lugar.

## Cores

| Hoje | Agora |
|---|---|
| `primaryColor` `#6C63FF` (ação, app bar, marca) | Ação: `primaria` (âmbar). Marca, foco e seleção: `marca` (violeta `#8F7CFF` / `#5B47F0`) |
| `darkPrimaryColor` `#8B84FF` | `marca` no Noite |
| `secondaryColor` `#3F3D56` (texto claro) | `texto` (`#1B1D5C` no Dia) |
| `#E0E0E0` (texto escuro) | `texto` (`#F1EEFF` no Noite) |
| `accentColor` `#FF6584` | `rosa` (Pergunta Impostora). Só uma! passa a ser `lampada` |
| `errorColor` / `espiaoColor` `#E74C3C` | `erro` e `papel-espiao` (`carmim`) |
| `successColor` `#2ECC71` | `sucesso` (`menta`) e Quiz da Vez |
| `warningColor` `#F39C12` | `aviso` (`lampada`); A Resistência passa a ser `brasa` |
| `civilColor` `#3498DB` | `papel-civil` (`ceu`) |
| Lobisomem em `#3F3D56` | `jogo-lobisomem` (`luar`) |
| Nos Anéis `#3B82F6` e `AneisConstants` | `jogo-aneis` e `anel-palavra`, `anel-atributo`, `anel-contexto`, `anel-nenhum` |
| Fundo `#F7F7F7` / `#121212` | Componente `Ceu` sobre `fundo` |
| Superfície branco / `#1E1E1E` | `superficie` |
| Borda `#E0E0E0` / `#424242` | `linha-forte` (controles) e `linha` (divisores) |
| Polegar do switch `#BDBDBD` / `#757575` | `texto-3` |
| Fundo do ícone a 15% da cor | `<cor>-suave` |
| Degradês próprios da splash | `ceu-topo` → `fundo` + `ceu-brilho` |

## O que estava solto e agora tem dono

| Convenção solta | Resolução |
|---|---|
| `Colors.grey[400]`, `[500]`, `[600]` | `texto-3`, `texto-3`, `texto-2` |
| `Colors.red`, `Colors.green`, `Colors.orange` em resultado | `LinhaResultado` com `erro`, `sucesso`, `aviso` |
| `SnackBar` com `Colors.red` | `Aviso` de erro (fundo `superficie-elevada`, poço `carmim-suave`) |
| `FilledButton` sem tema | `filledButtonTheme` no tema; nos diálogos, `Dialogo` usa `BotaoSala` perigo |
| Splash presa ao brilho do sistema | Splash lê o `ThemeProvider`; padrão é Noite |
| `bodySmall` sem definição | `bodySmall` Nunito 12/16 peso 700 |
| Opacidade 0,5 em jogo indisponível | `opac-desabilitado` (0,4) + tag "EM BREVE" |
| Espaçamentos 4 a 48 sem nome | `espaco-1` a `espaco-12`, mais `margem-tela` (20) |
| Raios 12, 16, 20, 30 | `raio-md` (14), `raio-lg` (18), `raio-xl` (24), `raio-pill` |

## Tipografia

| Hoje | Agora |
|---|---|
| Fonte do sistema | Nunito (texto) e Pixelify Sans (display e HUD), empacotadas |
| `displayLarge` 32 bold (título da home) | `displayLarge` Pixelify 40/44 |
| `displayMedium` 28 bold (nome na revelação) | `displayMedium` Pixelify 32/36 |
| Título da splash 36 bold | Wordmark (SVG) |
| Título da app bar 22 bold branco | `titleMedium` peso 900 em `texto`, sobretítulo em pixel |
| Botões 18 bold | `labelLarge` Nunito 16/20 peso 900 |
| Palavra revelada 48 bold | `revelacao` Nunito Black 40/46 em CAIXA ALTA (pixel confundiria letras) |
| Contagem 32 bold | Contagem Pixelify 96 dentro de anel |

## Componentes

| Hoje | Agora |
|---|---|
| `PrimaryButton` | `BotaoSala` (com lábio e `Pressionavel`) |
| `OutlinedButton.icon` "Estatísticas" | `Botao` secundário |
| `JogoCard` | `CartaoJogo` + `OpenContainer` |
| `ConfigCard` | `CartaoConfig` |
| Card de estatística | `CartaoEstatistica` |
| `AlertDialog` de abortar | `Dialogo` (sobre `Janela`) |
| `CircularProgressIndicator` | `Varal` em modo carregando; bolinhas dentro do botão |
| Ícone `sports_esports` 72 na home | Marca (janela com quatro vidros) |
| Ícones `wb_sunny` / `nightlight_round` | `AlternarTema` |
| `MaterialPageRoute` sem transição | Container transform, eixo compartilhado e fade-through |
| `Icons` do Material | Material Symbols Rounded |
