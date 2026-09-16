# Inngage Flutter SDK v4.0 — Desenho da Interface Pública

> Status: proposta aprovada para desenho — pendente de implementação.
> Referências de mercado: OneSignal 5.x, Braze, Customer.io, Amplitude, FlutterFire.

## Princípios

1. **Superfície mínima.** Um único import (`package:inngage_plugin/inngage.dart`) exporta
   apenas o que o app terceiro precisa. Todo o resto vive em `lib/src/` e não é exportado.
2. **Uma chamada de inicialização.** `Inngage.initialize(config)` substitui o par
   `InngageSDK.subscribe(...)` + `InngageNotificationMessage.subscribe()`.
3. **Config imutável, mutação explícita.** Estado que muda pós-init (identidade, custom
   fields) passa por métodos que também re-sincronizam o subscriber na API.
4. **Callbacks tipados e streams.** Nada de `Function?` nem casts dinâmicos.
5. **Offline-first.** Eventos entram numa fila persistida e são enviados em batch com
   retry/backoff. `trackEvent` nunca perde dado por falta de rede.
6. **A SDK nunca inicializa o Firebase.** O app é dono do `Firebase.initializeApp`
   (pré-requisito documentado), eliminando conflitos com `firebase_options`.
7. **Nunca lançar exceção para o app host.** Falhas são reportadas por retorno tipado
   e pelo stream de diagnóstico.

## Export público (`lib/inngage.dart`)

```dart
export 'src/public/inngage.dart'            show Inngage;
export 'src/public/config.dart'             show InngageConfig, AndroidPushConfig, InngageLogLevel;
export 'src/public/user.dart'               show InngageUser;
export 'src/public/events.dart'             show Conversion, TrackResult;
export 'src/public/push.dart'               show PushClick, PushReceived;
export 'src/public/inapp.dart'              show InAppMessage, InAppAction, InAppActionType;
export 'src/public/webview.dart'            show InngageWebViewProperties;
```

Tudo que hoje é exportado no barrel (`InngageProperties`, modelos de request, utils,
`hexcolor`, dialogs…) sai da superfície pública.

## 1. Fachada `Inngage`

Fachada estática fina; delega para um `InngageClient` interno (instância com dependências
injetáveis — é isso que torna a SDK testável). `@visibleForTesting Inngage.client` permite
substituir a instância em testes do próprio app host.

