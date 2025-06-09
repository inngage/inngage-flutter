## 3.7.2
* chore: added `hasInngageData` extension getter for `RemoteMessage`.

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
* update: ``device_local_plus`` to version 10.1.2, ``package_local_plus`` to version 8.0.2 and ``devicelocale`` to version 0.8.0.

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