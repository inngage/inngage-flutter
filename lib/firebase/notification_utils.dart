import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:inngage_plugin/inngage_plugin.dart';
import 'package:inngage_plugin/services/inngage_service.dart';

Future<void> requestPermissions() async {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> registerFCMToken() async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    try {
      await InngageService.registerSubscriber(token);
    } catch (e) {
      debugPrint('registerFCMToken error: $e');
    }
  }
}

void openNotification(Map<String, dynamic> data, {bool inBack = false}) {
  InngageNotification.openCommonNotification(
    data: data,
    appToken: InngageProperties.appToken,
    inBack: inBack,
  );
}