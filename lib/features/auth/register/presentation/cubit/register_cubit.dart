import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:errasoft/core/networking/api_error_model.dart';
import 'package:errasoft/features/auth/register/data/models/register_request_model.dart';
import 'package:errasoft/features/auth/register/data/repo/register_repository.dart';

sealed class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {}

class RegisterError extends RegisterState {
  final String message;

  RegisterError(this.message);
}

class RegisterCubit extends Cubit<RegisterState> {
  final RegisterRepository repository;

  RegisterCubit(this.repository) : super(RegisterInitial());

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(RegisterLoading());

    try {
      await repository.register(
        RegisterRequestModel(
          name: name,
          email: email,
          password: password,
        ),
      );

      emit(RegisterSuccess());
    } on ApiErrorModel catch (error) {
      emit(RegisterError(error.message));
    } catch (_) {
      emit(RegisterError('Something went wrong'));
    }
  }
}