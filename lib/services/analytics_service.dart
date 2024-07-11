import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> sendUTMParameters(Map<String, String> utmParameters) async {
    try {
      debugPrint('UTM: $utmParameters');

      await _analytics.logEvent(
        name: 'inngage_notification_click',
        parameters: utmParameters,
      );

      debugPrint('Evento UTM Parameters enviado com sucesso.');
    } catch (e) {
      debugPrint('Erro ao enviar evento UTM Parameters');
    }
  }
}
