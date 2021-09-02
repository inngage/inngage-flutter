// To parse this JSON data, do
//
//     final event = eventFromJson(jsonString);

import 'dart:convert';

Event eventFromJson(String str) => Event.fromJson(json.decode(str));

String eventToJson(Event data) => json.encode(data.toJson());

class Event {
  Event({
    required this.newEventRequest,
  });

  NewEventRequest newEventRequest;

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        newEventRequest: NewEventRequest.fromJson(json["newEventRequest"]),
      );

  Map<String, dynamic> toJson() => {
        "newEventRequest": newEventRequest.toJson(),
      };
}

class NewEventRequest {
  NewEventRequest({
    required this.appToken,
    required this.identifier,
    required this.eventName,
    this.eventValues = const {},
  });

  String appToken;
  String identifier;
  String eventName;
  Map<String, dynamic> eventValues;

  factory NewEventRequest.fromJson(Map<String, dynamic> json) =>
      NewEventRequest(
        appToken: json["app_token"],
        identifier: json["identifier"],
        eventName: json["event_name"],
        eventValues: json["event_values"],
      );

  Map<String, dynamic> toJson() => {
        "app_token": appToken,
        "identifier": identifier,
        "event_name": eventName,
        "event_values": eventValues,
      };
}
