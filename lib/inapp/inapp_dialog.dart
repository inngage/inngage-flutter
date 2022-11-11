import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:inngage_plugin/models/innapp_model.dart';
import 'package:inngage_plugin/models/inngage_web_view_properties_model.dart';
import 'package:inngage_plugin/util/hexcolor.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InAppDialog extends StatelessWidget {
  InAppModel inAppModel;
  InngageWebViewProperties inngageWebViewProperties;
  GlobalKey<NavigatorState> navigatorKey;
  InAppDialog(
      {Key? key,
      required this.inAppModel,
      required this.inngageWebViewProperties,
      required this.navigatorKey})
      : super(key: key);
  static GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  static InngageWebViewProperties _inngageWebViewProperties2 =
      InngageWebViewProperties();
  @override
  Widget build(BuildContext context) {
    _inngageWebViewProperties2 = inngageWebViewProperties;
    _navigatorKey = navigatorKey;
    return Center(
      child: SizedBox(
        child: Stack(
          alignment: Alignment.center,
          children: [
            alertDialog(context),
          ],
        ),
      ),
    );

    //alertDialog(context);
  }

/*  if (inAppModel.backgroundImg != null &&
                inAppModel.backgroundImg!.length > 5)
              Image.network(
                inAppModel.backgroundImg!,
                fit: BoxFit.cover,
              ), */
  AlertDialog alertDialog(BuildContext context) {
    var dots = 0;
    if (inAppModel.richContent!.img1 != null) dots++;
    if (inAppModel.richContent!.img2 != null) dots++;
    if (inAppModel.richContent!.img3 != null) dots++;

    return AlertDialog(
      backgroundColor: HexColor.fromHex(inAppModel.backgroundColor ?? "#FFF"),
      title: Text(
        inAppModel.title ?? "",
        textAlign: TextAlign.center,
        style: TextStyle(
            color: HexColor.fromHex(inAppModel.titleFontColor ?? "#000")),
      ),
      content: SizedBox(
        height: 310,
        child: Column(
          children: [
            inAppModel.richContent!.carousel!
                ? SizedBox(
                    height: 220,
                    width: 400,
                    child: ImageSlideshow(
                      width: 533,
                      height: 200,
                      initialPage: 0,

                      indicatorColor: dots < 2
                          ? Colors.transparent
                          : HexColor.fromHex(
                              inAppModel.backgroundColor ?? "#0000FF"),
                      indicatorBackgroundColor: Colors.grey,
                      children: [
                        if (inAppModel.richContent!.img1 != null)
                          Image.network(
                            inAppModel.richContent!.img1!,
                            fit: BoxFit.cover,
                          ),
                        if (inAppModel.richContent!.img2 != null)
                          Image.network(
                            inAppModel.richContent!.img2!,
                            fit: BoxFit.cover,
                          ),
                        if (inAppModel.richContent!.img3 != null)
                          Image.network(
                            inAppModel.richContent!.img3!,
                            fit: BoxFit.cover,
                          ),
                      ],

                      /// Called whenever the page in the center of the viewport changes.
                      onPageChanged: (value) {
                        debugPrint('Page changed: $value');
                      },

                      /// Auto scroll interval.
                      /// Do not auto scroll with null or 0.

                      /// Loops back to first slide.
                      isLoop: inAppModel.richContent!.img1 != null &&
                          inAppModel.richContent!.img2 != null &&
                          inAppModel.richContent!.img3 != null,
                    ),
                  )
                : Container(),
            const SizedBox(
              height: 25,
            ),
            Text(
              inAppModel.body ?? "",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: HexColor.fromHex(inAppModel.bodyFontColor ?? "#000")),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: inAppModel.btnLeftTxt == null || inAppModel.btnRightTxt == null
          ? [
              if (inAppModel.btnLeftTxt != null)
                Center(
                  child: TextButton(
                    child: Text(
                      inAppModel.btnLeftTxt ?? "",
                      style: TextStyle(
                          color: HexColor.fromHex(
                              inAppModel.btnLeftTxtColor ?? "#000")),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          HexColor.fromHex(
                              inAppModel.btnLeftBgColor ?? "#FFF")),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (inAppModel.btnLeftActionLink != null) {
                        _action(inAppModel.btnLeftActionType,
                            inAppModel.btnLeftActionLink);
                      }
                    },
                  ),
                ),
              if (inAppModel.btnRightTxt != null)
                Center(
                  child: TextButton(
                    child: Text(
                      inAppModel.btnRightTxt ?? "",
                      style: TextStyle(
                          color: HexColor.fromHex(
                              inAppModel.btnRightTxtColor ?? "#000")),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          HexColor.fromHex(
                              inAppModel.btnRightBgColor ?? "#FFF")),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (inAppModel.btnRightActionLink != null) {
                        _action(inAppModel.btnRightActionType,
                            inAppModel.btnRightActionLink);
                      }
                    },
                  ),
                ),
            ]
          : [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: TextButton(
                  child: Text(
                    inAppModel.btnLeftTxt ?? "",
                    style: TextStyle(
                        color: HexColor.fromHex(
                            inAppModel.btnLeftTxtColor ?? "#000")),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        HexColor.fromHex(inAppModel.btnLeftBgColor ?? "#FFF")),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (inAppModel.btnLeftActionLink != null) {
                      _action(inAppModel.btnLeftActionType,
                          inAppModel.btnLeftActionLink);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TextButton(
                  child: Text(
                    inAppModel.btnRightTxt ?? "",
                    style: TextStyle(
                        color: HexColor.fromHex(
                            inAppModel.btnRightTxtColor ?? "#000")),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        HexColor.fromHex(inAppModel.btnRightBgColor ?? "#FFF")),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (inAppModel.btnRightActionLink != null) {
                      _action(inAppModel.btnRightActionType,
                          inAppModel.btnRightActionLink);
                    }
                  },
                ),
              ),
            ],
    );
  }

  _action(type, link) {
    switch (type) {
      case "":
        break;
      case "deep":
        _deep(link);
        break;
      case "inapp":
        _web(link);
        break;
    }
  }

  _deep(link) async {
    final urlEncode = Uri.encodeFull(link);
    if (await canLaunch(urlEncode)) {
      await launch(urlEncode, forceWebView: false, forceSafariVC: false);
    } else {
      debugPrint( 'Could not launch $urlEncode');
    }
  }

  _web(link) {
    _showCustomNotification(
        url: link,
        titleNotification: inAppModel.title,
        messageNotification: inAppModel.body!);
  }

  static void _showCustomNotification({
    required String? titleNotification,
    required String messageNotification,
    required String url,
  }) async {
    final currentState = _navigatorKey.currentState;
    if (currentState != null) {
      currentState.push(
        MaterialPageRoute(
            builder: (context) => Scaffold(
                appBar: AppBar(
                  title: _inngageWebViewProperties2.appBarText,
                ),
                body: WebView(
                  initialUrl: url,
                  zoomEnabled: _inngageWebViewProperties2.withZoom,
                  debuggingEnabled: _inngageWebViewProperties2.debuggingEnabled,
                  javascriptMode: _inngageWebViewProperties2.withJavascript
                      ? JavascriptMode.unrestricted
                      : JavascriptMode.disabled,
                ))),
      );
    }
  }
}

