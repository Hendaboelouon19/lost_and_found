class LoginResponseModel {
  final String token;
  final String userId;
  final String? name;
  final String? email;

  const LoginResponseModel({
    required this.token,
    required this.userId,
    this.name,
    this.email,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['token']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString(),
      email: json['email']?.toString(),
    );
  }
}