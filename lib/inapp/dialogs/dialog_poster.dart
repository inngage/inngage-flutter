import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inngage_plugin/inapp/inapp_actions.dart';
import 'package:inngage_plugin/inapp/widgets/custom_image_slideshow.dart';
import 'package:inngage_plugin/inapp/widgets/custom_text.dart';
import 'package:inngage_plugin/inapp/widgets/text_button.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

class DialogPoster extends StatefulWidget {
  final InAppModel inAppModel;

  const DialogPoster({
    Key? key,
    required this.inAppModel,
  }) : super(key: key);

  @override
  State<DialogPoster> createState() => _DialogPosterState();
}

class _DialogPosterState extends State<DialogPoster> {
  int? widthImage, heightImage;

  Future<void> getBackgroundImageSize(String imageUrl) async {
    final ByteData data =
        await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl);
    final Uint8List bytes = data.buffer.asUint8List();

    final decodedImage = await decodeImageFromList(bytes);

    debugPrint('Image width: ${decodedImage.width}');
    debugPrint('Image height: ${decodedImage.height}');

    setState(() {
      widthImage = decodedImage.width;
      heightImage = decodedImage.height;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!InngageUtils.isNullOrEmpty(widget.inAppModel.backgroundImg)) {
      if (widthImage == null || heightImage == null) {
        getBackgroundImageSize(widget.inAppModel.backgroundImg!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;

    return InngageUtils.isNullOrEmpty(widget.inAppModel.backgroundImg)
        ? Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            backgroundColor:
                HexColor.fromHex(widget.inAppModel.backgroundColor ?? "#000"),
            child: Container(
              width: deviceWidth * .9,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CustomImageSlideshow(inAppModel: widget.inAppModel),
                  CustomText(
                    text: widget.inAppModel.title,
                    fontSize: 18.0,
                    fontColor: widget.inAppModel.titleFontColor,
                    isBold: true,
                  ),
                  const SizedBox(height: 10),
                  CustomText(
                    text: widget.inAppModel.body,
                    fontSize: 16.0,
                    fontColor: widget.inAppModel.bodyFontColor,
                  ),
                  buildButtonsRow(context),
                ],
              ),
            ),
          )
        : widthImage != null && heightImage != null
            ? Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                backgroundColor: HexColor.fromHex(
                    widget.inAppModel.backgroundColor ?? "#000"),
                child: Container(
                  width: deviceWidth * .9,
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Stack(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              if (widget.inAppModel.bgImgActionType != null) {
                                InngageActions.executeAction(
                                    widget.inAppModel.bgImgActionType!,
                                    widget.inAppModel.bgImgActionLink!);
                              }
                            },
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              child: Image.network(
                                height: heightImage! - 100 >= widthImage!
                                    ? null
                                    : 500,
                                widget.inAppModel.backgroundImg ?? "",
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Column(
                              children: [
                                CustomImageSlideshow(
                                    inAppModel: widget.inAppModel),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CustomText(
                                        text: widget.inAppModel.title,
                                        fontSize: 18.0,
                                        fontColor:
                                            widget.inAppModel.titleFontColor,
                                        isBold: true,
                                      ),
                                      const SizedBox(height: 10),
                                      CustomText(
                                        text: widget.inAppModel.body,
                                        fontSize: 16.0,
                                        fontColor:
                                            widget.inAppModel.bodyFontColor,
                                      ),
                                    ],
                                  ),
                                ),
                                buildButtonsRow(context)
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              );
  }

  Widget buildButtonsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        CustomTextButton(
          text: widget.inAppModel.btnLeftTxt,
          actionLink: widget.inAppModel.btnLeftActionLink,
          actionType: widget.inAppModel.btnLeftActionType,
          textColor: widget.inAppModel.btnLeftTxtColor!,
          bgColor: widget.inAppModel.btnLeftBgColor!,
        ),
        _shouldAddSizedBox(
                widget.inAppModel.btnLeftTxt, widget.inAppModel.btnRightTxt)
            ? const SizedBox(width: 10) // Ajuste o tamanho conforme necessário
            : Container(),
        CustomTextButton(
          text: widget.inAppModel.btnRightTxt,
          actionLink: widget.inAppModel.btnRightActionLink,
          actionType: widget.inAppModel.btnRightActionType,
          textColor: widget.inAppModel.btnRightTxtColor!,
          bgColor: widget.inAppModel.btnRightBgColor!,
        ),
      ]),
    );
  }

  bool _shouldAddSizedBox(String? btnLeftTxt, String? btnRightTxt) {
    return btnLeftTxt != null &&
        btnLeftTxt.isNotEmpty &&
        btnRightTxt != null &&
        btnRightTxt.isNotEmpty;
  }
}
