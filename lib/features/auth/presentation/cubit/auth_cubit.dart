import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  AuthSuccess(this.message);

  final String message;
}

class AuthFailure extends AuthState {
  AuthFailure(this.message);

  final String message;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      emit(AuthSuccess('Welcome back!'));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
