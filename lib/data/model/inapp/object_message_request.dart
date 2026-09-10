/// Request body for `POST /v4/message/objectMessage`.
///
/// `appId` and `registration` are persisted from the subscription response;
/// both are prerequisites — the fetch is aborted when either is missing.
class ObjectMessageRequest {
  /// In-App channel identifier, fixed by the contract.
  static const int inAppChannelId = 6;

  final int appId;
  final String registration;
  final bool firstAccess;
  final int channelId;

  const ObjectMessageRequest({
    required this.appId,
    required this.registration,
    required this.firstAccess,
    this.channelId = inAppChannelId,
  });

  Map<String, dynamic> toJson() => {
        'appId': appId,
        'registration': registration,
        'firstAccess': firstAccess,
        'channelId': channelId,
      };
}
