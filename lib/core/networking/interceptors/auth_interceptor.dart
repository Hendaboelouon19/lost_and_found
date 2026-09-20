import 'package:dio/dio.dart';

import '../../utils/local_storage.dart';

class AuthInterceptor extends Interceptor {
  final LocalStorage localStorage;

  AuthInterceptor(this.localStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await localStorage.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }
}