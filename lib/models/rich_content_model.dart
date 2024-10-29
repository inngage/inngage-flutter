import 'package:inngage_plugin/models/carrousel_images_model.dart';

class RichContent {
  bool? carousel;
  List<CarrouselImagesModel>? images;
  String? img1;
  String? img2;
  String? img3;
  String? img4;
  String? img5;

  RichContent({
    this.carousel,
    this.images,
    this.img1,
    this.img2,
    this.img3,
    this.img4,
    this.img5,
  });

  RichContent.fromJson(Map<String, dynamic> json) {
    carousel = json['carousel'];
    if (json['images'] != null) {
      images = (json['images'] as List)
          .map((item) => CarrouselImagesModel.fromJson(item))
          .toList();
    }
    img1 = json['img1'];
    img2 = json['img2'];
    img3 = json['img3'];
    img4 = json['img4'];
    img5 = json['img5'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['carousel'] = carousel;
    if (images != null) {
      data['images'] = images!.map((imgData) => imgData.toJson()).toList();
    }
    data['img1'] = img1;
    data['img2'] = img2;
    data['img3'] = img3;
    data['img4'] = img4;
    data['img5'] = img5;
    return data;
  }

  @override
  String toString() {
    return 'RichContent(carousel: $carousel, images: $images)';
  }
}
