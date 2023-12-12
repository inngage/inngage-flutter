import 'package:flutter/material.dart';
import 'package:inngage_plugin/inapp/dialogs/dialog_poster.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

// ignore: must_be_immutable
class InAppDialog extends StatelessWidget {
  InAppModel inAppModel;

  InAppDialog({Key? key, required this.inAppModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        child: Stack(
          alignment: Alignment.center,
          children: [
            DialogPoster(
              inAppModel: inAppModel,
            )
          ],
        ),
      ),
    );
  }
}
