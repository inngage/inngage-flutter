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
    final images = inAppModel.richContent?.images ?? [];

    if (images.isEmpty) return Container();

    final indicatorColor = images.length < 2
        ? Colors.transparent
        : HexColor.fromHex(inAppModel.backgroundColor ?? "#0000FF");

    return SizedBox(
      height: 250,
      child: ImageSlideshow(
        initialPage: 0,
        indicatorColor: indicatorColor,
        indicatorBackgroundColor: Colors.grey,
        onPageChanged: (value) => debugPrint('Page changed: $value'),
        isLoop: images.length > 1,
        children: images.map((imageData) {
          return GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              await InngageUtils.launchURL(imageData.urlImg!);
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Image.network(
                imageData.img ?? '',
                fit: BoxFit.contain,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
