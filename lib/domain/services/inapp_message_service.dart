import '../../data/model/inapp/object_message_request.dart';

abstract class InAppMessageService {
  /// Fetches the current In-App message object from `/v4/message/objectMessage`.
  /// Returns the raw response body, or `null` on delivery failure.
  Future<Map<String, dynamic>?> getObjectMessage(ObjectMessageRequest request);
}
