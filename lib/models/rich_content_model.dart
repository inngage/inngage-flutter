class RichContent {
  bool? carousel;
  String? img1;
  String? img2;
  String? img3;

  RichContent({this.carousel, this.img1, this.img2, this.img3});

  RichContent.fromJson(Map<String, dynamic> json) {
    carousel = json['carousel'];
    img1 = json['img1'];
    img2 = json['img2'];
    img3 = json['img3'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['carousel'] = this.carousel;
    data['img1'] = this.img1;
    data['img2'] = this.img2;
    data['img3'] = this.img3;
    return data;
  }
}
