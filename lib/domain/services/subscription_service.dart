import '../../data/model/inngage/add_custom_field_request.dart';
import '../../data/model/inngage/subscription_request.dart';

abstract class SubscriptionService {
  /// Registers the subscriber (`POST /v4/subscription/`) and returns the API
  /// response body (which carries the `appId` required by the In-App flow and
  /// the `subscriberId`), or `null` on delivery failure.
  Future<Map<String, dynamic>?> subscription(SubscriptionRequest subscription);

  /// Writes custom fields (`POST /v4/subscription/addCustomField`) without
  /// session side effects. Returns the API response body (`status`,
  /// `message`, `appId`), or `null` on delivery failure.
  Future<Map<String, dynamic>?> addCustomField(AddCustomFieldRequest request);
}
