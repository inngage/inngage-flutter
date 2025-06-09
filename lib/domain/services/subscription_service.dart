import '../../data/model/inngage/subscription_request.dart';

abstract class SubscriptionService {
  Future<void> subscription(SubscriptionRequest subscription);
}
