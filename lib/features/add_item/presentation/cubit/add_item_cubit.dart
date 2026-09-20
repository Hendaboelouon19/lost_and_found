import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AddItemState {}

class AddItemInitial extends AddItemState {}

class AddItemLoading extends AddItemState {}

class AddItemSuccess extends AddItemState {
  AddItemSuccess(this.message);

  final String message;
}

class AddItemFailure extends AddItemState {
  AddItemFailure(this.message);

  final String message;
}

class AddItemCubit extends Cubit<AddItemState> {
  AddItemCubit() : super(AddItemInitial());

  Future<void> addItem({required String title, required String description}) async {
    emit(AddItemLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      emit(AddItemSuccess('Item added successfully'));
    } catch (e) {
      emit(AddItemFailure(e.toString()));
    }
  }
}
