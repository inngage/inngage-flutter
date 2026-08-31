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