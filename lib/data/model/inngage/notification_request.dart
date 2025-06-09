// To parse this JSON data, do
//
//     final notificationRequest = notificationRequestFromJson(jsonString);

import 'dart:convert';

NotificationRequest notificationRequestFromJson(String str) =>
    NotificationRequest.fromJson(json.decode(str));

String notificationRequestToJson(NotificationRequest data) =>
    json.encode(data.toJson());

class NotificationRequest {
  NotificationRequest({
    required this.notificationRequest,
  });

  Notification notificationRequest;

  factory NotificationRequest.fromJson(Map<String, dynamic> json) =>
      NotificationRequest(
        notificationRequest: Notification.fromJson(json["notificationRequest"]),
      );

  Map<String, dynamic> toJson() => {
        "notificationRequest": notificationRequest.toJson(),
      };
}

class Notification {
  Notification({
    this.id,
    this.appToken,
    this.notId,
  });

  String? id;
  String? appToken;
  String? notId;

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
        id: json["id"],
        appToken: json["app_token"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "app_token": appToken,
        "notid": notId,
      };
}
