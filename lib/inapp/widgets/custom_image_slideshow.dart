// custom_image_slideshow.dart

import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:inngage_plugin/inngage_plugin.dart';

class CustomImageSlideshow extends StatelessWidget {
  final InAppModel inAppModel;

  const CustomImageSlideshow({
    super.key,
    required this.inAppModel,
  });

  @override
  Widget build(BuildContext context) {
    var dots = 0;
    if (inAppModel.richContent!.img1 != null) dots++;
    if (inAppModel.richContent!.img2 != null) dots++;
    if (inAppModel.richContent!.img3 != null) dots++;

    return inAppModel.richContent!.carousel!
        ? SizedBox(
            height: 250,
            child: ImageSlideshow(
              initialPage: 0,
              indicatorColor: dots < 2
                  ? Colors.transparent
                  : HexColor.fromHex(inAppModel.backgroundColor ?? "#0000FF"),
              indicatorBackgroundColor: Colors.grey,

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
              children: [
                if (inAppModel.richContent!.img1 != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8)),
                    child: Image.network(
                      inAppModel.richContent!.img1!,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (inAppModel.richContent!.img2 != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8)),
                    child: Image.network(
                      inAppModel.richContent!.img2!,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (inAppModel.richContent!.img3 != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8)),
                    child: Image.network(
                      inAppModel.richContent!.img3!,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (inAppModel.richContent!.img4 != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8)),
                    child: Image.network(
                      inAppModel.richContent!.img4!,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (inAppModel.richContent!.img5 != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8)),
                    child: Image.network(
                      inAppModel.richContent!.img5!,
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
          )
        : Container();
  }
}
