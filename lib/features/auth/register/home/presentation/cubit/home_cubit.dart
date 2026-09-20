import 'package:flutter_bloc/flutter_bloc.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  HomeLoaded(this.items);

  final List<Map<String, dynamic>> items;
}

class HomeFailure extends HomeState {
  HomeFailure(this.message);

  final String message;
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  Future<void> loadItems() async {
    emit(HomeLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      emit(HomeLoaded([
        {'id': '1', 'title': 'Sample item', 'description': 'Hello from home'},
      ]));
    } catch (e) {
      emit(HomeFailure(e.toString()));
    }
  }
}
