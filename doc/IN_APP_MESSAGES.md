# In-App Messages — Guia de Integração (Flutter SDK 4.0.0+)

A partir da versão **4.0.0** do `inngage_plugin`, as In-App Messages são
**sob demanda (pull-based)**: o app decide **onde e quando** uma mensagem pode
aparecer, e o SDK consulta a plataforma Inngage naquele momento. Se houver uma
campanha ativa para o usuário, ela é renderizada; se não houver, **nada
acontece** — sem erro e sem tela vazia.

As mensagens não dependem mais do payload de push (FCM). O push continua
funcionando normalmente, em paralelo.

---

## 1. Pré-requisito: a subscription

O fluxo de In-App depende de dois dados que o SDK persiste automaticamente ao
concluir a **subscription**: o `app_id` (retornado pela API) e o token de
registro do dispositivo.

Portanto, **o `InngageSDK.subscribe(...)` + registro do subscriber precisam
ter sido executados ao menos uma vez** antes da primeira chamada de In-App —
o fluxo normal de inicialização do SDK já faz isso:

```dart
await InngageSDK.subscribe(
  appToken: 'SEU_APP_TOKEN',
  friendlyIdentifier: 'usuario@exemplo.com',
  navigatorKey: navigatorKey,
);
// registro do subscriber (envia o token e persiste o app_id):
await InngageNotificationMessage.registerSubscriber();
```

> Na **primeira execução** do app, chame a In-App somente após a subscription
> concluir (ex.: depois do login ou do splash). Nas execuções seguintes os
> dados já estão persistidos e a In-App funciona de imediato. Se os dados
> ainda não existirem, o SDK apenas registra um aviso no log e não faz nada.

---

## 2. Exibindo uma In-App

Chame `InngageInApp.show()` no ponto do app onde uma mensagem pode aparecer —
após o splash, na tela de login, na home, numa tela específica:

```dart
await InngageInApp.show(
  context: context, // opcional: usa o navigatorKey do subscribe se omitido
);
```

O que acontece internamente:

1. O SDK consulta a API (`POST /v4/message/objectMessage`) com os dados
   persistidos;
2. Se a resposta **não trouxer** mensagem (vazia, desabilitada ou falha de
   rede), **nada é renderizado** e a chamada retorna silenciosamente;
3. Se trouxer, o SDK identifica o **modelo** pelo campo `type` e renderiza o
   card correspondente — cada modelo está descrito na seção 4.

A API retorna **no máximo uma** mensagem por chamada. O controle de quais
campanhas são entregues (segmentação, frequência) é feito na plataforma
Inngage — o app só precisa chamar o método.

### Parâmetros e callbacks de `show()`

| Parâmetro | Tipo | Default | Descrição |
|---|---|---|---|
| `context` | `BuildContext?` | `navigatorKey` do subscribe | Contexto para exibir o dialog. |
| `handledBySdk` | `bool` | `true` | Quem executa as ações de clique (ver seção 3). |
| `onAction` | `void Function(InAppV2Action)` | — | Recebe a ação quando `handledBySdk: false` (ou quando deep links estão bloqueados). |
| `onMetadata` | `void Function(Map<String, String>)` | — | Recebe os pares chave-valor de ações do tipo `metadata`. |
| `onLeadCaptured` | `void Function(Map<String, String>)` | — | Recebe os campos preenchidos no formulário de captura (Roleta/Raspadinha). |
| `onWheelResult` | `void Function(InAppV2WheelSlice)` | — | Recebe a fatia sorteada na Roleta (`label`, `code`, `isWin`). |
| `onScratchResult` | `void Function(InAppV2ScratchPrize)` | — | Recebe o prêmio revelado na Raspadinha (`label`, `code`, `isWin`). |

> O SDK **não envia** lead, resultado de giro ou prêmio para a API — esses
> dados são entregues apenas ao app, pelos callbacks acima.

---

## 3. Ações de clique

Botões e cliques de fundo carregam uma **ação**, configurada na campanha:

| Tipo (`action.type`) | Comportamento com `handledBySdk: true` |
|---|---|
| `deeplink` / `deep_link` | Abre a URL como deep link no dispositivo. |
| `weblink` | Abre a URL no **navegador externo**. |
| `in_app_url` / `inapp` | Abre a URL no **navegador in-app** (Custom Tab / Safari View). |
| `metadata` | Não navega; entrega o mapa de metadados ao `onMetadata`. |
| `dismiss` (ou desconhecido) | Apenas fecha a mensagem. |

Com `handledBySdk: false`, **nenhuma** navegação é feita pelo SDK: toda ação
é entregue ao `onAction` e o app decide o que fazer:

```dart
await InngageInApp.show(
  context: context,
  handledBySdk: false,
  onAction: (action) {
    // action.type, action.url, action.metadata
  },
);
```

Em todos os casos, o clique **fecha a mensagem** antes de a ação executar.
Tocar fora do card também fecha, sem executar ação.

---

## 4. Modelos de In-App

O modelo é definido pelo campo `type` da campanha. Todos compartilham o
**estilo do card** (`style`): posição na tela (`center`/`top`/`bottom`), cor
de fundo, imagem de fundo, cor de borda, sombra e cores de título/corpo.

