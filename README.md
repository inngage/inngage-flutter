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
