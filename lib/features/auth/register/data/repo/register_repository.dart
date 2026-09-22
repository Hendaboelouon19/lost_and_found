import 'package:errasoft/core/networking/api_error_handler.dart';
import 'package:errasoft/core/networking/api_service.dart';
import 'package:errasoft/features/auth/register/data/models/register_request_model.dart';

class RegisterRepository {
  final ApiService apiService;

  RegisterRepository(this.apiService);

  Future<void> register(RegisterRequestModel request) async {
    try {
      await apiService.register(
        name: request.name,
        email: request.email,
        password: request.password,
      );
    } catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }
}