```dart
abstract final class Inngage {
  // ---- Ciclo de vida ------------------------------------------------------
  /// Idempotente. Registra o subscriber, faz o wiring de FCM (se
  /// [InngageConfig.autoRegisterPush]) e agenda o flush da fila de eventos.
  static Future<void> initialize(InngageConfig config);
  static bool get isInitialized;

  // ---- Identidade ---------------------------------------------------------
  /// Associa o dispositivo a um usuário conhecido. Qualquer campo informado
  /// atualiza o subscriber na API (merge, não replace).
  static Future<void> identify({
    String? identifier,      // "friendly identifier" (e-mail, CPF, id interno…)
    String? email,
    String? phone,
    Map<String, dynamic>? customFields,
  });

  /// Atualiza apenas custom fields (merge). Para remover um campo, envie null.
  static Future<void> setCustomFields(Map<String, dynamic> fields);

  /// Volta ao estado anônimo (novo uuid), preservando o push token.
  static Future<void> logout();

  /// Snapshot do usuário atual (identifier, uuid, pushToken, customFields).
  static InngageUser get user;

  // ---- Eventos ------------------------------------------------------------
  /// Enfileira o evento (persistido em disco) e retorna imediatamente.
  /// O envio real acontece em batch — ver [InngageConfig.eventFlushInterval].
  static Future<TrackResult> trackEvent(
    String name, {
    Map<String, dynamic> values = const {},
    Conversion? conversion,
  });

  /// Força o envio imediato da fila (ex.: antes de logout ou no fim do checkout).
  static Future<void> flushEvents();

  // ---- Push ---------------------------------------------------------------
  /// Clique em push (foreground, background e terminated — unificados).
  static Stream<PushClick> get onPushClick;

  /// Push recebido com o app em foreground, ANTES de a SDK exibi-lo.
  /// Retornar false no handler suprime a exibição.
  static void setForegroundPushHandler(bool Function(PushReceived) handler);

  static Future<bool> requestPushPermission();
  static Future<String?> getPushToken();

  /// true se a mensagem foi enviada pela Inngage — para apps com mais de um
  /// provedor de push decidirem a quem rotear.
  static bool isInngageMessage(Map<String, dynamic> messageData);

  /// Para o app registrar em `FirebaseMessaging.onBackgroundMessage` quando
  /// tiver o próprio handler top-level (caso contrário a SDK registra o dela).
  static Future<void> handleBackgroundMessage(Map<String, dynamic> messageData);

  // ---- In-app -------------------------------------------------------------
  /// Ações do usuário em mensagens in-app (clique em botão, dismiss, deep link).
  static Stream<InAppAction> get onInAppAction;

  /// Pausa/retoma exibição (ex.: durante onboarding ou checkout).
  static void pauseInAppMessages();
  static void resumeInAppMessages();

  /// Observer para `MaterialApp.navigatorObservers` — é como a SDK obtém
  /// contexto para exibir in-app sem exigir o GlobalKey do app.
  static NavigatorObserver get navigatorObserver;

  // ---- Diagnóstico --------------------------------------------------------
  static void setLogLevel(InngageLogLevel level);
}
```

## 2. `InngageConfig`

```dart
final class InngageConfig {
  const InngageConfig({
    required this.appToken,
    this.identifier,                       // identify() também pode ser usado depois
    this.attributionId,
    this.autoRegisterPush = true,          // wiring FCM completo no initialize
    this.requestPermissionOnInit = true,   // false => app chama requestPushPermission()
    this.requestAdvertiserId = false,
    this.requestGeolocation = false,
    this.blockDeepLinks = false,
    this.logLevel = InngageLogLevel.error, // nunca loga payload/PII abaixo de debug
    this.androidPush = const AndroidPushConfig(),
    this.webView = const InngageWebViewProperties(),
    this.eventFlushInterval = const Duration(seconds: 30),
    this.eventBatchSize = 10,
    this.navigatorKey,                     // OPCIONAL — fallback p/ quem não usa o observer
  });

  final String appToken;
  final String? identifier;
  final String? attributionId;
  final bool autoRegisterPush;
  final bool requestPermissionOnInit;
  final bool requestAdvertiserId;
  final bool requestGeolocation;
  final bool blockDeepLinks;
  final InngageLogLevel logLevel;
  final AndroidPushConfig androidPush;
  final InngageWebViewProperties webView;
  final Duration eventFlushInterval;
  final int eventBatchSize;
  final GlobalKey<NavigatorState>? navigatorKey;
}

final class AndroidPushConfig {
  const AndroidPushConfig({
    this.notificationIcon,        // nome do drawable
    this.accentColor,
    this.channelId = 'inngage',
    this.channelName = 'Notifications',
  });
  // ...
}

enum InngageLogLevel { none, error, warning, info, debug }
```

## 3. Tipos de dados públicos

```dart
final class InngageUser {
  final String uuid;                 // id anônimo do dispositivo
  final String? identifier;
  final String? email;
  final String? phone;
  final String? pushToken;
  final Map<String, dynamic> customFields;
}

final class Conversion {
  const Conversion({required this.value, this.notificationId});
  final double value;
  final String? notificationId;      // atribui a conversão a um push específico
}

enum TrackResult { queued, sent, invalid }

final class PushClick {
  final String? notificationId;
  final String? title;
  final String? body;
  final String? deepLink;
  final Map<String, dynamic> data;   // additional_data completo
}

final class PushReceived {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
}

final class InAppMessage {
  final String id;
  final Map<String, dynamic> payload;
}

enum InAppActionType { buttonClick, dismiss, deepLink }

final class InAppAction {
  final InAppMessage message;
  final InAppActionType type;
  final String? link;                // presente quando type == deepLink
}
```

