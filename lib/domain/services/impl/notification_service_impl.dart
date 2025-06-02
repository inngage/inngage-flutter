import 'package:inngage_plugin/data/api/inngage_network.dart';
import '../notification_service.dart';

class NotificationServiceImpl implements NotificationService {
  final InngageNetwork network;

  NotificationServiceImpl(this.network);

  @override
  Future<void> sendNotification(String notId, String appToken) {
    return network.sendNotification(notId, appToken);
  }
}
