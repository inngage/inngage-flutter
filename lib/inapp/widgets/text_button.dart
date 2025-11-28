import 'package:flutter/material.dart';
import 'package:inngage_plugin/inapp/inapp_actions.dart';
import 'package:inngage_plugin/util/hexcolor.dart';

class CustomTextButton extends StatelessWidget {
  final String? text;
  final String? actionLink;
  final String? actionType;
  final String textColor;
  final String bgColor;

  const CustomTextButton({
    super.key,
    this.text,
    this.actionLink,
    this.actionType,
    this.textColor = "#000",
    this.bgColor = "#FFF",
  });

  @override
  Widget build(BuildContext context) {
    return text != null && text!.isNotEmpty
        ? Expanded(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (actionLink != null) {
                  InngageActions.executeAction(
                      type: actionType!, link: actionLink!);
                }
              },
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.all(HexColor.fromHex(bgColor)),
              ),
              child: Text(
                text!,
                style: TextStyle(
                  color: HexColor.fromHex(textColor),
                ),
              ),
            ),
          )
        : Container();
  }
}
