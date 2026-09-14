[![pub package](https://img.shields.io/pub/v/permission_handler.svg)](https://pub.dev/packages/inngage_plugin) 

# inngage_plugin

This SDK inf lutter aims to enable integration with the [Inngage](https://www.inngage.com.br)  platform

## Add the plugin to your project

* Open the **pubspec.yaml**
* add to the dependencies section


[Access here](https://inngage.readme.io/v1.0/docs/integração-flutter) to see the official documentation on the inngage website

```yaml
inngage_plugin:3.2.0
```


## How to use

```dart
 final json = {
      "nome": "User 01",
      "dt_nascimento": "01/09/1970",
      "genero": "M",
      "cartao": "N",
      "ultimo_abastecimento": "10/09/2018",
      "total_abastecido": "290,00"
    };

    final inngageWebViewProperties = InngageWebViewProperties(
      appBarColor: Colors.pink,
      appBarText: Text(
        'AppTitle',
      ),
      backgroundColor: Colors.white,
      loaderColor: Colors.pink,
      debuggingEnabled: true,
      withJavascript: true,
      withLocalStorage: true,
      withZoom: true,
    );
    await InngageSDK.subscribe(
      appToken: 'appToken',
      friendlyIdentifier: 'user@gmail.com',
      customFields: json,
      phoneNumber: 'phoneNumber',
      email: 'user@gmail.com',
      blockDeepLink:true,
      firebaseListenCallback: (data) => print(data['additional_data']),
      navigatorKey: navigatorKey,
      inngageWebViewProperties: inngageWebViewProperties,
      requestAdvertiserId: false,
      requestGeoLocator: false,
    );
     Future.delayed(const Duration(seconds: 5)).then((value){
      InngageNotificationMessage.subscribe();
    });
    InngageEvent.setDebugMode(true);
    InngageEvent.setUserPhone("phoneNumber");
    await InngageEvent.sendEvent(
      eventName: 'MyOtherEventWithoutEventValues',
      appToken: 'appToken',
      identifier: 'user@gmail.com',
      eventValues: {
        'location': '12312312312',
      },
    );
    await InngageEvent.sendEvent(
      eventName: 'send_test',
      appToken: 'appToken',
      identifier: 'user@gmail.com',
    );

  var localNotification = InngageNotificationMessage.flutterLocalNotificationsPlugin;
```

Call `subscribe()` on a `InngageSDK` to request it.

## In-App Messages

Since 4.0.0 In-App messages no longer arrive through push payloads. The SDK
fetches them on demand from the Inngage API (`/v4/message/objectMessage`) when
your app asks for one — for example after the splash screen, on the login
screen, or on any specific route:

```dart
await InngageInApp.show(
  context: context, // optional: defaults to the navigatorKey passed to subscribe
  handledBySdk: true, // SDK executes deep links / browser / in-app browser
  onMetadata: (metadata) {
    // "metadata" actions deliver key-value pairs to the app, with no navigation
  },
);
```

If there is no In-App message to display, nothing is rendered and the call
returns silently.

> **Important:** the In-App flow depends on the `app_id` and the device
> registration token persisted from the subscription. Make sure
> `InngageSDK.subscribe` + the subscriber registration have completed at least
> once before calling `InngageInApp.show`.

To handle every action yourself instead of letting the SDK navigate, pass
`handledBySdk: false` and an `onAction` callback receiving the `InAppV2Action`.

### Scratch (raspadinha)

Campaigns with `type: "Scratch"` render a scratch card: the weighted draw
happens before the cover is shown, so the revealed prize is already the
result. Scratching past `revealPercent` completes the reveal and shows the
win/lose panel with a copy-to-clipboard coupon. The drawn prize is delivered
to the app via `onScratchResult` — nothing is sent to the API.

### Wheel (roleta)

Campaigns with `type: "Wheel"` render a fortune wheel: an optional
lead-capture form (before or after the spin), a weighted draw that happens
before the animation, and a win/lose result panel with a copy-to-clipboard
coupon. The SDK delivers the captured lead and the drawn slice to the app —
nothing is sent to the API:

```dart
await InngageInApp.show(
  context: context,
  onLeadCaptured: (lead) => print('lead: $lead'),        // {label: value}
  onWheelResult: (slice) => print('${slice.label} win=${slice.isWin}'),
);
```
