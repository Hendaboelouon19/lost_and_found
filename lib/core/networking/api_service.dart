import 'package:dio/dio.dart';

import 'api_constants.dart';

class ApiService {
  final Dio dio;

  ApiService(this.dio);

  Future<Response> login({
    required String email,
    required String password,
  }) {
    return dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> register({
    required String name,
    required String email,
    required String password,
  }) {
    return dio.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> getItems() {
    return dio.get(ApiConstants.items);
  }

  Future<Response> getItem(String id) {
    return dio.get('${ApiConstants.items}/$id');
  }

  Future<Response> addItem(Map<String, dynamic> data) {
    return dio.post(
      ApiConstants.items,
      data: data,
    );
  }

  Future<Response> getProfile() {
    return dio.get(ApiConstants.profile);
  }
}