import 'dart:convert';

class CarrouselImagesModel {
  String? img;
  String? urlImg;

  CarrouselImagesModel({
    this.img,
    this.urlImg,
  });

  factory CarrouselImagesModel.fromJson(Map<String, dynamic> json) {
    String imgKey = json.keys.firstWhere((key) => key.startsWith('img'));
    String urlImgKey = json.keys.firstWhere((key) => key.startsWith('url_img'));

    return CarrouselImagesModel(
      img: json[imgKey] as String,
      urlImg: json[urlImgKey] as String,
    );
  }

  @override
  String toString() {
    return 'CarrouselImagesModel(img: $img, urlImg: $urlImg)';
  }

  Map<String, dynamic> toJson() {
    return {
      'img': img,
      'url_img': urlImg,
    };
  }
}

List<CarrouselImagesModel> parseImagesList(String jsonString) {
  final parsed = jsonDecode(jsonString);
  return (parsed['images'] as List)
      .map((item) => CarrouselImagesModel.fromJson(item))
      .toList();
}
