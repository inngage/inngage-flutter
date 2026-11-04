import 'package:flutter_test/flutter_test.dart';
import 'package:inngage_plugin/data/model/inapp/inapp_message_v2.dart';

void main() {
  group('InAppMessageV2.fromResponse — envelopes', () {
    final flatObject = {
      'type': 'Banner',
      'media': {
        'enabled': true,
        'items': [
          {
            'content': {'title': 'Olá'}
          }
        ]
      },
    };

    test('resolves the inAppMessage envelope', () {
      final message = InAppMessageV2.fromResponse({'inAppMessage': flatObject});
      expect(message, isNotNull);
      expect(message!.media.items.single.content.title, 'Olá');
    });

    test('resolves the legacy payload envelope', () {
      final message = InAppMessageV2.fromResponse({'payload': flatObject});
      expect(message, isNotNull);
      expect(message!.type, 'Banner');
    });

    test('resolves the flat production format', () {
      final message = InAppMessageV2.fromResponse(flatObject);
      expect(message, isNotNull);
      expect(message!.type, 'Banner');
    });

    test('returns null for a null response', () {
      expect(InAppMessageV2.fromResponse(null), isNull);
    });
  });

  group('InAppMessageV2.fromResponse — suppression', () {
    test('returns null when enabled is false', () {
      final message = InAppMessageV2.fromResponse({
        'enabled': false,
        'type': 'Banner',
        'media': {'items': []},
      });
      expect(message, isNull);
    });

    test('returns null when there is neither media nor type', () {
      expect(InAppMessageV2.fromResponse({'foo': 'bar'}), isNull);
    });

    test('keeps the message when only type is present', () {
      expect(InAppMessageV2.fromResponse({'type': 'Banner'}), isNotNull);
    });

    test('keeps the message when only media is present', () {
      expect(InAppMessageV2.fromResponse({'media': {}}), isNotNull);
    });
  });

  group('InAppMessageV2 defaults', () {
    test('applies root/style/media defaults for absent fields', () {
      final message = InAppMessageV2.fromResponse({'type': 'Message'})!;

      expect(message.enabled, isTrue);
      expect(message.type, 'Message');

      expect(message.style.position, 'center');
      expect(message.style.backgroundColor, '');
      expect(message.style.backgroundImage, isNull);
      expect(message.style.borderColor, '');
      expect(message.style.shadow, isFalse);
      expect(message.style.titleColor, '#000000');
      expect(message.style.bodyColor, '#000000');

      expect(message.media.enabled, isFalse);
      expect(message.media.position, 'TOP');
      expect(message.media.items, isEmpty);
    });

    test('applies item/button defaults for absent fields', () {
      final message = InAppMessageV2.fromResponse({
        'type': 'Banner',
        'media': {
          'items': [
            {
              'actions': {
                'buttons': [
                  {'text': 'Ok'}
                ]
              }
            }
          ]
        },
      })!;

      final item = message.media.items.single;
      expect(item.image, '');
      expect(item.imageType, 'fill');
      expect(item.content.title, '');
      expect(item.content.body, '');
      expect(item.actions.backgroundClick, isNull);

      final button = item.actions.buttons.single;
      expect(button.style.backgroundColor, '#000000');
      expect(button.style.textColor, '#FFFFFF');
      expect(button.style.hoverColor, '');
      expect(button.action, isNull);
    });
  });

  group('InAppV2Media — carousel compatibility', () {
    test('reads items/position/enabled nested in media.carousel', () {
      final media = InAppV2Media.fromJson({
        'carousel': {
          'enabled': true,
          'position': 'BOTTOM',
          'items': [
            {'image': 'https://cdn/img.png'}
          ],
        }
      });

      expect(media.enabled, isTrue);
      expect(media.position, 'BOTTOM');
      expect(media.items.single.image, 'https://cdn/img.png');
    });

    test('prefers top-level fields over media.carousel', () {
      final media = InAppV2Media.fromJson({
        'position': 'TOP',
        'items': [
          {'image': 'top-level.png'}
        ],
        'carousel': {
          'position': 'BOTTOM',
          'items': [
            {'image': 'nested.png'}
          ],
        },
      });

      expect(media.position, 'TOP');
      expect(media.items.single.image, 'top-level.png');
    });
  });

  group('InAppV2ActionType.parse', () {
    test('maps every documented value, case-insensitively', () {
      expect(InAppV2ActionType.parse('deeplink'), InAppV2ActionType.deepLink);
      expect(InAppV2ActionType.parse('deep_link'), InAppV2ActionType.deepLink);
      expect(InAppV2ActionType.parse('DEEP_LINK'), InAppV2ActionType.deepLink);
      expect(InAppV2ActionType.parse('weblink'), InAppV2ActionType.weblink);
      expect(InAppV2ActionType.parse('in_app_url'), InAppV2ActionType.inAppUrl);
      expect(InAppV2ActionType.parse('inapp'), InAppV2ActionType.inAppUrl);
      expect(InAppV2ActionType.parse('metadata'), InAppV2ActionType.metadata);
      expect(InAppV2ActionType.parse('dismiss'), InAppV2ActionType.dismiss);
    });

    test('unknown or absent values fall back to dismiss', () {
      expect(InAppV2ActionType.parse('whatever'), InAppV2ActionType.dismiss);
      expect(InAppV2ActionType.parse(''), InAppV2ActionType.dismiss);
      expect(InAppV2ActionType.parse(null), InAppV2ActionType.dismiss);
    });
  });

  group('InAppV2Action.fromJson', () {
    test('coerces metadata values to strings', () {
      final action = InAppV2Action.fromJson({
        'type': 'metadata',
        'metadata': {'campaign': 'promo', 'priority': 2, 'flag': null},
      });

      expect(action.type, InAppV2ActionType.metadata);
      expect(
          action.metadata, {'campaign': 'promo', 'priority': '2', 'flag': ''});
    });
  });

  group('hasRenderableContent', () {
    test('false when type is empty', () {
      final message = InAppMessageV2.fromResponse({
        'type': '',
        'media': {
          'items': [
            {
              'content': {'title': 'Olá'}
            }
          ]
        },
      })!;
      expect(message.hasRenderableContent, isFalse);
    });

    test('false when no slide has content and there is no background image',
        () {
      final message = InAppMessageV2.fromResponse({
        'type': 'Banner',
        'media': {
          'items': [
            {'image': ''}
          ]
        },
      })!;
      expect(message.hasRenderableContent, isFalse);
    });

    test('true with a slide that only has a body', () {
      final message = InAppMessageV2.fromResponse({
        'type': 'Banner',
        'media': {
          'items': [
            {
              'content': {'body': 'texto'}
            }
          ]
        },
      })!;
      expect(message.hasRenderableContent, isTrue);
    });

    test('true with only a style background image', () {
      final message = InAppMessageV2.fromResponse({
        'type': 'Banner',
        'style': {'backgroundImage': 'https://cdn/bg.png'},
        'media': {'items': []},
      })!;
      expect(message.hasRenderableContent, isTrue);
    });
  });

  group('notId', () {
    test('parses notId (production) and not_id (fallback)', () {
      expect(
        InAppMessageV2.fromJson({'type': 'Banner', 'notId': 'abc123'}).notId,
        'abc123',
      );
      expect(
        InAppMessageV2.fromJson({'type': 'Banner', 'not_id': 'abc123'}).notId,
        'abc123',
      );
    });

    test('defaults to empty when absent', () {
      expect(InAppMessageV2.fromJson({'type': 'Banner'}).notId, '');
    });
  });

  test('parses the full production example from the contract', () {
    final message = InAppMessageV2.fromResponse({
      'type': 'Banner',
      'enabled': true,
      'style': {
        'position': 'center',
        'backgroundColor': '#FFFFFF',
        'backgroundImage': null,
        'borderColor': '#E0E0E0',
        'shadow': true,
        'titleColor': '#111111',
        'bodyColor': '#444444',
      },
      'media': {
        'enabled': true,
        'position': 'TOP',
        'items': [
          {
            'image': 'https://cdn.inngage.com.br/inapp/promo.png',
            'imageType': 'fill',
            'content': {
              'title': 'Bem-vindo!',
              'body': 'Aproveite 20% de desconto na sua primeira compra.',
            },
            'actions': {
              'backgroundClick': {
                'type': 'deeplink',
                'url': 'myapp://home',
                'metadata': {},
              },
              'buttons': [
                {
                  'text': 'Ver ofertas',
                  'style': {
                    'backgroundColor': '#0066FF',
                    'textColor': '#FFFFFF',
                    'hoverColor': '#0052CC',
                  },
                  'action': {
                    'type': 'in_app_url',
                    'url': 'https://loja.exemplo.com/ofertas',
                    'metadata': {},
                  },
                },
                {
                  'text': 'Agora não',
                  'style': {
                    'backgroundColor': '#EEEEEE',
                    'textColor': '#333333',
                    'hoverColor': '',
                  },
                  'action': {'type': 'dismiss', 'url': '', 'metadata': {}},
                },
              ],
            },
          }
        ],
      },
    });

    expect(message, isNotNull);
    expect(message!.hasRenderableContent, isTrue);
    expect(message.style.shadow, isTrue);

    final item = message.media.items.single;
    expect(item.actions.backgroundClick!.type, InAppV2ActionType.deepLink);
    expect(item.actions.backgroundClick!.url, 'myapp://home');
    expect(item.actions.buttons, hasLength(2));
    expect(item.actions.buttons.first.action!.type, InAppV2ActionType.inAppUrl);
    expect(item.actions.buttons.last.action!.type, InAppV2ActionType.dismiss);
  });
}
