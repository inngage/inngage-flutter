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
    Key? key,
    this.text,
    this.actionLink,
    this.actionType,
    this.textColor = "#000",
    this.bgColor = "#FFF",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return text != null && text!.isNotEmpty
        ? Expanded(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (actionLink != null) {
                  InngageActions.executeAction(actionType!, actionLink!);
                }
              },
              child: Text(
                text!,
                style: TextStyle(
                  color: HexColor.fromHex(textColor),
                ),
              ),
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(HexColor.fromHex(bgColor)),
              ),
            ),
          )
        : Container();
  }
}
