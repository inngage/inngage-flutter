import 'dart:async';
import 'dart:ffi';
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
  static String _keyAuthorization = '';
  static Map<String, dynamic> _customFields = {};
  static InngageNetwork _inngageNetwork =
      InngageNetwork(keyAuthorization: _keyAuthorization);
  static GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static InngageWebViewProperties _inngageWebViewProperties =
      InngageWebViewProperties();
  static bool _debugMode = false;

  static bool getDebugMode() => _debugMode;
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
      if (getDebugMode()) {
        print(error.toString());
      }
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
        data: event.data,
        appToken: appToken,
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      _openCommonNotification(
        data: event.data,
        appToken: appToken,
      );
    });

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
        if (getDebugMode()) {
          print(registration);
        }
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
          subscription: SubscriptionRequest(
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
    ));

    if (result ?? false) {
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
    if (getDebugMode()) {
      print('Handling a background message ${message.messageId}');
    }
  }

  static void _openCommonNotification({
    required Map<String, dynamic> data,
    required String appToken,
  }) async {
    if (getDebugMode()) {
      print("openCommonNotification: $data");
    }

    //final Map<String, dynamic>? data = payload['data'];
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

  static Future<String> _getVersionApp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // String appName = packageInfo.appName;
    // String packageName = packageInfo.packageName;
    //String version = packageInfo.version;
    //String buildNumber = packageInfo.buildNumber;
    return packageInfo.version;
  }

  static void _launchURL(String url) async {
    final urlEncode = Uri.encodeFull(url);
    if (await canLaunch(urlEncode)) {
      await launch(urlEncode);
    } else {
      throw 'Could not launch $urlEncode';
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

  static void setIdentifier({required String identifier}) async {
    _identifier = identifier;
  }

  static void setKeyAuthorization({required String keyAuthorization}) async {
    _keyAuthorization = keyAuthorization;
  }

  static Future<bool> sendEvent({
    required String eventName,
    required String appToken,
    String? identifier,
    String? registration,
    Map<String, dynamic> eventValues = const {},
    bool conversionEvent = false,
    double conversionValue = 0,
    String conversionNotId = '',
  }) async {
    if (identifier == null && registration == null) {
      throw InngageException(
        'Unfortunately it was not possible send an event,'
        ' you need to declare the identifier or registration',
      );
    }
    try {
      await Future.microtask(
        () async => await _inngageNetwork.sendEvent(
          eventName: eventName,
          appToken: appToken,
          identifier: identifier ?? '',
          registration: registration ?? '',
          eventValues: eventValues,
          conversionValue: conversionValue,
          conversionNotId: conversionNotId,
          conversionEvent: conversionEvent,
        ),
      );
    } catch (e) {
      return false;
    }
    return true;
  }

  static void setCustomFields({required Map<String, dynamic> customFields}) {
    _customFields = customFields;
  }

  static void setDebugMode(bool value) {
    _debugMode = value;
  }

  static void setUserPhone(String number) {
    _phoneNumber = number;
    if (_debugMode) {
      print("user phone number: $_phoneNumber");
    }
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
