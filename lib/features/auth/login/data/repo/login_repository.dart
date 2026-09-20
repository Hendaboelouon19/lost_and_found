import 'package:errasoft/core/networking/api_error_handler.dart';
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
    } catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }
}