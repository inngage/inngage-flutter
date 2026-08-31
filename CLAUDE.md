# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`inngage_plugin` is a **Flutter plugin package** (published to pub.dev) that integrates apps with the [Inngage](https://www.inngage.com.br) marketing platform. It provides two channels: **push notifications** (via Firebase Cloud Messaging + local notifications) and **in-app messages** (dialogs/cards rendered from FCM payloads). It is a Dart-only plugin — there is no custom native Android/iOS code in `lib`; native behavior comes from the Firebase and `flutter_local_notifications` dependencies.

## Commands

```bash
flutter pub get                 # install deps (root and example/)
flutter analyze                 # lint — uses flutter_lints via analysis_options.yaml
dart format lib/                 # format

# Run the demo app (a full Flutter app that exercises the SDK):
cd example && flutter pub get && flutter run
```

**There are no automated tests** in this repo (no `test/` directory), despite `mockito`/`flutter_test` being declared as dev dependencies. Verification is done by running the `example/` app against a real Inngage app token. The example requires a `example/.env` file (loaded via `flutter_dotenv` in `example/lib/main.dart`) plus Firebase config files (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) — these are listed under `false_secrets` in `pubspec.yaml`.

## Architecture

The public API is re-exported through the barrel file **`lib/inngage_plugin.dart`** — consumers `import 'package:inngage_plugin/inngage_plugin.dart'`. The main entry point is the **`InngageSDK`** singleton (`lib/inngage_sdk.dart`); host apps call `InngageSDK.subscribe(...)` once at startup, then `InngageNotificationMessage.subscribe()` to wire up FCM.

Code is organized in layers under `lib/`:

- **`shared/inngage_properties.dart`** — the central global-state class. `InngageProperties` is an all-`static` class holding runtime config (appToken, identifier, phone/email, lat/long, customFields, navigatorKey, debugMode…). It also **constructs and wires the dependency graph**: a single `InngageNetwork`, an `InngageService`, and the three service impls. This is effectively the composition root. Almost everything reads/writes state here.
- **`domain/`** — `InngageService` orchestrates business operations (registerSubscriber / registerNotification / registerEvent), building request models from `InngageProperties`. `domain/services/` holds the interfaces (`SubscriptionService`, `NotificationService`, `EventService`); `domain/services/impl/` holds thin impls that delegate to the network.
- **`data/`** — `data/api/inngage_network.dart`: `InngageNetwork` implements all three service interfaces and is the only HTTP layer. It POSTs JSON to `https://api.inngage.com.br/v1/{subscription,notification,events/newEvent}/` (base host in `lib/core/constants.dart`). `data/model/` holds request/response models split into `inngage/` (API payloads) and `inapp/` (in-app message models).
- **`firebase/`** — FCM integration. `InngageNotificationMessage.subscribe()` registers foreground/background/opened/terminated handlers and the FCM token. `notification_handlers.dart` decides how each message is rendered (system notification vs. in-app), including downloading notification images. In-app payloads arrive in the FCM `additional_data` field.
- **`inapp/`** — renders in-app messages (dialogs, carousels, rich content, custom widgets). In-app content is persisted between delivery and display via `FlutterSecureStorage` under the key **`"inapp"`**.
- **`events/inngage_event.dart`** — `InngageEvent` static facade for sending analytics/conversion events and setting user attributes.
- **`geolocator/`**, **`dialogs/`**, **`util/`** — permissions/location, dialog helpers, and misc utilities (`hexcolor.dart`, `utils.dart`, native dialogs).

Request flow example: `InngageEvent.sendEvent()` → `InngageSDK.registerEvent()` → `InngageProperties.inngageService.registerEvent()` → builds `NewEventRequest`/`Event` → `EventServiceImpl` → `InngageNetwork.sendEvent()` → HTTP POST.

## Gotchas

- **The SDK version reported to the API is a manual constant** — `AppConstants.sdkVersion` in `lib/core/constants.dart`. It is **not** derived from `pubspec.yaml`'s `version:`, so bump both together when releasing.
- **`InngageNetwork._postRequest` never throws**: HTTP/client failures are logged (via `logger`) and reported as a `false` return value, so callers see delivery failures as `false`, not as exceptions.
- Logging below error level (including request/response payloads) is gated on `InngageProperties.debugMode` via a `LogFilter` in `shared/inngage_properties.dart` (set via `InngageSDK.setDebugMode` / `InngageEvent.setDebugMode`); errors are always logged. A few paths still use unconditional `debugPrint` for usage warnings.
- `InngageSDK` extends `ChangeNotifier` and exposes a deprecated `notificationController` **only for backward compatibility** — neither ever emits anything. Both are slated for removal in 4.0 (see `docs/V4_API_DESIGN.md`).
- The package deliberately uses wide dependency version ranges (`>=min <=max` rather than caret) to stay compatible across consumer apps — preserve this style in `pubspec.yaml` (see CHANGELOG 3.8.1).
