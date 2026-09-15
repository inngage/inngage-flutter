## 4.0.0
#### BREAKING CHANGES — In-App Messages rewritten (pull-based, decoupled from push)
In-App messages no longer arrive inside FCM push payloads. The SDK now fetches
them on demand from `POST /v4/message/objectMessage` and renders the returned
message (banner for a single slide, carousel with dot indicator for two or
more). Push notifications themselves are unchanged and still use Firebase.

- **New public API:** `InngageInApp.show({context, handledBySdk, onAction, onMetadata})` — call it wherever the app wants an In-App message to appear (after the splash screen, on login, on a specific route…). When there is no message to display, nothing is rendered. With `handledBySdk: true` (default) the SDK executes the actions (`deeplink`/`deep_link`, `weblink` in the external browser, `in_app_url`/`inapp` in an in-app browser, unknown → dismiss); `metadata` actions are delivered to `onMetadata`. With `handledBySdk: false` every action is delivered to `onAction`.
- **Prerequisite:** the subscription must have completed at least once before the first `InngageInApp.show` call. The subscription response is now parsed and its `app_id` is persisted, together with the device registration token — both are required by `/objectMessage` (plus a persisted `firstAccess` flag, sent as `true` until the first successful fetch).
- **New public models:** `InAppMessageV2`, `InAppV2Style`, `InAppV2Media`, `InAppV2CarouselItem`, `InAppV2Content`, `InAppV2Actions`, `InAppV2Button`, `InAppV2ButtonStyle`, `InAppV2Action`, `InAppV2ActionType` and `ObjectMessageRequest` — mirroring the cross-SDK `/objectMessage` contract.
- **New "Wheel" (roleta) message type:** `type: "Wheel"` responses render a fortune-wheel flow — optional lead-capture form (`before` gates the spin; `after` locks a winning coupon until sign-up), weighted client-side draw (`drawWeighted`, shared with the future Scratch type), spin animation that lands on the drawn slice (via `flutter_fortune_wheel`), and a win/lose result panel (solid or gradient background) with a copy-to-clipboard coupon. One spin per display. New models: `InAppV2LeadCapture`, `InAppV2LeadField`, `InAppV2WheelConfig`, `InAppV2WheelSlice`, `InAppV2ResultConfig`, `InAppV2ResultStyle`. New `InngageInApp.show` callbacks: `onLeadCaptured` and `onWheelResult` (the SDK delivers both to the app and sends nothing to the API). A "Powered by Inngage" footer is shown unless `hideBrand` is `true`; the `targeting` field is ignored on mobile. The lead-capture step is implemented and tested but currently ships disabled (`InAppV2LeadPanel.renderLeadCapture`, default `false` — flip to honor `leadCapture.enabled` again), and the payload `icon` is parsed but intentionally not rendered.
- **New "Countdown" message type:** `type: "Countdown"` responses render a ticking deadline card — DIAS/HORAS/MIN/SEG boxes styled by `countdown.boxColor`/`digitColor`, refreshed every second toward `endDate` (interpreted in the device's local time), plus root-level action `buttons` that go through the same action pipeline as banner buttons (`target` is a web concept and is ignored). An already-expired campaign is not rendered; when the deadline is reached while the card is open, the boxes and buttons give way to `expiredTitle`/`expiredBody`. New model: `InAppV2CountdownConfig`.
- **New "Scratch" (raspadinha) message type:** `type: "Scratch"` responses render a scratch card (via `scratcher`) — the weighted draw happens BEFORE the cover is shown, so what gets revealed is already the drawn prize; scratching past `revealPercent` finishes the reveal and shows the shared win/lose result panel with the coupon. Same lead-capture flows and callbacks as the Wheel, plus the new `onScratchResult` callback on `InngageInApp.show`. New models: `InAppV2ScratchConfig`, `InAppV2ScratchPrize`.

#### Removed:
- `InAppModel`, `RichContent` and `CarrouselImagesModel` (replaced by the models above).
- `InngageInAppWidget` (in-app messages are no longer queued for display on app resume; call `InngageInApp.show` on demand instead).
- `InngageDialog.showInAppDialog` and the `dialogs/app_dialog.dart` export.
- `InngageInApp.blockDeepLink` and `InngageInApp.deepLinkCallback` (use `InngageProperties.blockDeepLink` plus the `onAction` callback of `InngageInApp.show`).
- The `inapp_message` handling inside the FCM notification handlers. `InngageHandlersNotification.handleBackgroundNotification` is kept as a no-op for backward compatibility of existing background handlers.
- The `"inapp"`/`"metadata"` secure-storage keys used by the old flow are cleared on `InngageSDK.subscribe`.

#### Changed:
- `SubscriptionService.subscription` now returns the API response body (`Map<String, dynamic>?`) instead of `void`, so the `app_id` can be extracted.

## 3.9.0
#### Fixed:
- Request/response payloads (which may contain PII such as e-mail, phone number and custom fields) are no longer printed unconditionally to the console. All SDK logging below error level is now gated on `InngageSDK.setDebugMode(true)`; errors are always logged.
- `InngageUtils.setKeyAuthorization` now takes effect even when called after the SDK's HTTP client has been created. Previously the authorization key was captured once at startup and later changes were silently ignored.
- `InngageSDK.subscribe`'s `firebaseListenCallback` no longer throws a `TypeError` when the callback is typed (e.g. `void Function(Map<String, dynamic>)`); any single-argument callback signature is now accepted.

#### Changed:
- `InngageEvent.sendEvent` no longer requires `appToken`: when omitted, the token configured via `InngageSDK.subscribe` is used. Passing it explicitly still works and takes precedence.
- `InngageEvent.sendEvent` now returns `false` when the API call fails (HTTP error or no connectivity). Previously network errors were swallowed and the method always returned `true`. If your app branches on the result, error paths that never triggered before may now run.
- `InngageInApp.deepLinkCallback` is now typed as `void Function(String? link)` instead of the untyped `Function`. Untyped closures (`(link) { ... }`) keep working unchanged; closures explicitly typed as non-nullable (`(String link) { ... }`) or taking no arguments must be updated:
  ```dart
  // Before (3.8.x)
  InngageInApp.deepLinkCallback = (String link) { ... };
  // After (3.9.0)
  InngageInApp.deepLinkCallback = (String? link) { ... };
  ```

#### Deprecated:
- `InngageSDK.notificationController`: this stream never emitted any events, so no working integration depends on it. It will be removed in 4.0, together with `InngageSDK` extending `ChangeNotifier` (which likewise never notified listeners) and the `InngageSDK().inngageProperties` instance field (access the all-static `InngageProperties` directly).

#### Removed:
- Dead code: `lib/models/inngage_properties.dart` (fully commented-out duplicate of `shared/inngage_properties.dart`).
- Unused `win32` dependency.

## 3.8.2
#### Fixed: 
- Click redirection for the in-app message button and card.

## 3.8.1
#### Changed:
- Migrated all dependency constraints from caret (`^`) notation to explicit version ranges (`>=min <=max`) to provide greater flexibility for consumers of the SDK, allowing compatibility across multiple major and minor versions. Affected packages:
  - `device_info_plus`: `^10.1.2` → `>=10.1.2 <=13.1.0`
  - `firebase_core`: `^4.2.1` → `>=4.2.1 <=4.10.0`
  - `firebase_analytics`: `^12.0.4` → `>=12.0.4 <=12.4.2`
  - `firebase_messaging`: `^16.0.4` → `>=16.0.4 <=16.3.0`
  - `flutter_local_notifications`: `^18.0.1` → `>=18.0.1 <=21.0.0`
  - `url_launcher`: `^6.3.1` → `>=6.3.1 <=6.3.2`
  - `webview_flutter`: `^4.8.0` → `>=4.8.0 <=4.13.1`
  - `devicelocale`: `^0.8.0` → `>=0.8.0 <=0.9.0`
  - `geolocator`: `^12.0.0` → `>=12.0.0 <=14.0.2`
  - `uuid`: `^4.5.1` → `>=4.4.1 <=4.5.3`
  - `shared_preferences`: `^2.3.2` → `>=2.3.2 <=2.5.5`
  - `package_info_plus`: `^8.0.2` → `>=8.0.2 <=10.1.0`
  - `advertising_id`: `^2.6.0` → `>=2.6.0 <=2.7.1`
  - `meta`: `^1.12.0` → `>=1.15.0 <=1.18.2`
  - `http`: `^1.2.1` → `>=1.2.1 <=1.6.0`
  - `logger`: `^2.3.0` → `>=2.3.0 <=2.7.0`
  - `flutter_image_slideshow`: `^0.1.6` → `>=0.1.3 <=0.1.6`
  - `flutter_secure_storage`: `^9.2.2` → `>=9.2.2 <=10.3.1`
  - `win32`: `^5.10.0` → `>=5.10.0 <=6.3.0`

## 3.8.0
#### Added: 
- Implemented a new iOS Notification Service Extension in Swift to support richer push notification handling on sample application.
#### Fixed:
- Fixed an issue where push notifications with images were not displayed correctly in foreground on Android.
- Fixed duplicate push notifications stacking on screen.
- Fixed an issue where the WebView page was not loading when triggered by push notification click.
#### Changed
- Improved in-app message data handling for more reliable payload processing.

## 3.7.3
* update: ``firebase_core`` to version 4.2.1, ``firebase_analytics`` to version 12.0.4 and ``firebase_messaging`` to version 16.0.4.

## 3.7.2
* fix: Corrected the UTM key name in the event sent to GA.
* build: Removed the package attribute from `AndroidManifest.xml` to support AGP 8.x+, and updated the namespace in `build.gradle`.

Some dependencies may require updating the Dart SDK and Flutter SDK. Internal tests were performed using Dart 3.6.1 and Flutter 3.27.2:
* uuid: 4.5.1
* meta: 1.12.0
* shared_preferences: 2.3.2
* win32: 5.10.0

## 3.7.1
* fix: Ensure conversion event parameters are properly registered.

## 3.7.0
* feat: Added new notification handlers for increased flexibility with Firebase Messaging.
* refactor: SDK reorganized and functions renamed for better readability and alignment with other Inngage SDKs.
* fix: Fixed push notification reception and click tracking on iOS (foreground and when app is closed).

## 3.6.10
* fix: added `namespace` on plugin.

## 3.6.9
* fix: fixed build issue by explicitly defining the `namespace` in the module-level `build.gradle`, as required by Android Gradle Plugin 7.0+.

## 3.6.8
* refactor: separate Firebase logic into dedicated methods

## 3.6.7
* fix: callback data firebase closed app

## 3.6.6
* fix: add ``appToken`` in ``addUserData``

## 3.6.5
* chore: include UUID in subscription request

## 3.6.4
* chore: add dependencies: ``uuid`` and ``shared_preferences``. 
* fix: Generating a unique UUID for user registration.

## 3.6.3
* fix: closing In App Message after clicked.

## 3.6.2
* fix: handle clicks on carousel images in the In App Message.

## 3.6.1
* feature: updated notification color for foreground display.

## 3.6.0
* feature: updated notification icon for foreground display.
* feature: added support for email and phoneNumber in the ``addUserData`` method.
* refactor: removed deprecated field and non-functional method.
* refactor: revised handling of UTM data. 
* update: ``device_info_plus`` to version 10.1.2, ``package_info_plus`` to version 8.0.2 and ``devicelocale`` to version 0.8.0.

## 3.5.2
* chore: removing deprecated dependencies. 

## 3.5.1
* fix: removing class causing error in Crash Analytics.

## 3.5.0
* feature: sending UTM parameters to Google Analytics

## 3.4.0
### Dependency updates to the following versions:
* firebase_core: 2.10.0 to 3.1.0.
* firebase_core: 2.10.0 to 3.1.0.
* firebase_messaging: 14.4.1 to 15.0.1.
* flutter_local_notifications: 16.3.3 to 17.1.2.
* url_launcher: 6.1.10 to 6.3.0.
* webview_flutter: 4.2.0 to 4.8.0.
* devicelocale: 0.5.0 to 0.7.1.
* geolocator: 10.1.0 to 12.0.0.
* advertising_id: 2.4.0 to 2.6.0.
* meta: 1.7.0 to 1.12.0.
* http: 1.1.0 to 1.2.1.
* flutter_image_slideshow: 0.1.5 to 0.1.6.
* device_info to device_info_plus (version 10.1.0)

Some dependencies require updating the Dart SDK to at least 3.0.0 and the Flutter SDK to at least 3.13.1. For more information, we recommend checking the Changelog of the listed dependencies.

## 3.3.0
* chore: update logger and flutter_secure_storage dependencies
## 3.2.0
* update: improvement in notification handling
* fix: notification status in closed app
## 3.1.1
* update: remove unnecessary permission from AndroidManifest
## 3.1.0
* chore: Added debug function for the SDK: ``InngageSDK.setDebugMode()``.
* update: Updated dependencies to ``flutter_local_notifications`` version 16.3.3.
## 3.0.0
* feature: add geolocation support to subscribe function
* chore: improvement of in-app design and performance
* update: update some dependencies to support Dart 3.0
## 2.0.12 
* chore: update http dependency.
## 2.0.11 
* fix: opening the deeplink through the ``firebaseListenCallback`` with the app closed.
## 2.0.10 
* chore: add ```attributionId``` on subscriber. 
* chore: update some dependencies.
* refactor: remove the ```registration``` parameter from the ```addUserData``` method. Value automatically filled.
* fix: fixed notification icon not appearing in foreground.
## 2.0.9
## 2.0.8+4
## 2.0.8+3
## 2.0.8+2
## 2.0.8+1
## 2.0.8
## 2.0.7
## 2.0.6
## 2.0.5
## 2.0.4+2
## 2.0.4+1
## 2.0.4
## 2.0.3+2
## 2.0.3+1
## 2.0.3
## 2.0.2+1
## 2.0.2
## 2.0.1
## 2.0.0+1
## 2.0.0
## 1.4.0
## 1.4.1
## 1.3.6
## 1.3.5
## 1.3.4
## 1.3.3
## 1.3.2
## 1.3.1
## 1.3.0
## 1.2.1
## 1.2.0
## 1.1.0
## 1.0.6
## 1.0.5
## 1.0.4
## 1.0.3
## 1.0.2
## 1.0.1
## 1.0.0
## 0.0.1