## 4. Integração-alvo no app terceiro

```dart
// main.dart do app host — a integração completa:
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (Inngage.isInngageMessage(message.data)) {
    await Inngage.handleBackgroundMessage(message.data);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_bgHandler);

  await Inngage.initialize(InngageConfig(
    appToken: 'SEU_TOKEN',
    logLevel: kDebugMode ? InngageLogLevel.debug : InngageLogLevel.error,
  ));

  Inngage.onPushClick.listen((click) => router.go(click.deepLink ?? '/'));

  runApp(MaterialApp(
    navigatorObservers: [Inngage.navigatorObserver],
    home: const HomePage(),
  ));
}

// em qualquer lugar do app:
await Inngage.identify(identifier: 'user@x.com', phone: '+5511...');
await Inngage.trackEvent('purchase',
    values: {'sku': 'abc'}, conversion: const Conversion(value: 49.9));
```

## 5. Estrutura interna (`lib/src/`)

```
lib/
  inngage.dart                  # export público (acima)
  inngage_plugin.dart           # barrel LEGADO — mantido em v4 só com as fachadas
                                # antigas @Deprecated; removido na v5
  src/
    client/inngage_client.dart  # instância real; deps por construtor
    config/
    identity/identity_store.dart      # uuid/identifier persistidos
    network/
      api_client.dart                 # http, auth, timeout, erros tipados internos
      event_queue.dart                # fila em disco + batch + retry exponencial
    channels/
      push/                           # FCM wiring, local notifications, canais Android
      inapp/                          # fila com TTL (substitui a chave única "inapp"),
                                      # renderização, ações
    models/                           # payloads da API — internos
    support/logger.dart               # logging central, gated por logLevel
```

## 6. Compatibilidade e migração (v4)

As fachadas v3 permanecem funcionais em v4, marcadas `@Deprecated`, delegando para a
nova API:

| v3 (deprecated em 4.0)                         | v4                                             |
|------------------------------------------------|------------------------------------------------|
| `InngageSDK.subscribe(appToken:, navigatorKey:, ...)` | `Inngage.initialize(InngageConfig(...))` |
| `InngageNotificationMessage.subscribe()`       | automático no `initialize` (`autoRegisterPush`) |
| `InngageEvent.sendEvent(...)`                  | `Inngage.trackEvent(...)`                      |
| `InngageEvent.setUserPhone` / `setCustomFields`| `Inngage.identify` / `Inngage.setCustomFields` |
| `firebaseListenCallback` (Function?)           | `Inngage.onPushClick` (Stream tipado)          |
| `InngageInApp.show()`                          | automático; controle via pause/resume          |
| `InngageSDK.setDebugMode(bool)`                | `Inngage.setLogLevel(...)`                     |
| `InngageUtils.setKeyAuthorization`             | parâmetro interno do `InngageConfig` (se necessário) |

Remoção das fachadas legadas: v5.0.

## 7. Fora do desenho da API, mas parte do plano v4.x

- Testes unitários (`InngageClient` com `http.Client` mockado; fila de eventos; parsing
  de payload FCM) — a arquitetura injetável é o que destrava isso.
- CI (GitHub Actions): `flutter analyze` + `flutter test` + `pana` (score pub.dev).
- `sdk_version.g.dart` gerado a partir do `pubspec.yaml` (elimina o constante manual).
- Avaliar federação em packages (`inngage_core`/`inngage_push`/`inngage_inapp`) apenas
  se surgirem novos canais; a estrutura `src/channels/` já prepara isso.
