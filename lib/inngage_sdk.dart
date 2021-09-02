import 'dart:async';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:inngage_plugin/inngage_plugin.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

class InngageSDK extends ChangeNotifier {
  InngageSDK._internal();
  factory InngageSDK() => _singleton;

  static final InngageSDK _singleton = InngageSDK._internal();

  static FirebaseApp? defaultApp;
  static DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static String _identifier = '';
  static String _phoneNumber = '';
  static Map<String, dynamic> _customFields = {};
  static InngageNetwork _inngageNetwork = InngageNetwork();
  static GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static InngageWebViewProperties _inngageWebViewProperties =
      InngageWebViewProperties();

  static Future<void> subscribe({
    required String appToken,
    required GlobalKey<NavigatorState> navigatorKey,
    String friendlyIdentifier = '',
    String? phoneNumber,
    Map<String, dynamic>? customFields,
    InngageWebViewProperties? inngageWebViewProperties,
  }) async {
    try {
      //initialize firebase
      defaultApp = await Firebase.initializeApp();
    } catch (error) {
      print(error.toString());
    }
    //validation identifier
    if (friendlyIdentifier.isEmpty) {
      _identifier = await _getId();
    } else {
      _identifier = friendlyIdentifier;
    }

    //set navigator key
    _navigatorKey = navigatorKey;

    //set inngage web view properties
    if (inngageWebViewProperties != null) {
      _inngageWebViewProperties = inngageWebViewProperties;
    }
    //set inngage web view properties
    if (phoneNumber != null) {
      _phoneNumber = phoneNumber;
    }

    //set customFields properties
    if (customFields != null) {
      _customFields = customFields;
    }
    FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((event) {
      _openCommonNotification(
        payload: event.data,
        appToken: appToken,
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      _openCommonNotification(
        payload: event.data,
        appToken: appToken,
      );
    });
    //firebase config notifications handlers
    // _firebaseMessaging.configure(
    //   onBackgroundMessage: Platform.isIOS ? null : _backgroundMessageHandler,
    //   onMessage: (Map<String, dynamic> payload) async {},
    //   onLaunch: (Map<String, dynamic> payload) async {

    //   },
    //   onResume: (Map<String, dynamic> payload) async {
    //     _openCommonNotification(
    //       payload: payload,
    //       appToken: appToken,
    //     );
    //   },
    // );

    //request permission to iOS device
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true, // Required to display a heads up notification
        badge: true,
        sound: true,
      );
    }

    //get device infos
    String? locale = await Devicelocale.currentLocale;
    List? languages = await Devicelocale.preferredLanguages;
    final deviceModel = await _getDeviceModel();
    final osDevice = await _getDeviceOS();
    final uuid = await _getUniqueId();
    final manufacturer = await _getDeviceManufacturer();
    final appVersion = await _getVersionApp();

