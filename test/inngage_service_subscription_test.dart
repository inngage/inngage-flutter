import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/local/inapp_local_store.dart';
import 'package:inngage_plugin/data/model/inapp/object_message_request.dart';
import 'package:inngage_plugin/data/model/inngage/add_custom_field_request.dart';
import 'package:inngage_plugin/data/model/inngage/event_request.dart';
import 'package:inngage_plugin/data/model/inngage/subscription_request.dart';
import 'package:inngage_plugin/domain/inngage_service.dart';
import 'package:inngage_plugin/domain/services/event_service.dart';
import 'package:inngage_plugin/domain/services/inapp_message_service.dart';
import 'package:inngage_plugin/domain/services/notification_service.dart';
import 'package:inngage_plugin/domain/services/subscription_service.dart';
import 'package:inngage_plugin/shared/inngage_properties.dart';

class _InMemoryLocalStore extends InAppLocalStore {
  int? appId;
  String? registration;
  String? subscriberId;
  int saves = 0;

  @override
  Future<void> saveSubscription({
    required int appId,
    required String registration,
    String? subscriberId,
  }) async {
    saves++;
    this.appId = appId;
    this.registration = registration;
    if (subscriberId != null) this.subscriberId = subscriberId;
  }

  @override
  Future<int?> readAppId() async => appId;

  @override
  Future<String?> readRegistration() async => registration;

  @override
  Future<String?> readSubscriberId() async => subscriberId;

  @override
  Future<bool> readFirstAccess() async => true;

  @override
  Future<void> markFirstAccessConsumed() async {}

  @override
  Future<void> clearLegacyInAppKeys() async {}
}

class _FakeSubscriptionService implements SubscriptionService {
  Map<String, dynamic>? addCustomFieldResponse;
  final List<AddCustomFieldRequest> addCustomFieldRequests = [];

  @override
  Future<Map<String, dynamic>?> subscription(SubscriptionRequest _) async =>
      null;

  @override
  Future<Map<String, dynamic>?> addCustomField(
      AddCustomFieldRequest request) async {
    addCustomFieldRequests.add(request);
    return addCustomFieldResponse;
  }
}

class _UnusedNotificationService implements NotificationService {
  @override
  Future<void> sendNotification(String notId, String appToken) async {}
}

class _UnusedEventService implements EventService {
  @override
  Future<bool> sendEvent(Event event) async => true;
}

class _UnusedInAppMessageService implements InAppMessageService {
  @override
  Future<Map<String, dynamic>?> getObjectMessage(
          ObjectMessageRequest _) async =>
      null;

  @override
  Future<bool> trackInAppImpression(String notId) async => true;

  @override
  Future<bool> trackInAppClick(String notId, String clickSource) async => true;
}

