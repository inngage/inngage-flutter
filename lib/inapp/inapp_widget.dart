import 'package:flutter/material.dart';
import 'inngage_inapp.dart';

class InngageInAppWidget extends StatefulWidget {
  final Widget child;
   const InngageInAppWidget({super.key, required this.child});

  @override
  State<InngageInAppWidget> createState() => _InngageInAppWidgetState();
}

class _InngageInAppWidgetState extends State<InngageInAppWidget> with WidgetsBindingObserver {
  
  
   @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
          InngageInapp.show();
       
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
      InngageInapp.show();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}