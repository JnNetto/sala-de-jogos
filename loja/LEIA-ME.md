# Material da loja — Sala de Jogos

Tudo o que a Play Console pede para publicar, pronto para copiar.

## O que tem aqui

| Arquivo | Onde usar na Play Console |
|---|---|
| `textos/ficha-da-loja.md` | Presença na loja → Página principal: nome, descrições, categoria, contato. Também as notas da versão e a mensagem para os testadores. |
| `formularios/seguranca-dos-dados.md` | Conteúdo do app → Segurança dos dados |
| `formularios/classificacao-e-politicas.md` | Conteúdo do app → Classificação, Público-alvo, Anúncios, Acesso ao app e demais declarações |
| `imagens/icone-512.png` | Página principal → Ícone do app (512×512) |
| `imagens/destaque-1024x500.png` | Página principal → Recurso gráfico (1024×500) |
| `imagens/prints/*.png` | Página principal → Capturas de tela do smartphone (1080×1920, envie de 4 a 8, na ordem dos números) |

## Ordem sugerida na Play Console

1. **Criar o app:** nome "Sala de Jogos", idioma padrão Português (Brasil), tipo Jogo, gratuito.
2. **Conteúdo do app** (Política e programas): política de privacidade, acesso ao app, anúncios, classificação, público-alvo, segurança dos dados, exclusão de conta.
3. **Página principal da loja:** textos e imagens desta pasta.
4. **Teste fechado:** crie a faixa, adicione a lista de testadores (pelo menos 12), envie o `.aab` e mande a mensagem de `textos/ficha-da-loja.md`.
5. Depois do primeiro envio, pegue o **SHA-1 e o SHA-256 da chave de assinatura do app** (Configuração → Integridade do app) e cadastre no Firebase (app Android) e no App Check.
6. Após 14 dias de teste fechado com os testadores ativos, peça o **acesso à produção**.

## Links públicos

- Política de privacidade: https://sala-de-jogos-7298f.web.app/privacidade.html
- Exclusão de conta: https://sala-de-jogos-7298f.web.app/excluir-conta.html

## Gerar o pacote para envio

```powershell
flutter build appbundle --release --dart-define-from-file=.env.local --obfuscate --split-debug-info=build/simbolos
```

O arquivo sai em `build\app\outputs\bundle\release\app-release.aab`. Guarde a
pasta `build\simbolos` de cada versão enviada: ela traduz os erros
ofuscados, se precisar investigar um problema.

## Refazer as imagens

As imagens saem das telas reais do app. Se o visual mudar:

```powershell
$env:GERAR_LOJA=1; flutter test test/loja/gerar_imagens_test.dart
```

E o ícone, se a marca mudar:

```powershell
$env:GERAR_ICONE=1; flutter test test/loja/gerar_icone_test.dart
dart run flutter_launcher_icons
```
