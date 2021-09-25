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
    required this.registration,
    required this.eventName,
    this.eventValues = const {},
    this.conversionEvent = false,
    this.conversionValue = 0,
    this.conversionNotId = '',
  });

  String appToken;
  String identifier;
  String registration;
  String eventName;
  bool conversionEvent;
  double conversionValue;
  String conversionNotId;

  Map<String, dynamic> eventValues;

  factory NewEventRequest.fromJson(Map<String, dynamic> json) => NewEventRequest(
        appToken: json["app_token"],
        identifier: json["identifier"],
        eventName: json["event_name"],
        eventValues: json["event_values"],
        registration: json["registration"],
        conversionEvent: json["conversion_event"],
        conversionNotId: json["conversion_value"],
        conversionValue: json["conversion_notid"],
      );

  Map<String, dynamic> toJson() => {
        "app_token": appToken,
        "identifier": identifier,
        "event_name": eventName,
        "event_values": eventValues,
        "registration": registration,
        "conversion_event": conversionEvent,
        "conversion_value": conversionValue,
        "conversion_notid": conversionNotId,
      };
}
