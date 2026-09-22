import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:errasoft/features/auth/register/home/data/models/lost_found_report.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  HomeLoaded(this.items);

  final List<LostFoundReport> items;
}

class HomeFailure extends HomeState {
  HomeFailure(this.message);

  final String message;
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  final List<LostFoundReport> _reports = [
    LostFoundReport(
      id: '1',
      title: 'Black AirPods',
      type: ReportType.lost,
      category: 'Electronics',
      location: 'Gate 3',
      time: 'Today, 5:15 PM',
      description: 'Black AirPods case with a small scratch on the right side.',
      matchProbability: 96,
    ),
    LostFoundReport(
      id: '2',
      title: 'Black AirPods',
      type: ReportType.found,
      category: 'Electronics',
      location: 'Gate 3',
      time: 'Today, 5:30 PM',
      description: 'Found near the entrance. One earbud was still charging.',
      matchProbability: 96,
    ),
    LostFoundReport(
      id: '3',
      title: 'Blue Backpack',
      type: ReportType.lost,
      category: 'Bag',
      location: 'Library',
      time: 'Yesterday, 6:10 PM',
      description: 'Blue backpack with a yellow keychain and a notebook inside.',
      matchProbability: 68,
    ),
    LostFoundReport(
      id: '4',
      title: 'Silver Keychain',
      type: ReportType.found,
      category: 'Accessories',
      location: 'Parking',
      time: 'This morning',
      description: 'Silver keychain with a small red tag.',
      matchProbability: 42,
    ),
  ];

  Future<void> loadItems() async {
    emit(HomeLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      emit(HomeLoaded(List<LostFoundReport>.from(_reports)));
    } catch (e) {
      emit(HomeFailure(e.toString()));
    }
  }

  void addReport(LostFoundReport report) {
    final updatedReports = [report, ..._reports];
    _reports
      ..clear()
      ..addAll(updatedReports);

    if (state is HomeLoaded) {
      emit(HomeLoaded(List<LostFoundReport>.from(_reports)));
      return;
    }

    emit(HomeLoaded(List<LostFoundReport>.from(_reports)));
  }
}
