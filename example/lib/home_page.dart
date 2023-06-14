import 'package:flutter/material.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
        child: ElevatedButton(
          onPressed: () async {
            try {
              final result = await InngageEvent.sendEvent(
                eventName: 'click me',
                appToken: '4d5c17ab9ae4ea7f5c989dc50c41bd7e',
                identifier: 'dass@asdsa.com',
                //identifier: 'appexample@gmail.com',
              );
              if (result) {
                const snackBar =  SnackBar(
                  content: Text('Evento enviado com successo'),
                  backgroundColor: Colors.green,
                );

                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            } on InngageException catch (_) {
              const snackBar =  SnackBar(
                content: Text('Houve um erro tente novamente'),
                backgroundColor: Colors.red,
              );

              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          },
          child: const Text('Enviar evento'),
        ),
      ),
    );
  }
}
