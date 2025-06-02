import '../../data/model/inngage/event_request.dart';

abstract class EventService {
  Future<void> sendEvent(Event event);
}
