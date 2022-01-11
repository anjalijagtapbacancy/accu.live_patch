class ArrhythmiaType {
  String? arrhythmiaType;

  ArrhythmiaType({this.arrhythmiaType});

  ArrhythmiaType.fromJson(Map<String, dynamic> json) {
    arrhythmiaType = json['Arrhythmia_Type'];
  }

  Map<String, String?> toJson() {
    final Map<String, String?> data = new Map<String, String?>();
    data['Arrhythmia_Type'] = this.arrhythmiaType;
    return data;
  }
}
