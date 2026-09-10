import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/api/inngage_network.dart';
import 'package:inngage_plugin/data/local/inapp_local_store.dart';
import 'package:inngage_plugin/data/model/inapp/object_message_request.dart';
import 'package:inngage_plugin/data/model/inngage/event_request.dart';
import 'package:inngage_plugin/data/model/inngage/subscription_request.dart';
import 'package:inngage_plugin/domain/inngage_service.dart';
import 'package:inngage_plugin/domain/services/event_service.dart';
import 'package:inngage_plugin/domain/services/inapp_message_service.dart';
import 'package:inngage_plugin/domain/services/notification_service.dart';
import 'package:inngage_plugin/domain/services/subscription_service.dart';

class _InMemoryLocalStore extends InAppLocalStore {
  int? appId;
  String? registration;
  bool firstAccess = true;

  @override
  Future<void> saveSubscription({
    required int appId,
    required String registration,
  }) async {
    this.appId = appId;
    this.registration = registration;
  }

  @override
  Future<int?> readAppId() async => appId;

  @override
  Future<String?> readRegistration() async => registration;

  @override
  Future<bool> readFirstAccess() async => firstAccess;

  @override
  Future<void> markFirstAccessConsumed() async => firstAccess = false;

  @override
  Future<void> clearLegacyInAppKeys() async {}
}

class _FakeInAppMessageService implements InAppMessageService {
  Map<String, dynamic>? response;
  final List<ObjectMessageRequest> requests = [];

  @override
  Future<Map<String, dynamic>?> getObjectMessage(
      ObjectMessageRequest request) async {
    requests.add(request);
    return response;
  }
}

class _UnusedSubscriptionService implements SubscriptionService {
  @override
  Future<Map<String, dynamic>?> subscription(SubscriptionRequest _) async =>
      null;
}

class _UnusedNotificationService implements NotificationService {
  @override
  Future<void> sendNotification(String notId, String appToken) async {}
}

class _UnusedEventService implements EventService {
  @override
  Future<bool> sendEvent(Event event) async => true;
}

void main() {
  late _InMemoryLocalStore store;
  late _FakeInAppMessageService inAppService;
  late InngageService service;

  setUp(() {
    store = _InMemoryLocalStore();
    inAppService = _FakeInAppMessageService();
    service = InngageService(
      subscriptionService: _UnusedSubscriptionService(),
      notificationService: _UnusedNotificationService(),
      eventService: _UnusedEventService(),
      inAppMessageService: inAppService,
      inAppLocalStore: store,
    );
  });

  group('fetchInAppMessage — prerequisites', () {
    test('aborts without fetching when app_id is missing', () async {
      store.registration = 'fcm-token';

      expect(await service.fetchInAppMessage(), isNull);
      expect(inAppService.requests, isEmpty);
    });

    test('aborts without fetching when registration is missing', () async {
      store.appId = 42;

      expect(await service.fetchInAppMessage(), isNull);
      expect(inAppService.requests, isEmpty);
    });
  });

  group('fetchInAppMessage — request contents', () {
    test('sends appId, registration, firstAccess and channelId 6', () async {
      store.appId = 42;
      store.registration = 'fcm-token';
      inAppService.response = {'type': 'Banner'};

      await service.fetchInAppMessage();

      final request = inAppService.requests.single;
      expect(request.appId, 42);
      expect(request.registration, 'fcm-token');
      expect(request.firstAccess, isTrue);
      expect(request.channelId, 6);
      expect(request.toJson(), {
        'appId': 42,
        'registration': 'fcm-token',
        'firstAccess': true,
        'channelId': 6,
      });
    });
  });

  group('fetchInAppMessage — firstAccess semantics', () {
    setUp(() {
      store.appId = 42;
      store.registration = 'fcm-token';
    });

    test('is consumed only after a successful fetch', () async {
      inAppService.response = {'type': 'Banner'};

      await service.fetchInAppMessage();
      expect(store.firstAccess, isFalse);

      await service.fetchInAppMessage();
      expect(inAppService.requests.last.firstAccess, isFalse);
    });

    test('is not consumed when the fetch fails', () async {
      inAppService.response = null;

      expect(await service.fetchInAppMessage(), isNull);
      expect(store.firstAccess, isTrue);

      await service.fetchInAppMessage();
      expect(inAppService.requests.last.firstAccess, isTrue);
    });

    test('is consumed on success even when the message is suppressed',
        () async {
      inAppService.response = {'enabled': false, 'type': 'Banner'};

      expect(await service.fetchInAppMessage(), isNull);
      expect(store.firstAccess, isFalse);
    });
  });

  group('fetchInAppMessage — response handling', () {
    setUp(() {
      store.appId = 42;
      store.registration = 'fcm-token';
    });

    test('returns the parsed message on success', () async {
      inAppService.response = {
        'type': 'Banner',
        'media': {
          'items': [
            {
              'content': {'title': 'Olá'}
            }
          ]
        },
      };

      final message = await service.fetchInAppMessage();
      expect(message, isNotNull);
      expect(message!.media.items.single.content.title, 'Olá');
    });

    test('returns null for an unrelated/empty response', () async {
      inAppService.response = {'status': 'ok'};

      expect(await service.fetchInAppMessage(), isNull);
    });
  });

  group('extractAppId', () {
    test('reads an int app_id field', () {
      expect(InngageService.extractAppId({'app_id': 42}), 42);
    });

    test('reads a numeric-string app_id field', () {
      expect(InngageService.extractAppId({'app_id': '42'}), 42);
    });

    test('reads app_id nested in another object', () {
      expect(
        InngageService.extractAppId({
          'subscription': {'app_id': 42}
        }),
        42,
      );
    });

    test('reads the production response shape (camelCase appId, nested)', () {
      expect(
        InngageService.extractAppId({
          'registerSubscriberResponse': {
            'statusDescription': 'Forwarded to new platform',
            'appId': 361,
          }
        }),
        361,
      );
    });

    test('reads a top-level camelCase appId', () {
      expect(InngageService.extractAppId({'appId': 42}), 42);
      expect(InngageService.extractAppId({'appId': '42'}), 42);
    });

    test('falls back to a plain-text body', () {
      expect(
        InngageService.extractAppId(
            {InngageNetwork.rawBodyKey: 'subscribed with app_id: 42.'}),
        42,
      );
    });

    test('returns null when absent', () {
      expect(InngageService.extractAppId({'status': 'ok'}), isNull);
      expect(InngageService.extractAppId(null), isNull);
    });
  });
}
