import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ItemDetailsState {}

class ItemDetailsInitial extends ItemDetailsState {}

class ItemDetailsLoading extends ItemDetailsState {}

class ItemDetailsLoaded extends ItemDetailsState {
  ItemDetailsLoaded(this.item);

  final Map<String, dynamic> item;
}

class ItemDetailsFailure extends ItemDetailsState {
  ItemDetailsFailure(this.message);

  final String message;
}

class ItemDetailsCubit extends Cubit<ItemDetailsState> {
  ItemDetailsCubit() : super(ItemDetailsInitial());

  Future<void> loadItem(String id) async {
    emit(ItemDetailsLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      emit(ItemDetailsLoaded({
        'id': id,
        'title': 'Sample item',
        'description': 'Detailed description',
      }));
    } catch (e) {
      emit(ItemDetailsFailure(e.toString()));
    }
  }
}
