import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:inngage_plugin/models/inngage_properties.dart';
import 'package:inngage_plugin/services/analytics_service.dart';
import 'package:inngage_plugin/services/inngage_service.dart';
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

    String? notificationId = '';

    if (data.containsKey('notId')) {
      notificationId = data['notId'];
    }

    processUTMParameters(data);

    try {
      await InngageService.registerNotification(
          notId: notificationId!, appToken: appToken);
    } catch (e) {
      debugPrint(e.toString());
    }

    final String type = data['type'] ?? '';
    final String url = data['url'] ?? '';

    final titleNotification = data['title'];
    final messageNotification = data['message'];

    if (type.isEmpty) {
      return;
    }
    switch (type) {
      case 'deep':
        if (!InngageProperties.blockDeepLink) {
          InngageUtils.launchURL(url);
        }

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

  static Future<void> processUTMParameters(Map<String, dynamic> data) async {
    if (data.containsKey('inn_utm_source')) {
      debugPrint('Capturando e enviando parâmetros do UTM');

      final utmSource = data['inn_utm_source']?.toString();
      final utmCampaign = data['inn_utm_campaign']?.toString();
      final utmMedium = data['inn_utm_medium']?.toString();
      final utmTerm = data['inn_utm_term']?.toString();

      Map<String, String> utmData = {
        if (utmSource != null && utmSource.isNotEmpty)
          "inn_utm_source": utmSource,
        if (utmCampaign != null && utmCampaign.isNotEmpty)
          "inn_utm_campaign": utmCampaign,
        if (utmMedium != null && utmMedium.isNotEmpty)
          "inn_utm_medium": utmMedium,
        if (utmTerm != null && utmTerm.isNotEmpty) "inn_utm_term": utmTerm
      };

      if (utmData.isNotEmpty) {
        debugPrint('UTM Data: ${jsonEncode(utmData)}');
        await AnalyticsService().sendUTMParameters(utmData);
      } else {
        debugPrint('Nenhum parâmetro UTM válido foi capturado.');
      }
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
        MaterialPageRoute(builder: (context) {
          WebViewController controller = WebViewController()
            ..setJavaScriptMode(
                InngageProperties.inngageWebViewProperties.withJavascript
                    ? JavaScriptMode.unrestricted
                    : JavaScriptMode.disabled)
            ..enableZoom(InngageProperties.inngageWebViewProperties.withZoom)
            ..setNavigationDelegate(
              NavigationDelegate(
                onProgress: (int progress) {
                  // Update loading bar.
                },
                onPageStarted: (String url) {},
                onPageFinished: (String url) {},
                onWebResourceError: (WebResourceError error) {},
                onNavigationRequest: (NavigationRequest request) {
                  if (request.url.startsWith(url)) {
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ),
            )
            ..loadRequest(Uri.parse(url));

          return Scaffold(
              appBar: AppBar(
                title: InngageProperties.inngageWebViewProperties.appBarText,
              ),
              body: WebViewWidget(
                controller: controller,
              ));
        }),
      );
    }
  }
}
