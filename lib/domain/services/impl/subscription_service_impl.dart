import 'package:inngage_plugin/data/api/inngage_network.dart';
import 'package:inngage_plugin/data/model/inngage/subscription_request.dart';
import '../subscription_service.dart';

class SubscriptionServiceImpl implements SubscriptionService {
  final InngageNetwork network;

  SubscriptionServiceImpl(this.network);

  @override
  Future<void> subscription(SubscriptionRequest subscription) {
    return network.subscription(subscription);
  }
}
