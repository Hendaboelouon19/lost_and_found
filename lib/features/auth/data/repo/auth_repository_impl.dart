import 'package:errasoft/features/auth/domain/repo/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl();

  @override
  Future<String> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Logged in successfully';
  }
}
