import 'package:inngage_plugin/inngage_plugin.dart';
import 'package:url_launcher/url_launcher.dart';

class InngageActions {
  static void executeAction(String type, String link) {
    switch (type) {
      case "":
        break;
      case "deep":
        if (InngageInApp.blockDeepLink) {
          InngageInApp.deepLinkCallback(link);
        } else {
          _deep(link);
        }
        break;
      case "inapp":
        _web(link);
        break;
    }
  }

  static void _deep(String link) async {
    final Uri _url = Uri.parse(link);
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  static void _web(String link) async {
    final Uri _url = Uri.parse(link);
    if (!await launchUrl(_url, mode: LaunchMode.inAppWebView)) {
      throw Exception('Could not launch $_url');
    }
  }
}
