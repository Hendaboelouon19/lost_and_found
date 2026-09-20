import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:errasoft/core/networking/api_error_model.dart';
import 'package:errasoft/features/auth/login/data/models/login_request_model.dart';
import 'package:errasoft/features/auth/login/data/models/login_response_model.dart';
import 'package:errasoft/features/auth/login/data/repo/login_repository.dart';

sealed class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final LoginResponseModel response;

  LoginSuccess(this.response);
}

class LoginError extends LoginState {
  final String message;

  LoginError(this.message);
}

class LoginCubit extends Cubit<LoginState> {
  final LoginRepository repository;

  LoginCubit(this.repository) : super(LoginInitial());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(LoginLoading());

    try {
      final response = await repository.login(
        LoginRequestModel(
          email: email,
          password: password,
        ),
      );

      emit(LoginSuccess(response));
    } on ApiErrorModel catch (error) {
      emit(LoginError(error.message));
    } catch (_) {
      emit(LoginError('Something went wrong'));
    }
  }
}