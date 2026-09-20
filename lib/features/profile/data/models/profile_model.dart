class ProfileModel {
  const ProfileModel({
    required this.userId,
    required this.name,
    required this.bio,
  });

  final String userId;
  final String name;
  final String bio;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
    );
  }
}
