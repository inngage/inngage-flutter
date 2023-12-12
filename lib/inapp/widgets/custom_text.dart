import 'package:flutter/material.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

class CustomText extends StatelessWidget {
  final String? text;
  final double? fontSize;
  final String? fontColor;
  final bool isBold;

  const CustomText({
    Key? key,
    this.text,
    this.fontSize,
    this.fontColor,
    this.isBold = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text ?? "",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize,
          color: HexColor.fromHex(fontColor ?? "#000"),
        ),
      ),
    );
  }
}
