import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inngage/add_custom_field_request.dart';

void main() {
  group('AddCustomFieldRequest.toJson', () {
    test('envelopes everything in fieldsRequest with the v4 field names', () {
      final json = const AddCustomFieldRequest(
        appToken: 'token',
        identifier: 'maria@exemplo.com',
        customField: {'plano': 'premium', 'pontos': 1250},
        email: 'maria@exemplo.com',
        phoneNumber: '5511999998888',
        identity: {'vtex': '7a3c9f1e', 'shopify': '123'},
        registration: 'fcm-token',
      ).toJson();

      expect(json.keys, ['fieldsRequest']);
      expect(json['fieldsRequest'], {
        'app_token': 'token',
        'identifier': 'maria@exemplo.com',
        'custom_field': {'plano': 'premium', 'pontos': 1250},
        'email': 'maria@exemplo.com',
        'phone_number': '5511999998888',
        'identity': {'vtex': '7a3c9f1e', 'shopify': '123'},
        'registration': 'fcm-token',
      });
    });

    test('omits the optional keys that were not provided', () {
      final json = const AddCustomFieldRequest(
        appToken: 'token',
        identifier: 'maria@exemplo.com',
        customField: {'plano': 'premium'},
      ).toJson();

      expect(json['fieldsRequest'], {
        'app_token': 'token',
        'identifier': 'maria@exemplo.com',
        'custom_field': {'plano': 'premium'},
      });
    });

    test('encodes to a JSON string', () {
      final encoded = addCustomFieldRequestToJson(const AddCustomFieldRequest(
        appToken: 'token',
        identifier: 'maria@exemplo.com',
        customField: {'vip': true},
      ));

      expect(
        jsonDecode(encoded),
        {
          'fieldsRequest': {
            'app_token': 'token',
            'identifier': 'maria@exemplo.com',
            'custom_field': {'vip': true},
          }
        },
      );
    });
  });
}
