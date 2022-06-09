import 'rich_content_model.dart';
class InAppModel {
  bool? inappMessage;
  String? title;
  String? titleFontColor;
  String? body;
  String? bodyFontColor;
  String? backgroundColor;
  String? backgroundImg;
  RichContent? richContent;
  String? btnLeftTxt;
  String? btnLeftTxtColor;
  String? btnLeftBgColor;
  String? btnLeftActionType;
  String? btnLeftActionLink;
  String? btnRightTxt;
  String? btnRightTxtColor;
  String? btnRightBgColor;
  String? btnRightActionType;
  String? btnRightActionLink;
  String? dotColor;

  InAppModel(
      {this.inappMessage,
      this.title,
      this.titleFontColor,
      this.body,
      this.bodyFontColor,
      this.backgroundColor,
      this.backgroundImg,
      this.richContent,
      this.btnLeftTxt,
      this.btnLeftTxtColor,
      this.btnLeftBgColor,
      this.btnLeftActionType,
      this.btnLeftActionLink,
      this.btnRightTxt,
      this.btnRightTxtColor,
      this.btnRightBgColor,
      this.btnRightActionType,
      this.btnRightActionLink,
      this.dotColor});

  InAppModel.fromJson(Map<String, dynamic> json) {
    inappMessage = json['inapp_message'];
    title = json['title'];
    titleFontColor = json['title_font_color'];
    body = json['body'];
    bodyFontColor = json['body_font_color'];
    backgroundColor = json['background_color'];
    backgroundImg = json['background_img'];
    richContent = json['rich_content'] != null
        ? new RichContent.fromJson(json['rich_content'])
        : null;
    btnLeftTxt = json['btn_left_txt'];
    btnLeftTxtColor = json['btn_left_txt_color'];
    btnLeftBgColor = json['btn_left_bg_color'];
    btnLeftActionType = json['btn_left_action_type'];
    btnLeftActionLink = json['btn_left_action_link'];
    btnRightTxt = json['btn_right_txt'];
    btnRightTxtColor = json['btn_right_txt_color'];
    btnRightBgColor = json['btn_right_bg_color'];
    btnRightActionType = json['btn_right_action-type'];
    btnRightActionLink = json['btn_right_action_link'];
    dotColor = json['dot_color'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['inapp_message'] = this.inappMessage;
    data['title'] = this.title;
    data['title_font_color'] = this.titleFontColor;
    data['body'] = this.body;
    data['body_font_color'] = this.bodyFontColor;
    data['background_color'] = this.backgroundColor;
    data['background_img'] = this.backgroundImg;
    if (this.richContent != null) {
      data['rich_content'] = this.richContent!.toJson();
    }
    data['btn_left_txt'] = this.btnLeftTxt;
    data['btn_left_txt_color'] = this.btnLeftTxtColor;
    data['btn_left_bg_color'] = this.btnLeftBgColor;
    data['btn_left_action_type'] = this.btnLeftActionType;
    data['btn_left_action_link'] = this.btnLeftActionLink;
    data['btn_right_txt'] = this.btnRightTxt;
    data['btn_right_txt_color'] = this.btnRightTxtColor;
    data['btn_right_bg_color'] = this.btnRightBgColor;
    data['btn_right_action-type'] = this.btnRightActionType;
    data['btn_right_action_link'] = this.btnRightActionLink;
    data['dot_color'] = this.dotColor;
    return data;
  }
}
