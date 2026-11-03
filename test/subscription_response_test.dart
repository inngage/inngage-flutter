import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/api/inngage_network.dart';
import 'package:inngage_plugin/data/model/inngage/subscription_response.dart';

void main() {
  group('SubscriptionResponse.fromJson — /v4/subscription/', () {
    test('parses the 201 subscriberCreated envelope', () {
      final response = SubscriptionResponse.fromJson({
        'registerSubscriberResponse': {
          'statusDescription': 'Successfully: subscriberCreated',
          'subscriberId': '671a0c2e9b1f4a3d8c5e7f10',
          'appId': 3,
        },
      });

      expect(response.statusDescription, 'Successfully: subscriberCreated');
      expect(response.subscriberId, '671a0c2e9b1f4a3d8c5e7f10');
      expect(response.appId, 3);
      expect(response.fromSubscriberId, isNull);
      expect(response.toSubscriberId, isNull);
    });

    test('falls back to toSubscriberId on deviceTransferred', () {
      final response = SubscriptionResponse.fromJson({
        'registerSubscriberResponse': {
          'statusDescription': 'Successfully: deviceTransferred',
          'appId': 3,
          'fromSubscriberId': '66f1a1',
          'toSubscriberId': '671a10',
        },
      });

      expect(response.subscriberId, '671a10');
      expect(response.fromSubscriberId, '66f1a1');
      expect(response.toSubscriberId, '671a10');
      expect(response.appId, 3);
    });

    test('accepts appId serialized as a string', () {
      final response = SubscriptionResponse.fromJson({
        'registerSubscriberResponse': {'appId': '42', 'subscriberId': 7},
      });

      expect(response.appId, 42);
      expect(response.subscriberId, '7');
    });

    test('is empty for null or unrelated bodies', () {
      expect(SubscriptionResponse.fromJson(null).appId, isNull);
      expect(SubscriptionResponse.fromJson(null).subscriberId, isNull);

      final unrelated = SubscriptionResponse.fromJson({'status': 'ok'});
      expect(unrelated.appId, isNull);
      expect(unrelated.subscriberId, isNull);
      expect(unrelated.statusDescription, isNull);
    });
  });

  group('SubscriptionResponse.fromJson — /addCustomField', () {
    test('reads appId and message from the root', () {
      final response = SubscriptionResponse.fromJson({
        'status': '1',
        'message': 'Updated identifier [maria@exemplo.com] in app [3]',
        'appId': 3,
      });

      expect(response.appId, 3);
      expect(response.statusDescription,
          'Updated identifier [maria@exemplo.com] in app [3]');
      expect(response.subscriberId, isNull);
    });
  });

  group('SubscriptionResponse.extractAppId', () {
    test('reads app_id / appId as int or numeric string', () {
      expect(SubscriptionResponse.extractAppId({'app_id': 42}), 42);
      expect(SubscriptionResponse.extractAppId({'app_id': '42'}), 42);
      expect(SubscriptionResponse.extractAppId({'appId': 42}), 42);
      expect(SubscriptionResponse.extractAppId({'appId': '42'}), 42);
    });

    test('searches nested objects', () {
      expect(
        SubscriptionResponse.extractAppId({
          'data': {'app_id': 7}
        }),
        7,
      );
    });

    test('falls back to a plain-text body', () {
      expect(
        SubscriptionResponse.extractAppId(
            {InngageNetwork.rawBodyKey: 'ok app_id=99'}),
        99,
      );
    });

    test('returns null when absent', () {
      expect(SubscriptionResponse.extractAppId({'status': 'ok'}), isNull);
      expect(SubscriptionResponse.extractAppId(null), isNull);
    });
  });
}