void main() {
  late _InMemoryLocalStore store;
  late _FakeSubscriptionService subscriptionService;
  late InngageService service;

  setUp(() {
    store = _InMemoryLocalStore();
    subscriptionService = _FakeSubscriptionService();
    service = InngageService(
      subscriptionService: subscriptionService,
      notificationService: _UnusedNotificationService(),
      eventService: _UnusedEventService(),
      inAppMessageService: _UnusedInAppMessageService(),
      inAppLocalStore: store,
    );

    InngageProperties.appToken = 'token';
    InngageProperties.identifier = 'maria@exemplo.com';
    InngageProperties.registration = 'fcm-token';
    InngageProperties.subscriberId = '';
    InngageProperties.email = '';
    InngageProperties.phoneNumber = '';
    InngageProperties.customFields = {};
  });

  group('persistSubscriptionResponse', () {
    test('persists appId, registration and subscriberId on subscriberCreated',
        () async {
      final parsed = await service.persistSubscriptionResponse({
        'registerSubscriberResponse': {
          'statusDescription': 'Successfully: subscriberCreated',
          'subscriberId': '671a',
          'appId': 3,
        },
      });

      expect(parsed.appId, 3);
      expect(store.appId, 3);
      expect(store.registration, 'fcm-token');
      expect(store.subscriberId, '671a');
      expect(InngageProperties.subscriberId, '671a');
    });

    test('uses toSubscriberId on deviceTransferred', () async {
      await service.persistSubscriptionResponse({
        'registerSubscriberResponse': {
          'statusDescription': 'Successfully: deviceTransferred',
          'appId': 3,
          'fromSubscriberId': '66f1',
          'toSubscriberId': '671a',
        },
      });

      expect(InngageProperties.subscriberId, '671a');
      expect(store.subscriberId, '671a');
    });

    test('keeps the last subscriberId when the response has none', () async {
      InngageProperties.subscriberId = 'previous';
      store.subscriberId = 'previous';

      await service.persistSubscriptionResponse({
        'registerSubscriberResponse': {'appId': 3},
      });

      expect(InngageProperties.subscriberId, 'previous');
      expect(store.subscriberId, 'previous');
      expect(store.appId, 3);
    });

    test('does not write the store without a registration token', () async {
      InngageProperties.registration = '';

      await service.persistSubscriptionResponse({
        'registerSubscriberResponse': {'appId': 3, 'subscriberId': '671a'},
      });

      expect(store.saves, 0);
      // The subscriber id is still useful without a device.
      expect(InngageProperties.subscriberId, '671a');
    });

    test('leaves everything untouched on a null response', () async {
      await service.persistSubscriptionResponse(null);

      expect(store.saves, 0);
      expect(InngageProperties.subscriberId, '');
    });
  });

  group('addCustomField — validation', () {
    test('rejects an empty customField without calling the API', () async {
      final ok = await service.addCustomField(
        identifier: 'maria@exemplo.com',
        customField: const {},
      );

      expect(ok, isFalse);
      expect(subscriptionService.addCustomFieldRequests, isEmpty);
    });

    test('rejects a blank identifier without calling the API', () async {
      for (final identifier in ['', '   ']) {
        final ok = await service.addCustomField(
          identifier: identifier,
          customField: {'a': 1},
        );

        expect(ok, isFalse, reason: 'identifier "$identifier"');
      }
      expect(subscriptionService.addCustomFieldRequests, isEmpty);
    });

    test('never falls back to the configured (possibly anonymous) identifier',
        () async {
      InngageProperties.identifier = 'ce089bdd-3544-48f4-b436-b783387e7ad7';

      final ok = await service.addCustomField(
        identifier: '',
        customField: {'a': 1},
      );

      expect(ok, isFalse);
      expect(subscriptionService.addCustomFieldRequests, isEmpty);
      expect(
          InngageProperties.identifier, 'ce089bdd-3544-48f4-b436-b783387e7ad7');
    });

    test('rejects a missing appToken without calling the API', () async {
      InngageProperties.appToken = '';

      final ok = await service.addCustomField(
        identifier: 'maria@exemplo.com',
        customField: {'a': 1},
      );

      expect(ok, isFalse);
      expect(subscriptionService.addCustomFieldRequests, isEmpty);
    });
  });

  group('addCustomField — request contents', () {
    test('builds the request from the arguments and the configured properties',
        () async {
      subscriptionService.addCustomFieldResponse = {'status': '1', 'appId': 3};

      await service.addCustomField(
        identifier: 'maria@exemplo.com',
        customField: {'plano': 'premium'},
      );

      final request = subscriptionService.addCustomFieldRequests.single;
      expect(request.appToken, 'token');
      expect(request.identifier, 'maria@exemplo.com');
      expect(request.registration, 'fcm-token');
      expect(request.customField, {'plano': 'premium'});
      expect(request.email, isNull);
      expect(request.phoneNumber, isNull);
      expect(request.identity, isNull);
    });

    test('trims the identifier and forwards contact and identity', () async {
      subscriptionService.addCustomFieldResponse = {'status': '1'};

      await service.addCustomField(
        identifier: '  joao@exemplo.com ',
        customField: {'plano': 'premium'},
        email: 'joao@exemplo.com',
        phoneNumber: '5511999998888',
        identity: {'vtex': '7a3c9f1e'},
      );

      final request = subscriptionService.addCustomFieldRequests.single;
      expect(request.identifier, 'joao@exemplo.com');
      expect(request.email, 'joao@exemplo.com');
      expect(request.phoneNumber, '5511999998888');
      expect(request.identity, {'vtex': '7a3c9f1e'});
    });

    test('omits the registration when none is known', () async {
      InngageProperties.registration = '';
      subscriptionService.addCustomFieldResponse = {'status': '1'};

      await service.addCustomField(
        identifier: 'maria@exemplo.com',
        customField: {'plano': 'premium'},
      );

      expect(subscriptionService.addCustomFieldRequests.single.registration,
          isNull);
    });
  });

  group('addCustomField — result handling', () {
    test('merges the fields and contact into the properties on success',
        () async {
      InngageProperties.customFields = {'nome': 'Maria', 'plano': 'free'};
      subscriptionService.addCustomFieldResponse = {'status': '1', 'appId': 3};

      final ok = await service.addCustomField(
        identifier: 'maria@exemplo.com',
        customField: {'plano': 'premium', 'pontos': 1250},
        email: 'maria@exemplo.com',
        phoneNumber: '5511999998888',
      );

      expect(ok, isTrue);
      expect(InngageProperties.customFields,
          {'nome': 'Maria', 'plano': 'premium', 'pontos': 1250});
      expect(InngageProperties.identifier, 'maria@exemplo.com');
      expect(InngageProperties.email, 'maria@exemplo.com');
      expect(InngageProperties.phoneNumber, '5511999998888');
    });

    test('replaces the anonymous identifier with the given one on success',
        () async {
      InngageProperties.identifier = 'ce089bdd-3544-48f4-b436-b783387e7ad7';
      subscriptionService.addCustomFieldResponse = {'status': '1'};

      await service.addCustomField(
        identifier: 'joao@exemplo.com',
        customField: {'plano': 'premium'},
      );

      expect(InngageProperties.identifier, 'joao@exemplo.com');
    });

    test('persists the appId from the response for the In-App flow', () async {
      subscriptionService.addCustomFieldResponse = {
        'status': '1',
        'message': 'Inserted identifier [maria@exemplo.com] in app [3]',
        'appId': 3,
      };

      await service.addCustomField(
        identifier: 'maria@exemplo.com',
        customField: {'plano': 'premium'},
      );

      expect(store.appId, 3);
      expect(store.registration, 'fcm-token');
    });

    test('returns false and changes nothing when delivery fails', () async {
      InngageProperties.customFields = {'nome': 'Maria'};
      subscriptionService.addCustomFieldResponse = null;

      final ok = await service.addCustomField(
        identifier: 'joao@exemplo.com',
        customField: {'plano': 'premium'},
        email: 'joao@exemplo.com',
      );

      expect(ok, isFalse);
      expect(InngageProperties.customFields, {'nome': 'Maria'});
      expect(InngageProperties.identifier, 'maria@exemplo.com');
      expect(InngageProperties.email, '');
      expect(store.saves, 0);
    });
  });
}
