import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inngage_plugin/inapp/inapp_actions.dart';
import 'package:inngage_plugin/inapp/widgets/inapp_v2_card.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final storage = const FlutterSecureStorage();

  /// Renders the "Wheel" (roleta) demand JSON locally: lead capture before
  /// the spin, weighted draw, and the win/lose result panel with coupon.
  void _showWheelDemo(BuildContext context) {
    final message = InAppMessageV2.fromJson({
      'type': 'Wheel',
      'icon': 'https://storage.googleapis.com/inn-app-icons/380.png',
      'hideBrand': false,
      'style': {
        'position': 'center',
        'backgroundColor': '#ffffff',
        'backgroundImage': null,
        'borderColor': '#e5e7eb',
        'shadow': true,
        'titleColor': '#111827',
        'bodyColor': '#4B5563',
      },
      'content': {
        'title': 'Gire a roleta da sorte',
        'body': 'Um giro por visita. Boa sorte!',
      },
      'leadCapture': {
        'enabled': true,
        'position': 'before',
        'fields': [
          {'type': 'email', 'label': 'Seu e-mail'}
        ],
        'button': {
          'text': 'Liberar meu giro',
          'style': {
            'backgroundColor': '#7C3AED',
            'textColor': '#FFFFFF',
            'hoverColor': '#6D28D9',
          },
        },
        'consentText':
            'Ao continuar você concorda com nossos Termos & Condições.',
        'consentColor': '#9CA3AF',
        'unlockText': 'Cadastre-se para liberar seu cupom 🎁',
      },
      'wheel': {
        'buttonText': 'Girar 🎡',
        'button': {'backgroundColor': '#7C3AED', 'textColor': '#FFFFFF'},
        'slices': [
          {
            'label': '10% OFF',
            'color': '#7C3AED',
            'code': 'GIRO10',
            'weight': 3
          },
          {
            'label': 'Frete grátis',
            'color': '#F59E0B',
            'code': 'FRETE0',
            'weight': 2
          },
          {'label': 'Quase!', 'color': '#9CA3AF', 'code': null, 'weight': 4},
          {
            'label': '25% OFF',
            'color': '#10B981',
            'code': 'GIRO25',
            'weight': 1
          },
        ],
      },
      'result': {
        'winTitle': 'Parabéns! 🎉',
        'loseTitle': 'Foi por pouco!',
        'body': 'Apresente o cupom no checkout.',
        'winEmoji': '🎁',
        'loseEmoji': '🙂',
        'style': {
          'gradient': false,
          'bgFrom': '#FFFFFF',
          'bgTo': '#F5F3FF',
          'textColor': '#111827',
        },
      },
    });

    showDialog(
      context: context,
      builder: (_) => InAppV2Card(
        message: message,
        onActionTriggered: (_) {},
        onLeadCaptured: (lead) => debugPrint('Wheel lead: $lead'),
        onWheelResult: (slice) => debugPrint(
            'Wheel result: ${slice.label} win=${slice.isWin} code=${slice.code}'),
      ),
    );
  }

  /// Renders a locally-built In-App v2 message so every click behavior
  /// (weblink, in_app_url, deeplink, metadata, dismiss) and the carousel can
  /// be exercised without depending on a backend campaign.
  void _showLocalDemo(BuildContext context) {
    final message = InAppMessageV2.fromJson({
      'type': 'Banner',
      'style': {
        'position': 'center',
        'backgroundColor': '#FFFFFF',
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
            'image': 'https://picsum.photos/seed/inngage1/600/300',
            'content': {
              'title': 'Slide 1 — navegação',
              'body': 'weblink abre o navegador externo; '
                  'in_app_url abre o navegador in-app.',
            },
            'actions': {
              'backgroundClick': {
                'type': 'deeplink',
                'url': 'https://flutter.dev',
              },
              'buttons': [
                {
                  'text': 'weblink',
                  'style': {'backgroundColor': '#0066FF'},
                  'action': {
                    'type': 'weblink',
                    'url': 'https://www.inngage.com.br',
                  },
                },
                {
                  'text': 'in_app_url',
                  'style': {'backgroundColor': '#16A34A'},
                  'action': {
                    'type': 'in_app_url',
                    'url': 'https://www.inngage.com.br',
                  },
                },
              ],
            },
          },
          {
            'image': 'https://picsum.photos/seed/inngage2/600/300',
            'content': {
              'title': 'Slide 2 — metadata e dismiss',
              'body': 'metadata entrega os pares ao app sem navegar; '
                  'dismiss apenas fecha.',
            },
            'actions': {
              'buttons': [
                {
                  'text': 'metadata',
                  'style': {'backgroundColor': '#9333EA'},
                  'action': {
                    'type': 'metadata',
                    'metadata': {'campaign': 'demo', 'priority': '1'},
                  },
                },
                {
                  'text': 'dismiss',
                  'style': {
                    'backgroundColor': '#EEEEEE',
                    'textColor': '#333333',
                  },
                  'action': {'type': 'dismiss'},
                },
              ],
            },
          },
        ],
      },
    });

    showDialog(
      context: context,
      builder: (_) => InAppV2Card(
        message: message,
        onActionTriggered: (action) {
          debugPrint('Demo action: ${action.type} url=${action.url} '
              'metadata=${action.metadata}');
          InngageInAppActions.execute(
            action,
            handledBySdk: true,
            onMetadata: (metadata) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('metadata recebido: $metadata')),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final conversionNotId =
                    await storage.read(key: 'conversionNotId');
                final result = await InngageEvent.sendEvent(
                  eventName: 'click me',
                  appToken: InngageProperties.appToken,
                  identifier: InngageProperties.identifier,
                  conversionEvent: true,
                  conversionNotId: conversionNotId ?? '',
                );

                if (!context.mounted) return;

                final snackBar = result
                    ? const SnackBar(
                        content: Text('Evento enviado com successo'),
                        backgroundColor: Colors.green,
                      )
                    : const SnackBar(
                        content: Text('Houve um erro tente novamente'),
                        backgroundColor: Colors.red,
                      );

                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              child: const Text('Enviar evento'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Fetches /objectMessage and renders the returned In-App
                // message; renders nothing when there is none. Requires the
                // subscription to have completed at least once.
                InngageInApp.show(
                  context: context,
                  onMetadata: (metadata) {
                    debugPrint('In-App metadata: $metadata');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('metadata recebido: $metadata')),
                    );
                  },
                );
              },
              child: const Text('Exibir In-App Message'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showLocalDemo(context),
              child: const Text('Demo local (todas as ações)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showWheelDemo(context),
              child: const Text('Demo Roleta (Wheel)'),
            ),
          ],
        ),
      ),
    );
  }
}
