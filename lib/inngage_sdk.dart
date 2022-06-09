import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:inngage_plugin/inngage_plugin.dart';
import 'package:logger/logger.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InngageSDK extends ChangeNotifier {
  InngageSDK._internal();
  factory InngageSDK() => _singleton;

  static bool _isInOpen = false;
  static final InngageSDK _singleton = InngageSDK._internal();

  static FirebaseApp? defaultApp;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static String _identifier = '';
  static String _phoneNumber = '';
  static String _appToken = '';
  static String _registration = '';
  static String _keyAuthorization = '';
  static Map<String, dynamic> _customFields = {};

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final InngageNetwork _inngageNetwork = InngageNetwork(
    keyAuthorization: _keyAuthorization,
    logger: Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 20000,
        colors: true,
        printEmojis: true,
        printTime: false,
      ),
    ),
  );
  static GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static InngageWebViewProperties _inngageWebViewProperties =
      InngageWebViewProperties();
  static bool _debugMode = false;

  static bool getDebugMode() => _debugMode;

  static var notificationController =
      StreamController<RemoteMessage>.broadcast();

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
    _appToken = appToken;
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
    FirebaseInAppMessaging m = FirebaseInAppMessaging.instance;
    _firebaseMessaging.getInitialMessage().then((value) {
      try {
        _openCommonNotification(
            data: value!.data, appToken: _appToken, inBack: true);
      } catch (e) {}
    });
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

    if (Platform.isAndroid) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('launch_background');

      final IOSInitializationSettings initializationSettingsIOS =
          IOSInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
              onDidReceiveLocalNotification: (
                int id,
                String? title,
                String? body,
                String? payload,
              ) async {});

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: (String? payload) async {
        if (payload != null) {
          debugPrint('notification payload: $payload');
          _openCommonNotification(
            data: json.decode(payload),
            appToken: _appToken,
          );
        }
      });
    }
    FirebaseMessaging.onMessage.listen((message) async {
      if (getDebugMode()) {
        print('onMessage ${message.data}');
      }

      var inappMessage = false;
      try {
        var data = json.decode(message.data['additional_data']);

        inappMessage = data['inapp_message'];

        var inAppModel = InAppModel.fromJson(data);

        if (inappMessage) {
          showInAppDialog(inAppModel);
        }
      } catch (e) {}
      print('logx listen $inappMessage');
      if (inappMessage) {
      } else {
        if (Platform.isAndroid) {
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
                  'high_importance_channel', 'your channel name',
                  channelDescription: 'your channel description',
                  importance: Importance.max,
                  priority: Priority.high,
                  ticker: 'ticker');
          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);
          final titleNotification = message.data['title'];
          final messageNotification = message.data['message'];
          await flutterLocalNotificationsPlugin.show(0, titleNotification,
              messageNotification, platformChannelSpecifics,
              payload: json.encode(message.data));
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      if (getDebugMode()) {
        print('onMessageOpenedApp ${event.from}');
        print('onMessageOpenedApp ${event.messageType}');
      }
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
          print("logx $registration");
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
 
 
 
 
 
 
 try {
      final prefs = await SharedPreferences.getInstance();
     var datax = prefs.getString('inapp');
      var data = json.decode(datax!);

      var inappMessage = data['inapp_message'];

      if (inappMessage) {
        
        var inAppModel = InAppModel.fromJson(data);
        showInAppDialog(inAppModel);
      }
    } catch (e) {
      print(e);
    }
 
 
 
 
 
 
 
 
 
 
  }

  static showInAppDialog(InAppModel inAppModel) async {
    try {
      final currentState = _navigatorKey.currentState;
      showDialog(
          context: currentState!.context,
          builder: (_) {
            return InAppDialog(
                inAppModel: inAppModel,
                inngageWebViewProperties: _inngageWebViewProperties,
                navigatorKey: _navigatorKey);
          });
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('inapp');
    } catch (e) {}
  }

  static void _showCustomNotification({
    required String? titleNotification,
    required String messageNotification,
    required String url,
  }) async {
    final currentState = _navigatorKey.currentState;
    if (currentState != null) {
      currentState.push(
        MaterialPageRoute(
            builder: (context) => Scaffold(
                appBar: AppBar(
                  title: _inngageWebViewProperties.appBarText,
                ),
                body: WebView(
                  initialUrl: url,
                  zoomEnabled: _inngageWebViewProperties.withZoom,
                  debuggingEnabled: _inngageWebViewProperties.debuggingEnabled,
                  javascriptMode: _inngageWebViewProperties.withJavascript
                      ? JavascriptMode.unrestricted
                      : JavascriptMode.disabled,
                ))),
      );
    }
  }

  /// Define a top-level named handler which background/terminated messages will
  /// call.
  ///
  /// To verify things are working, check out the native platform logs.
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    var inappMessage = false;
    try {
      final prefs = await SharedPreferences.getInstance();

      var data = json.decode(message.data['additional_data']);

      inappMessage = data['inapp_message'];

      if (inappMessage) {
        
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("inapp", message.data['additional_data']);
        var inAppModel = InAppModel.fromJson(data);
        showInAppDialog(inAppModel);
      }
    } catch (e) {
      print(e);
    }
    print('logx listen $inappMessage');

    if (getDebugMode()) {
      //print('_firebaseMessagingBackgroundHandler ${message.toString()}');
    }

    try {
      _openCommonNotification(
        data: message.data,
        appToken: _appToken,
      );
    } catch (e) {}
  }

  static void _openCommonNotification(
      {required Map<String, dynamic> data,
      required String appToken,
      bool inBack = false}) async {
    if (_isInOpen) return;
    _isInOpen = true;
    Future.delayed(const Duration(seconds: 4))
        .then((value) => _isInOpen = false);

    if (getDebugMode()) {
      print("openCommonNotification: $data");
    }

    //final Map<String, dynamic>? data = payload['data'];
    String? notificationId = '';

    if (data.containsKey('notId')) {
      notificationId = data['notId'];
    }
    Future.microtask(
      () => _inngageNetwork.notification(
        notid: notificationId ?? '',
        appToken: appToken,
      ),
    );
    final String type = data['type'] ?? '';
    final String url = data['url'] ?? '';

    final titleNotification = data['title'];
    final messageNotification = data['message'];

    if (type.isEmpty) {
      return;
    }
    switch (type) {
      case 'deep':
        _launchURL(url);
        return;
      case 'inapp':
        if (inBack) {
          Future.delayed(const Duration(seconds: 3))
              .then((value) => _showCustomNotification(
                    messageNotification: messageNotification,
                    titleNotification: titleNotification,
                    url: url,
                  ));
        } else {
          _showCustomNotification(
            messageNotification: messageNotification,
            titleNotification: titleNotification,
            url: url,
          );
        }

        break;
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
    final urlEncode = Uri.encodeFull(url);
    if (await canLaunch(urlEncode)) {
      await launch(urlEncode, forceWebView: false, forceSafariVC: false);
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

  static void addUserData({
    String? identifier,
    String? register,
    Map<String, dynamic>? customFields,
  }) async {
    _identifier = identifier ?? "";
    _registration = register ?? "";
    _customFields = customFields ?? {};
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

class InAppDialog extends StatelessWidget {
  InAppModel inAppModel;
  InngageWebViewProperties inngageWebViewProperties;
  GlobalKey<NavigatorState> navigatorKey;
  InAppDialog(
      {Key? key,
      required this.inAppModel,
      required this.inngageWebViewProperties,
      required this.navigatorKey})
      : super(key: key);
  static GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  static InngageWebViewProperties _inngageWebViewProperties2 =
      InngageWebViewProperties();
  @override
  Widget build(BuildContext context) {
    _inngageWebViewProperties2 = inngageWebViewProperties;
    _navigatorKey = navigatorKey;
    return Center(
      child: SizedBox(
        child: Stack(
          alignment: Alignment.center,
          children: [
            alertDialog(context),
          ],
        ),
      ),
    );

    //alertDialog(context);
  }

/*  if (inAppModel.backgroundImg != null &&
                inAppModel.backgroundImg!.length > 5)
              Image.network(
                inAppModel.backgroundImg!,
                fit: BoxFit.cover,
              ), */
  AlertDialog alertDialog(BuildContext context) {
    var dots = 0;
    if (inAppModel.richContent!.img1 != null) dots++;
    if (inAppModel.richContent!.img2 != null) dots++;
    if (inAppModel.richContent!.img3 != null) dots++;

    return AlertDialog(
      backgroundColor: HexColor.fromHex(inAppModel.backgroundColor ?? "#FFF"),
      title: Text(
        inAppModel.title ?? "",
        textAlign: TextAlign.center,
        style: TextStyle(
            color: HexColor.fromHex(inAppModel.titleFontColor ?? "#000")),
      ),
      content: SizedBox(
        height: 310,
        child: Column(
          children: [
            inAppModel.richContent!.carousel!
                ? SizedBox(
                    height: 220,
                    width: 400,
                    child: ImageSlideshow(
                      width: 533,
                      height: 200,
                      initialPage: 0,

                      indicatorColor: dots < 2
                          ? Colors.transparent
                          : HexColor.fromHex(
                              inAppModel.backgroundColor ?? "#0000FF"),
                      indicatorBackgroundColor: Colors.grey,
                      children: [
                        if (inAppModel.richContent!.img1 != null)
                          Image.network(
                            inAppModel.richContent!.img1!,
                            fit: BoxFit.cover,
                          ),
                        if (inAppModel.richContent!.img2 != null)
                          Image.network(
                            inAppModel.richContent!.img2!,
                            fit: BoxFit.cover,
                          ),
                        if (inAppModel.richContent!.img3 != null)
                          Image.network(
                            inAppModel.richContent!.img3!,
                            fit: BoxFit.cover,
                          ),
                      ],

                      /// Called whenever the page in the center of the viewport changes.
                      onPageChanged: (value) {
                        print('Page changed: $value');
                      },

                      /// Auto scroll interval.
                      /// Do not auto scroll with null or 0.

                      /// Loops back to first slide.
                      isLoop: inAppModel.richContent!.img1 != null &&
                          inAppModel.richContent!.img2 != null &&
                          inAppModel.richContent!.img3 != null,
                    ),
                  )
                : Container(),
            const SizedBox(
              height: 25,
            ),
            Text(
              inAppModel.body ?? "",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: HexColor.fromHex(inAppModel.bodyFontColor ?? "#000")),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: inAppModel.btnLeftTxt == null || inAppModel.btnRightTxt == null
          ? [
              if (inAppModel.btnLeftTxt != null)
                Center(
                  child: TextButton(
                    child: Text(
                      inAppModel.btnLeftTxt ?? "",
                      style: TextStyle(
                          color: HexColor.fromHex(
                              inAppModel.btnLeftTxtColor ?? "#000")),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          HexColor.fromHex(
                              inAppModel.btnLeftBgColor ?? "#FFF")),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (inAppModel.btnLeftActionLink != null) {
                        _action(inAppModel.btnLeftActionType,
                            inAppModel.btnLeftActionLink);
                      }
                    },
                  ),
                ),
              if (inAppModel.btnRightTxt != null)
                Center(
                  child: TextButton(
                    child: Text(
                      inAppModel.btnRightTxt ?? "",
                      style: TextStyle(
                          color: HexColor.fromHex(
                              inAppModel.btnRightTxtColor ?? "#000")),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          HexColor.fromHex(
                              inAppModel.btnRightBgColor ?? "#FFF")),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (inAppModel.btnRightActionLink != null) {
                        _action(inAppModel.btnRightActionType,
                            inAppModel.btnRightActionLink);
                      }
                    },
                  ),
                ),
            ]
          : [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: TextButton(
                  child: Text(
                    inAppModel.btnLeftTxt ?? "",
                    style: TextStyle(
                        color: HexColor.fromHex(
                            inAppModel.btnLeftTxtColor ?? "#000")),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        HexColor.fromHex(inAppModel.btnLeftBgColor ?? "#FFF")),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (inAppModel.btnLeftActionLink != null) {
                      _action(inAppModel.btnLeftActionType,
                          inAppModel.btnLeftActionLink);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TextButton(
                  child: Text(
                    inAppModel.btnRightTxt ?? "",
                    style: TextStyle(
                        color: HexColor.fromHex(
                            inAppModel.btnRightTxtColor ?? "#000")),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        HexColor.fromHex(inAppModel.btnRightBgColor ?? "#FFF")),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (inAppModel.btnRightActionLink != null) {
                      _action(inAppModel.btnRightActionType,
                          inAppModel.btnRightActionLink);
                    }
                  },
                ),
              ),
            ],
    );
  }

  _action(type, link) {
    switch (type) {
      case "":
        break;
      case "deep":
        _deep(link);
        break;
      case "inapp":
        _web(link);
        break;
    }
  }

  _deep(link) async {
    final urlEncode = Uri.encodeFull(link);
    if (await canLaunch(urlEncode)) {
      await launch(urlEncode, forceWebView: false, forceSafariVC: false);
    } else {
      throw 'Could not launch $urlEncode';
    }
  }

  _web(link) {
    _showCustomNotification(
        url: link,
        titleNotification: inAppModel.title,
        messageNotification: inAppModel.body!);
  }

  static void _showCustomNotification({
    required String? titleNotification,
    required String messageNotification,
    required String url,
  }) async {
    final currentState = _navigatorKey.currentState;
    if (currentState != null) {
      currentState.push(
        MaterialPageRoute(
            builder: (context) => Scaffold(
                appBar: AppBar(
                  title: _inngageWebViewProperties2.appBarText,
                ),
                body: WebView(
                  initialUrl: url,
                  zoomEnabled: _inngageWebViewProperties2.withZoom,
                  debuggingEnabled: _inngageWebViewProperties2.debuggingEnabled,
                  javascriptMode: _inngageWebViewProperties2.withJavascript
                      ? JavascriptMode.unrestricted
                      : JavascriptMode.disabled,
                ))),
      );
    }
  }
}

class InAppModel {
  bool? inappMessage;
  String? title;
  String? titleFontColor;
  String? body;
  String? bodyFontColor;
  String? backgroundColor;
  String? backgroundImg;
  RichContent? richContent;
  String? btnLeftTxt;
  String? btnLeftTxtColor;
  String? btnLeftBgColor;
  String? btnLeftActionType;
  String? btnLeftActionLink;
  String? btnRightTxt;
  String? btnRightTxtColor;
  String? btnRightBgColor;
  String? btnRightActionType;
  String? btnRightActionLink;
  String? dotColor;

  InAppModel(
      {this.inappMessage,
      this.title,
      this.titleFontColor,
      this.body,
      this.bodyFontColor,
      this.backgroundColor,
      this.backgroundImg,
      this.richContent,
      this.btnLeftTxt,
      this.btnLeftTxtColor,
      this.btnLeftBgColor,
      this.btnLeftActionType,
      this.btnLeftActionLink,
      this.btnRightTxt,
      this.btnRightTxtColor,
      this.btnRightBgColor,
      this.btnRightActionType,
      this.btnRightActionLink,
      this.dotColor});

  InAppModel.fromJson(Map<String, dynamic> json) {
    inappMessage = json['inapp_message'];
    title = json['title'];
    titleFontColor = json['title_font_color'];
    body = json['body'];
    bodyFontColor = json['body_font_color'];
    backgroundColor = json['background_color'];
    backgroundImg = json['background_img'];
    richContent = json['rich_content'] != null
        ? new RichContent.fromJson(json['rich_content'])
        : null;
    btnLeftTxt = json['btn_left_txt'];
    btnLeftTxtColor = json['btn_left_txt_color'];
    btnLeftBgColor = json['btn_left_bg_color'];
    btnLeftActionType = json['btn_left_action_type'];
    btnLeftActionLink = json['btn_left_action_link'];
    btnRightTxt = json['btn_right_txt'];
    btnRightTxtColor = json['btn_right_txt_color'];
    btnRightBgColor = json['btn_right_bg_color'];
    btnRightActionType = json['btn_right_action-type'];
    btnRightActionLink = json['btn_right_action_link'];
    dotColor = json['dot_color'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['inapp_message'] = this.inappMessage;
    data['title'] = this.title;
    data['title_font_color'] = this.titleFontColor;
    data['body'] = this.body;
    data['body_font_color'] = this.bodyFontColor;
    data['background_color'] = this.backgroundColor;
    data['background_img'] = this.backgroundImg;
    if (this.richContent != null) {
      data['rich_content'] = this.richContent!.toJson();
    }
    data['btn_left_txt'] = this.btnLeftTxt;
    data['btn_left_txt_color'] = this.btnLeftTxtColor;
    data['btn_left_bg_color'] = this.btnLeftBgColor;
    data['btn_left_action_type'] = this.btnLeftActionType;
    data['btn_left_action_link'] = this.btnLeftActionLink;
    data['btn_right_txt'] = this.btnRightTxt;
    data['btn_right_txt_color'] = this.btnRightTxtColor;
    data['btn_right_bg_color'] = this.btnRightBgColor;
    data['btn_right_action-type'] = this.btnRightActionType;
    data['btn_right_action_link'] = this.btnRightActionLink;
    data['dot_color'] = this.dotColor;
    return data;
  }
}

class RichContent {
  bool? carousel;
  String? img1;
  String? img2;
  String? img3;

  RichContent({this.carousel, this.img1, this.img2, this.img3});

  RichContent.fromJson(Map<String, dynamic> json) {
    carousel = json['carousel'];
    img1 = json['img1'];
    img2 = json['img2'];
    img3 = json['img3'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['carousel'] = this.carousel;
    data['img1'] = this.img1;
    data['img2'] = this.img2;
    data['img3'] = this.img3;
    return data;
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
