import 'package:flutter/material.dart';
import 'inngage_inapp.dart';

class InngageInAppWidget extends StatefulWidget {
  final Widget child;

  const InngageInAppWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<InngageInAppWidget> createState() => _InngageInAppWidgetState();
}

class _InngageInAppWidgetState extends State<InngageInAppWidget>
    with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        InngageInApp.show();
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(seconds: 2)).then((value) {
      InngageInApp.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
