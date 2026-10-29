# Dialogo

Diálogo de confirmação, montado sobre a `Janela`. Substitui o `AlertDialog` padrão com `FilledButton` sem tema.

- Véu `veu` com desfoque de 6 px sobre a tela.
- Janela de até 340 de largura, barra com título curto ("ATENÇÃO", "SAIR DA SALA").
- Título `headlineSmall` em forma de pergunta; corpo `bodyMedium` em `texto-2` dizendo a consequência.
- Ações empilhadas em largura total: a ação principal em cima (perigo ou primária), a de escape embaixo como fantasma. O verbo repete o título ("Abortar"), nunca "Sim".
- Abre com `Janela` (escala 0,9, `dur-media`, `curva-entrada`); o véu entra em fade de `dur-base`. Fecha em `dur-rapida`. Botão voltar do Android equivale à ação de escape.
- Háptico médio ao abrir um diálogo destrutivo.
