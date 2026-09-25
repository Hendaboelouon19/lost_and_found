import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

  LatLng? _userLocation;

  final List<LostFoundReport> _reports = [
    LostFoundReport(
      id: '1',
      title: 'Black AirPods',
      type: ReportType.lost,
      category: 'Electronics',
      location: 'Gate 3',
      time: 'Today, 5:15 PM',
      description: 'Black AirPods case with a small scratch on the right side.',
      photoUrl:
          'https://images.unsplash.com/photo-1606220945770-b5b6c2c55bf1?auto=format&fit=crop&w=500&q=80',
    ),
    LostFoundReport(
      id: '2',
      title: 'Black AirPods',
      type: ReportType.found,
      category: 'Electronics',
      location: 'Gate 3',
      time: 'Today, 5:30 PM',
      description: 'Found near the entrance. One earbud was still charging.',
      photoUrl:
          'https://images.unsplash.com/photo-1588423771073-b8903fbb85b5?auto=format&fit=crop&w=500&q=80',
    ),
    LostFoundReport(
      id: '3',
      title: 'Blue Backpack',
      type: ReportType.lost,
      category: 'Bag',
      location: 'Library',
      time: 'Yesterday, 6:10 PM',
      description:
          'Blue backpack with a yellow keychain and a notebook inside.',
      photoUrl:
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=500&q=80',
    ),
    LostFoundReport(
      id: '4',
      title: 'Silver Keychain',
      type: ReportType.found,
      category: 'Accessories',
      location: 'Parking',
      time: 'This morning',
      description: 'Silver keychain with a small red tag.',
      photoUrl:
          'https://images.unsplash.com/photo-1612810436541-336d5f7a4e2b?auto=format&fit=crop&w=500&q=80',
    ),
  ];

  Future<void> loadItems() async {
    emit(HomeLoading());
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();
      _reports
        ..clear()
        ..addAll(
          snapshot.docs.map(
            (doc) => LostFoundReport.fromMap({
              ...doc.data(),
              'id': doc.id,
            }),
          ),
        );
      await _syncMatchNotifications();
      emit(HomeLoaded(_withCalculatedMatches()));
    } on FirebaseException {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      emit(HomeLoaded(_withCalculatedMatches()));
    } catch (e) {
      emit(HomeFailure(e.toString()));
    }
  }

  Future<void> addReport(LostFoundReport report) async {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } on FirebaseException {
      user = null;
    }
    final reportWithOwner = LostFoundReport(
      id: report.id,
      title: report.title,
      type: report.type,
      category: report.category,
      location: report.location,
      time: report.time,
      description: report.description,
      latitude: report.latitude,
      longitude: report.longitude,
      photoUrl: report.photoUrl,
      photoData: report.photoData,
      userId: user?.uid ?? report.userId,
    );

    try {
      final data = reportWithOwner.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      if (reportWithOwner.photoData != null) {
        base64Decode(reportWithOwner.photoData!);
      }
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportWithOwner.id)
          .set(data);
        await _syncMatchNotifications();
    } on FirebaseException {
      // Keep local behavior available when Firebase is not configured offline.
    }

    final updatedReports = [reportWithOwner, ..._reports];
    _reports
      ..clear()
      ..addAll(updatedReports);

    if (state is HomeLoaded) {
      emit(HomeLoaded(_withCalculatedMatches()));
      return;
    }

    emit(HomeLoaded(_withCalculatedMatches()));
  }

  Future<void> _syncMatchNotifications() async {
    final notifications = FirebaseFirestore.instance.collection('notifications');
    for (var index = 0; index < _reports.length; index++) {
      final first = _reports[index];
      for (var nextIndex = index + 1;
          nextIndex < _reports.length;
          nextIndex++) {
        final second = _reports[nextIndex];
        if (first.type == second.type ||
            first.userId == null ||
            second.userId == null ||
            first.userId == second.userId) {
          continue;
        }

        final lost = first.type.isLost ? first : second;
        final found = first.type.isLost ? second : first;
        final score = LostFoundReport.calculateMatchProbability(lost, found);
        if (score < 60) continue;

        for (final recipient in [first.userId!, second.userId!]) {
          final notificationId =
              '${recipient}_${first.id}_${second.id}';
          final reference = notifications.doc(notificationId);
          if ((await reference.get()).exists) continue;
          await reference.set({
            'recipientId': recipient,
            'type': 'possible_match',
            'reportId': first.id,
            'relatedReportId': second.id,
            'matchProbability': score,
            'title': 'Possible match found',
            'body': '${score.toStringAsFixed(0)}% match between '
                '${first.title} and ${second.title}.',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  void setUserLocation(LatLng location) {
    _userLocation = location;
    if (state is HomeLoaded) {
      emit(HomeLoaded(_withCalculatedMatches()));
    }
  }

  List<LostFoundReport> _withCalculatedMatches() {
    final reports = _reports
        .map(
          (report) => LostFoundReport(
            id: report.id,
            title: report.title,
            type: report.type,
            category: report.category,
            location: report.location,
            time: report.time,
            description: report.description,
            latitude: report.latitude,
            longitude: report.longitude,
            photoUrl: report.photoUrl,
            photoData: report.photoData,
            matchProbability: LostFoundReport.bestMatchProbability(
              report,
              _reports,
            ),
            userId: report.userId,
          ),
        )
        .toList();

    if (_userLocation == null) return reports;

    reports.sort((left, right) {
      final leftDistance = _distanceFromUser(left);
      final rightDistance = _distanceFromUser(right);
      if (leftDistance == null && rightDistance == null) return 0;
      if (leftDistance == null) return 1;
      if (rightDistance == null) return -1;
      return leftDistance.compareTo(rightDistance);
    });
    return reports;
  }

  double? _distanceFromUser(LostFoundReport report) {
    if (report.latitude == null || report.longitude == null) return null;
    return Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      report.latitude!,
      report.longitude!,
    );
  }
}
