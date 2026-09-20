class AddItemModel {
  const AddItemModel({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  factory AddItemModel.fromJson(Map<String, dynamic> json) {
    return AddItemModel(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
    };
  }
}
