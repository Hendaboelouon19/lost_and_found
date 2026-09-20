class ApiErrorModel {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiErrorModel({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(
      message: json['message']?.toString() ?? 'Something went wrong',
      statusCode: json['statusCode'] as int?,
      errors: json['errors'] is Map<String, dynamic>
          ? json['errors'] as Map<String, dynamic>
          : null,
    );
  }
}