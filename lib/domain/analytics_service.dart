import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> sendUTMParameters(Map<String, String> utmParameters) async {
    try {
      if (utmParameters.isEmpty) {
        debugPrint('Nenhum parâmetro UTM foi encontrado.');
        return;
      }

      debugPrint('Enviando UTM Parameters: $utmParameters');

      await _analytics.logEvent(
        name: 'inngage_notification_click',
        parameters: utmParameters,
      );

      debugPrint('Evento UTM Parameters enviado com sucesso.');
    } catch (e) {
      debugPrint('Erro ao enviar evento UTM Parameters: $e');
    }
  }
}