    _firebaseMessaging.getToken().then(
      (String? registration) async {
        assert(registration != null);
        print(registration);
        final registerSubscriberRequest = RegisterSubscriberRequest(
          appInstalledIn: DateTime.now(),
          appToken: appToken,
          appUpdatedIn: DateTime.now(),
          customField: _customFields,
          appVersion: appVersion,
          deviceModel: deviceModel,
          sdk: '1',
          phoneNumber: _phoneNumber,
          deviceManufacturer: manufacturer,
          identifier: _identifier,
          osLanguage: languages![0] ?? '',
          osLocale: locale,
          osVersion: osDevice,
          registration: registration,
          uuid: uuid,
          platform: Platform.isAndroid ? 'Android' : 'iOS',
        );

        //make request subscription to inngage backend
        await _inngageNetwork.subscription(
          SubscriptionRequest(
            registerSubscriberRequest: registerSubscriberRequest,
          ),
        );
      },
    );
  }

  static void _showCustomNotification({
    required String? titleNotification,
    required String messageNotification,
    required String url,
  }) async {
    final result = await (FlutterNativeDialog.showConfirmDialog(
      title: titleNotification,
      message: messageNotification + '\n' + 'podemos redirecionar $url ?',
    ) as FutureOr<bool>);

    if (result) {
      _navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => WebviewScaffold(
            url: url,
            appBar: new AppBar(
              title: _inngageWebViewProperties.appBarText,
            ),
            withZoom: _inngageWebViewProperties.withZoom,
            withLocalStorage: _inngageWebViewProperties.withLocalStorage,
            hidden: true,
            debuggingEnabled: _inngageWebViewProperties.debuggingEnabled,
            withJavascript: _inngageWebViewProperties.withJavascript,
            initialChild: Container(
              color: _inngageWebViewProperties.backgroundColor,
              child: Center(
                child: _inngageWebViewProperties.customLoading != null
                    ? _inngageWebViewProperties.customLoading
                    : CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _inngageWebViewProperties.loaderColor,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    }
  }

  /// Define a top-level named handler which background/terminated messages will
  /// call.
  ///
  /// To verify things are working, check out the native platform logs.
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.
    await Firebase.initializeApp();
    print('Handling a background message ${message.messageId}');
  }

  static void _openCommonNotification({
    required Map<String, dynamic> payload,
    required String appToken,
  }) async {
    print("openCommonNotification: $payload");

    final Map<String, dynamic>? data = payload['data'];
    if (data != null) {
      String? notificationId = '';

      if (data.containsKey('notId')) {
        notificationId = data['notId'];
      }
      await _inngageNetwork.notification(
        notid: notificationId ?? '',
        appToken: appToken,
      );

      final String type = data['type'] ?? '';
      final String url = data['url'] ?? '';

      final titleNotification = data['title'];
      final messageNotification = data['message'];

      type == 'deep'
          ? _launchURL(url)
          : _showCustomNotification(
              messageNotification: messageNotification,
              titleNotification: titleNotification,
              url: url,
            );
    }
  }

  static Future<String> _getVersionApp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // String appName = packageInfo.appName;
    // String packageName = packageInfo.packageName;
    //String version = packageInfo.version;
    //String buildNumber = packageInfo.buildNumber;
    return packageInfo.version;
  }

  static void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<String> _getDeviceOS() async {
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.systemVersion;
    } else {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.release;
    }
  }

  static Future<String> _getDeviceModel() async {
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.utsname.machine;
    } else {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.model;
    }
  }

  static Future<String> _getDeviceManufacturer() async {
    if (Platform.isIOS) {
      return 'Apple';
    } else {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.manufacturer;
    }
  }

  static Future<String> _getUniqueId() async {
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    } else {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.androidId;
    }
  }

  static Future<String> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId; // unique ID on Android
    }
  }

  static setIdentifier({required String identifier}) async {
    _identifier = identifier;
  }

  static sendEventsendEvent({
    required String eventName,
    required String appToken,
    required String identifier,
    Map<String, dynamic> eventValues = const {},
  }) async {
    await _inngageNetwork.sendEvent(
        eventName: eventName, appToken: appToken, identifier: identifier);
  }

  static setCustomFields({required Map<String, dynamic> customFields}) {
    _customFields = customFields;
  }
}

class InngageWebViewProperties {
  InngageWebViewProperties({
    this.backgroundColor = Colors.white,
    this.appBarColor = Colors.blue,
    this.loaderColor = Colors.blue,
    this.appBarText = const Text('Webview'),
    this.withZoom = true,
    this.withLocalStorage = true,
    this.debuggingEnabled = false,
    this.withJavascript = true,
    this.customLoading,
  });
  Color backgroundColor;
  Color appBarColor;
  Color loaderColor;
  Text appBarText;
  bool withZoom;
  bool withLocalStorage;
  bool debuggingEnabled;
  bool withJavascript;
  Widget? customLoading;
}
