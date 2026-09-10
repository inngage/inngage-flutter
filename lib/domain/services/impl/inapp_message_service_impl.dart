import 'package:inngage_plugin/data/api/inngage_network.dart';
import 'package:inngage_plugin/data/model/inapp/object_message_request.dart';
import '../inapp_message_service.dart';

class InAppMessageServiceImpl implements InAppMessageService {
  final InngageNetwork network;

  InAppMessageServiceImpl(this.network);

  @override
  Future<Map<String, dynamic>?> getObjectMessage(ObjectMessageRequest request) {
    return network.getObjectMessage(request);
  }
}
