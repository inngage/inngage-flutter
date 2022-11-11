import 'package:flutter/material.dart';
import 'package:inngage_plugin/models/inngage_properties.dart';
import 'package:inngage_plugin/util/utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InngageNotification {

  static void openCommonNotification(
      {required Map<String, dynamic> data,
      required String appToken,
      bool inBack = false}) async {
    if (InngageProperties.isInOpen) return;
    InngageProperties.isInOpen = true;
    Future.delayed(const Duration(seconds: 4))
        .then((value) => InngageProperties.isInOpen = false);

    if (InngageProperties.getDebugMode()) {
      debugPrint("openCommonNotification: $data");
    }

    //final Map<String, dynamic>? data = payload['data'];
    String? notificationId = '';

    if (data.containsKey('notId')) {
      notificationId = data['notId'];
    }
    Future.microtask(
      () => InngageProperties.inngageNetwork.notification(
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
        InngageUtils.launchURL(url);
        return;
      case 'inapp':
        if (inBack) {
          Future.delayed(const Duration(seconds: 3))
              .then((value) => showCustomNotification(
                    messageNotification: messageNotification,
                    titleNotification: titleNotification,
                    url: url,
                  ));
        } else {
          showCustomNotification(
            messageNotification: messageNotification,
            titleNotification: titleNotification,
            url: url,
          );
        }

        break;
    }
  }

  static void showCustomNotification({
    required String? titleNotification,
    required String messageNotification,
    required String url,
  }) async {
    final currentState = InngageProperties.navigatorKey.currentState;
    if (currentState != null) {
      currentState.push(
        MaterialPageRoute(
            builder: (context) => Scaffold(
                appBar: AppBar(
                  title: InngageProperties.inngageWebViewProperties.appBarText,
                ),
                body: WebView(
                  initialUrl: url,
                  zoomEnabled: InngageProperties.inngageWebViewProperties.withZoom,
                  debuggingEnabled: InngageProperties.inngageWebViewProperties.debuggingEnabled,
                  javascriptMode: InngageProperties.inngageWebViewProperties.withJavascript
                      ? JavascriptMode.unrestricted
                      : JavascriptMode.disabled,
                ))),
      );
    }
  }
}
