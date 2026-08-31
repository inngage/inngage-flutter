import '../../data/model/inngage/event_request.dart';

abstract class EventService {
  /// Returns `true` when the event was accepted by the API, `false` otherwise.
  Future<bool> sendEvent(Event event);
}
