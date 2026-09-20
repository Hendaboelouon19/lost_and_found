import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  ProfileLoaded(this.profile);

  final Map<String, dynamic> profile;
}

class ProfileFailure extends ProfileState {
  ProfileFailure(this.message);

  final String message;
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      emit(ProfileLoaded({
        'userId': '1',
        'name': 'John Doe',
        'bio': 'Flutter developer',
      }));
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }
}
