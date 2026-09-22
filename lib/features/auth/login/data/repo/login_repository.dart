import 'package:dio/dio.dart';

import 'package:errasoft/core/networking/api_error_handler.dart';
import 'package:errasoft/core/networking/api_error_model.dart';
import 'package:errasoft/core/networking/api_service.dart';
import 'package:errasoft/core/utils/local_storage.dart';
import 'package:errasoft/features/auth/login/data/models/login_request_model.dart';
import 'package:errasoft/features/auth/login/data/models/login_response_model.dart';

class LoginRepository {
  final ApiService apiService;
  final LocalStorage localStorage;

  LoginRepository(this.apiService, this.localStorage);

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await apiService.login(
        email: request.email,
        password: request.password,
      );

      final data = Map<String, dynamic>.from(response.data as Map);

      final loginResponse = LoginResponseModel.fromJson(data);

      await localStorage.saveToken(loginResponse.token);
      await localStorage.saveUserId(loginResponse.userId);

      return loginResponse;
    } on ApiErrorModel catch (error) {
      if (error.message == 'No internet connection') {
        return _loginOffline(request);
      }
      rethrow;
    } catch (error) {
      if (error is DioException && error.type == DioExceptionType.connectionError) {
        return _loginOffline(request);
      }
      throw ApiErrorHandler.handle(error);
    }
  }

  Future<LoginResponseModel> _loginOffline(LoginRequestModel request) async {
    final userId = 'local-user-${DateTime.now().millisecondsSinceEpoch}';
    final token = 'offline-token-${DateTime.now().millisecondsSinceEpoch}';
    final name = request.email.split('@').first;

    await localStorage.saveToken(token);
    await localStorage.saveUserId(userId);

    return LoginResponseModel(
      token: token,
      userId: userId,
      email: request.email,
      name: name,
    );
  }
}