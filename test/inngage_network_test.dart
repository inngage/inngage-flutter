import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inngage_plugin/data/api/inngage_network.dart';
import 'package:inngage_plugin/data/model/inngage/add_custom_field_request.dart';
import 'package:inngage_plugin/data/model/inngage/event_request.dart';
import 'package:inngage_plugin/data/model/inngage/subscription_request.dart';
import 'package:logger/logger.dart';

/// Records every request and answers with [statusCode]/[body].
class _Server {
  _Server({this.statusCode = 200, this.body = '{}'});

  int statusCode;
  String body;
  final List<http.Request> requests = [];

  late final MockClient client = MockClient((request) async {
    requests.add(request);
    return http.Response(body, statusCode);
  });

  http.Request get last => requests.single;
}

InngageNetwork _network(_Server server, {String keyAuthorization = ''}) {
  return InngageNetwork(
    logger: Logger(level: Level.off),
    client: server.client,
    keyAuthorization: keyAuthorization,
  );
}

SubscriptionRequest _subscription() => SubscriptionRequest(
      registerSubscriberRequest: RegisterSubscriberRequest(
        appToken: 'token',
        identifier: 'maria@exemplo.com',
        registration: 'fcm-token',
        platform: 'android',
      ),
    );

const _addCustomField = AddCustomFieldRequest(
  appToken: 'token',
  identifier: 'maria@exemplo.com',
  customField: {'plano': 'premium'},
);

void main() {
  group('subscription', () {
    test('POSTs the enveloped JSON body to /v4/subscription/ (trailing slash)',
        () async {
      final server = _Server(
        statusCode: 200,
        body: '{"registerSubscriberResponse":{"appId":3}}',
      );

      await _network(server).subscription(_subscription());

      final request = server.last;
      expect(request.method, 'POST');
      expect(request.url.toString(),
          'https://api.inngage.com.br/v4/subscription/');
      expect(request.headers['Content-Type'],
          startsWith('application/json; charset=UTF-8'));
      expect(jsonDecode(request.body), {
        'registerSubscriberRequest': {
          'app_token': 'token',
          'identifier': 'maria@exemplo.com',
          'registration': 'fcm-token',
          'platform': 'android',
        },
      });
    });

    test('treats 201 Created (new subscriber) as success', () async {
      final server = _Server(
        statusCode: 201,
        body: '{"registerSubscriberResponse":'
            '{"statusDescription":"Successfully: subscriberCreated",'
            '"subscriberId":"671a","appId":3}}',
      );

      final response = await _network(server).subscription(_subscription());

      expect(response, isNotNull);
      expect(response!['registerSubscriberResponse']['appId'], 3);
    });

    test('returns null on 4xx/5xx without throwing', () async {
      for (final status in [400, 401, 500]) {
        final server = _Server(
          statusCode: status,
          body: '{"registerSubscriberResponse":'
              '{"statusDescription":"app_token is invalid or expired."}}',
        );

        final response = await _network(server).subscription(_subscription());

        expect(response, isNull, reason: 'status $status');
      }
    });

    test('returns null when the client throws', () async {
      final network = InngageNetwork(
        logger: Logger(level: Level.off),
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      expect(await network.subscription(_subscription()), isNull);
    });

    test('wraps a non-JSON 2xx body under rawBodyKey', () async {
      final server = _Server(statusCode: 200, body: 'ok app_id=5');

      final response = await _network(server).subscription(_subscription());

      expect(response, {InngageNetwork.rawBodyKey: 'ok app_id=5'});
    });

    test('sends the Authorization header only when a key is configured',
        () async {
      final withKey = _Server();
      await _network(withKey, keyAuthorization: 'abc')
          .subscription(_subscription());
      expect(withKey.last.headers['Authorization'], 'key=abc');

      final withoutKey = _Server();
      await _network(withoutKey).subscription(_subscription());
      expect(withoutKey.last.headers, isNot(contains('Authorization')));
    });
  });

  group('addCustomField', () {
    test('POSTs the fieldsRequest envelope to /v4/subscription/addCustomField',
        () async {
      final server = _Server(
        statusCode: 200,
        body: '{"status":"1","message":"Updated","appId":3}',
      );

      final response = await _network(server).addCustomField(_addCustomField);

      final request = server.last;
      expect(request.method, 'POST');
      expect(request.url.toString(),
          'https://api.inngage.com.br/v4/subscription/addCustomField');
      expect(jsonDecode(request.body), {
        'fieldsRequest': {
          'app_token': 'token',
          'identifier': 'maria@exemplo.com',
          'custom_field': {'plano': 'premium'},
        },
      });
      expect(response, {'status': '1', 'message': 'Updated', 'appId': 3});
    });

    test('returns null on a 400 validation error', () async {
      final server = _Server(
        statusCode: 400,
        body: '{"status":"0","message":"custom_field is required and must be '
            'a non-empty object."}',
      );

      expect(await _network(server).addCustomField(_addCustomField), isNull);
    });
  });

  group('legacy endpoints', () {
    test('events still go through the version parameter (v1)', () async {
      final server = _Server();

      final ok = await _network(server).sendEvent(Event(
        newEventRequest: NewEventRequest(
          appToken: 'token',
          identifier: 'maria@exemplo.com',
          registration: 'fcm-token',
          eventName: 'login',
          eventValues: const {},
          conversionEvent: false,
          conversionNotId: '',
          conversionValue: 0,
        ),
      ));

      expect(ok, isTrue);
      expect(server.last.url.toString(),
          'https://api.inngage.com.br/v1/events/newEvent/');
    });
  });

  group('isSuccess', () {
    test('accepts the whole 2xx range only', () {
      expect(InngageNetwork.isSuccess(200), isTrue);
      expect(InngageNetwork.isSuccess(201), isTrue);
      expect(InngageNetwork.isSuccess(204), isTrue);
      expect(InngageNetwork.isSuccess(299), isTrue);
      expect(InngageNetwork.isSuccess(199), isFalse);
      expect(InngageNetwork.isSuccess(300), isFalse);
      expect(InngageNetwork.isSuccess(400), isFalse);
      expect(InngageNetwork.isSuccess(500), isFalse);
    });
  });
}
