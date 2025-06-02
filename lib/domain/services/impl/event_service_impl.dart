import 'package:inngage_plugin/data/api/inngage_network.dart';
import 'package:inngage_plugin/data/model/inngage/event_request.dart';
import '../event_service.dart';

class EventServiceImpl implements EventService {
  final InngageNetwork network;

  EventServiceImpl(this.network);

  @override
  Future<void> sendEvent(Event event) {
    return network.sendEvent(event);
  }
}
