import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inngage/subscription_request.dart';

void main() {
  group('RegisterSubscriberRequest.toJson', () {
    test('serializes the v4 field names', () {
      final json = RegisterSubscriberRequest(
        appToken: 'token',
        identifier: 'maria@exemplo.com',
        registration: 'fcm-token',
        platform: 'android',
        sdk: '4.1.0',
        deviceModel: 'SM-S918B',
        deviceManufacturer: 'samsung',
        osName: 'Android',
        osVersion: '14',
        osLanguage: 'pt',
        osLocale: 'pt_BR',
        appVersion: '3.12.1',
        appInstalledIn: DateTime.utc(2026, 10, 1, 14, 3),
        appUpdatedIn: DateTime.utc(2026, 10, 20, 9, 10),
        uuid: 'device-uuid',
        attributionId: 'attr',
        customField: {'nome': 'Maria', 'vip': true},
        phoneNumber: '5511999998888',
        email: 'maria@exemplo.com',
        lat: '-23.5505',
        long: '-46.6333',
        advertiserId: 'gaid',
        optIn: '1',
      ).toJson();

      expect(json['app_token'], 'token');
      expect(json['identifier'], 'maria@exemplo.com');
      expect(json['registration'], 'fcm-token');
      expect(json['platform'], 'android');
      expect(json['sdk'], '4.1.0');
      expect(json['device_model'], 'SM-S918B');
      expect(json['device_manufacturer'], 'samsung');
      expect(json['os_name'], 'Android');
      expect(json['os_version'], '14');
      expect(json['os_language'], 'pt');
      expect(json['os_locale'], 'pt_BR');
      expect(json['app_version'], '3.12.1');
      expect(json['app_installed_in'], '2026-10-01T14:03:00.000Z');
      expect(json['app_updated_in'], '2026-10-20T09:10:00.000Z');
      expect(json['uuid'], 'device-uuid');
      expect(json['attribution_id'], 'attr');
      expect(json['custom_field'], {'nome': 'Maria', 'vip': true});
      expect(json['phone_number'], '5511999998888');
      expect(json, isNot(contains('phone')));
      expect(json['email'], 'maria@exemplo.com');
      expect(json['lat'], '-23.5505');
      expect(json['long'], '-46.6333');
      expect(json['opt_in'], '1');
    });

    test('omits absent values instead of sending null', () {
      final json = RegisterSubscriberRequest(
        appToken: 'token',
        registration: 'fcm-token',
        platform: 'android',
      ).toJson();

      expect(json.keys, containsAll(['app_token', 'registration', 'platform']));
      expect(json, isNot(contains('identifier')));
      expect(json, isNot(contains('email')));
      expect(json, isNot(contains('phone_number')));
      expect(json, isNot(contains('opt_in')));
      expect(json, isNot(contains('app_installed_in')));
      expect(json.values, isNot(contains(null)));
    });

    test('treats blank, "null" and "undefined" strings as absent', () {
      final json = RegisterSubscriberRequest(
        appToken: 'token',
        registration: 'fcm-token',
        identifier: '   ',
        email: 'null',
        phoneNumber: 'undefined',
        lat: '',
        customField: const {},
      ).toJson();

      expect(json, isNot(contains('identifier')));
      expect(json, isNot(contains('email')));
      expect(json, isNot(contains('phone_number')));
      expect(json, isNot(contains('lat')));
      expect(json, isNot(contains('custom_field')));
    });

    test('keeps opt_in "0" (a push opt-out must reach the API)', () {
      final json = RegisterSubscriberRequest(
        appToken: 'token',
        registration: 'fcm-token',
        optIn: '0',
      ).toJson();

      expect(json['opt_in'], '0');
    });
  });

  group('SubscriptionRequest', () {
    test('envelopes the body in registerSubscriberRequest', () {
      final encoded = subscriptionToJson(SubscriptionRequest(
        registerSubscriberRequest: RegisterSubscriberRequest(
          appToken: 'token',
          identifier: 'maria@exemplo.com',
        ),
      ));

      final decoded = json.decode(encoded) as Map<String, dynamic>;
      expect(decoded.keys, ['registerSubscriberRequest']);
      expect(decoded['registerSubscriberRequest'], {
        'app_token': 'token',
        'identifier': 'maria@exemplo.com',
      });
    });
  });

  group('isAbsentValue', () {
    test('matches the v4 "absent" rules', () {
      expect(isAbsentValue(null), isTrue);
      expect(isAbsentValue(''), isTrue);
      expect(isAbsentValue('  '), isTrue);
      expect(isAbsentValue('null'), isTrue);
      expect(isAbsentValue('undefined'), isTrue);
      expect(isAbsentValue(const <String, dynamic>{}), isTrue);

      expect(isAbsentValue('0'), isFalse);
      expect(isAbsentValue(0), isFalse);
      expect(isAbsentValue(false), isFalse);
      expect(isAbsentValue({'a': 1}), isFalse);
    });
  });
}
