import '../../data/model/inngage/subscription_request.dart';

abstract class SubscriptionService {
  /// Registers the subscriber and returns the API response body (which carries
  /// the `app_id` required by the In-App flow), or `null` on delivery failure.
  Future<Map<String, dynamic>?> subscription(SubscriptionRequest subscription);
}
