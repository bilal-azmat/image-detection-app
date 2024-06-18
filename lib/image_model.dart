class ImageModel {
  List<String>? predictions;

  ImageModel({this.predictions});

  ImageModel.fromJson(Map<String, dynamic> json) {
    predictions = json['predictions'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['predictions'] = this.predictions;
    return data;
  }
}
