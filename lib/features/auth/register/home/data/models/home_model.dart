class HomeModel {
  const HomeModel({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    return HomeModel(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