### 4.1 Banner e Carrossel (`type: "Banner"` / `"Message"`)

Mensagem visual composta por **slides**. A quantidade de slides define o
formato:

- **1 slide** → banner;
- **2 ou mais** → carrossel deslizável com indicador de pontos. A **altura se
  adapta ao conteúdo de cada slide**, com transição animada entre slides.

Cada slide pode ter:

| Recurso | Descrição |
|---|---|
| Imagem | Exibida acima ou abaixo do texto (`media.position`), com recorte central. |
| Título e corpo | Textos com as cores do `style`. |
| Botões (até 2 lado a lado) | Texto, cores próprias e uma ação (seção 3). |
| Clique de fundo (`backgroundClick`) | Ação disparada ao tocar em qualquer área do slide fora dos botões. |

### 4.2 Roleta (`type: "Wheel"`)

Roleta da sorte com prêmios por **sorteio ponderado**:

- Cada fatia tem rótulo, cor, **peso** (probabilidade) e um **cupom** —
  fatia sem cupom é "não ganhou";
- O sorteio acontece **no SDK, antes da animação**: a roleta gira e para
  exatamente na fatia sorteada;
- **Um giro por exibição**;
- Após o giro, o painel de resultado mostra título/emoji de vitória ou
  derrota, o texto configurado e, quando há prêmio, o **cupom com botão de
  copiar** para a área de transferência;
- O resultado é entregue ao app via `onWheelResult` (a fatia, com `isWin` e
  `code`).

```dart
await InngageInApp.show(
  context: context,
  onWheelResult: (slice) {
    print('Sorteado: ${slice.label} — ganhou? ${slice.isWin}');
  },
);
```

### 4.3 Raspadinha (`type: "Scratch"`)

Cartela de raspar com a **mesma mecânica de sorteio ponderado** da Roleta:

- O prêmio é sorteado **antes** de a cobertura aparecer — o que o usuário
  revela ao raspar já é o resultado;
- A cobertura tem cor e texto de instrução configuráveis (ex.: "Raspe aqui ✨"),
  que some ao primeiro toque;
- Ao raspar o percentual configurado na campanha (`revealPercent`), a
  revelação completa sozinha e o painel de resultado aparece — com suporte a
  fundo **sólido ou gradiente** e cupom com botão de copiar;
- O prêmio é entregue ao app via `onScratchResult`.

### 4.4 Contagem Regressiva (`type: "Countdown"`)

Card de urgência com prazo:

- Quatro caixas — **DIAS / HORAS / MIN / SEG** — com cores configuráveis,
  atualizadas a cada segundo até o `endDate` da campanha (interpretado no
  horário local do dispositivo);
- Botões de ação abaixo da contagem, com o mesmo comportamento da seção 3;
- **Campanha já vencida não é exibida**; se o prazo terminar com o card
  aberto, a contagem e os botões dão lugar ao título/texto de encerramento
  configurados na campanha.

### Recursos comuns aos modelos Roleta, Raspadinha e Contagem

- **Rodapé "Powered by Inngage"** — exibido por padrão; a campanha pode
  ocultá-lo (`hideBrand`);
- **Botão de fechar (X)** no canto superior do card;
- **Captura de lead** (formulário de e-mail antes ou depois do
  giro/raspagem): o fluxo está implementado no SDK, porém **desativado por
  padrão** nesta versão. Quando habilitado, os campos preenchidos são
  entregues ao app via `onLeadCaptured` — nada é enviado à API.

---

## 5. Métricas automáticas

O SDK contabiliza sozinho, sem nenhum código adicional:

- **Impressão** — registrada uma vez a cada exibição, para todos os modelos;
- **Clique** — registrado em cliques do Banner/Carrossel e da Contagem, com a
  origem: `card` (fundo do slide), `button` (botão único), `button_up` /
  `button_down` (primeiro/segundo botão). Botões de fechar/dismiss também
  contam clique.

As chamadas são *fire-and-forget*: falhas de rede não afetam a experiência
do usuário nem geram exceções.

---

## 6. Exemplo completo

```dart
// Em qualquer tela onde uma In-App possa aparecer (ex.: home):
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    InngageInApp.show(
      context: context,
      onMetadata: (metadata) => debugPrint('metadata: $metadata'),
      onWheelResult: (slice) => debugPrint('roleta: ${slice.code}'),
      onScratchResult: (prize) => debugPrint('raspadinha: ${prize.code}'),
    );
  });
}
```

## 7. Dicas e solução de problemas

- **"Nada aparece"** — na maioria das vezes é o comportamento esperado: não
  há campanha ativa para aquele usuário naquele momento. Ative os logs com
  `InngageSDK.setDebugMode(true)` para ver o request e a resposta da API.
- **Aviso "app_id/registration not available"** — a subscription ainda não
  concluiu nesta instalação. Garanta a ordem: `subscribe` →
  `registerSubscriber` → `InngageInApp.show`.
- **Chamadas repetidas** — pode chamar `show()` quantas vezes fizer sentido;
  a plataforma controla a frequência de entrega. Chamadas sem campanha ativa
  não renderizam nada.
