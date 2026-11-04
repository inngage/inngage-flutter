import '../../data/model/inapp/object_message_request.dart';

abstract class InAppMessageService {
  /// Fetches the current In-App message object from `/v4/message/objectMessage`.
  /// Returns the raw response body, or `null` on delivery failure.
  Future<Map<String, dynamic>?> getObjectMessage(ObjectMessageRequest request);

  /// Counts an In-App display for the campaign identified by [notId].
  Future<bool> trackInAppImpression(String notId);

  /// Counts an In-App click; [clickSource] says where the user clicked
  /// (`card`, `button`, `button_up` or `button_down`).
  Future<bool> trackInAppClick(String notId, String clickSource);
}
