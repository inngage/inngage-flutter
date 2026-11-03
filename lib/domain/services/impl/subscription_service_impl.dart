import 'package:inngage_plugin/data/api/inngage_network.dart';
import 'package:inngage_plugin/data/model/inngage/add_custom_field_request.dart';
import 'package:inngage_plugin/data/model/inngage/subscription_request.dart';
import '../subscription_service.dart';

class SubscriptionServiceImpl implements SubscriptionService {
  final InngageNetwork network;

  SubscriptionServiceImpl(this.network);

  @override
  Future<Map<String, dynamic>?> subscription(SubscriptionRequest subscription) {
    return network.subscription(subscription);
  }

  @override
  Future<Map<String, dynamic>?> addCustomField(AddCustomFieldRequest request) {
    return network.addCustomField(request);
  }
}
