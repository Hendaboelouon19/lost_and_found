import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';

import 'package:errasoft/core/utils/local_storage.dart';
import 'package:errasoft/features/add_item/presentation/screens/add_item_screen.dart';
import 'package:errasoft/features/auth/login/presentation/screens/login_screen.dart';
import 'package:errasoft/features/auth/register/home/data/models/lost_found_report.dart';
import 'package:errasoft/features/auth/register/home/presentation/cubit/home_cubit.dart';
import 'package:errasoft/features/profile/presentation/screens/profile_screen.dart';
import 'package:errasoft/themes/app_theme.dart';
import 'package:errasoft/features/auth/register/home/presentation/widgets/lost_found_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = 'All';
  bool showMap = false;
  bool isLocating = true;
  LatLng? userLocation;

  Future<void> _detectUserLocation(HomeCubit cubit) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final location = LatLng(position.latitude, position.longitude);
      setState(() => userLocation = location);
      cubit.setUserLocation(location);
    } finally {
      if (mounted) setState(() => isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = HomeCubit();
        _detectUserLocation(cubit);
        cubit.loadItems();
        return cubit;
      },
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Lost & Found'),
            actions: [
              _NotificationButton(),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                icon: const Icon(Icons.person_outline),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await LocalStorage.instance.clearUserData();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<HomeCubit>(),
                    child: const AddItemScreen(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Report item'),
          ),
          body: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading || state is HomeInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is HomeFailure) {
                return Center(child: Text(state.message));
              }

              if (state is HomeLoaded) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Find what matters',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.nightBordeaux,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Recent reports from your community',
                      style: TextStyle(
                        color: AppTheme.nightBordeaux.withValues(alpha: .65),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _NearbyReportsControl(
                      isLocating: isLocating,
                      hasLocation: userLocation != null,
                      mapVisible: showMap,
                      onPressed: () => setState(() => showMap = !showMap),
                    ),
                    if (showMap) ...[
                      const SizedBox(height: 12),
                      LostFoundMap(
                        items: state.items,
                        initialCenter: userLocation,
                        onLocationSelected: (location) {
                          setState(() => userLocation = location);
                          context.read<HomeCubit>().setUserLocation(location);
                        },
                      ),
                    ],
                    if (state.items.any(
                      (item) => (item.matchProbability ?? 0) >= 60,
                    )) ...[
                      const SizedBox(height: 16),
                      _MatchUpdateBanner(
                        match: state.items.reduce(
                          (left, right) =>
                              (left.matchProbability ?? 0) >=
                                      (right.matchProbability ?? 0)
                                  ? left
                                  : right,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Text(
                      'All reports',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.nightBordeaux,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['All', 'Lost', 'Found', 'Electronics'].map((
                          filter,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: selectedFilter == filter,
                              onSelected: (_) =>
                                  setState(() => selectedFilter = filter),
                              selectedColor: AppTheme.coolHorizon,
                              backgroundColor: Colors.white,
                              side: BorderSide.none,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...state.items
                        .where((item) {
                          if (selectedFilter == 'All') {
                            return true;
                          }
                          if (selectedFilter == 'Electronics') {
                            return item.category.toLowerCase() == 'electronics';
                          }
                          return item.type.label == selectedFilter;
                        })
                        .map((item) {
                          final type = item.type.label;
                          final match = item.matchProbability ?? 0.0;
                          final isLost = item.type.isLost;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: _ReportThumbnail(
                                item: item,
                                isLost: isLost,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLost
                                          ? Colors.orange.shade100
                                          : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        color: isLost
                                            ? Colors.orange.shade900
                                            : Colors.green.shade900,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Category: ${item.category}'),
                                    const SizedBox(height: 4),
                                    Text('Location: ${item.location}'),
                                    const SizedBox(height: 4),
                                    Text(item.time),
                                    Text(
                                      item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Possible match: ${match.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: AppTheme.nightBordeaux,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ItemPreviewSheet(item: item),
                                );
                              },
                            ),
                          );
                        }),
                  ],
                );
              }

              return const Center(child: Text('No reports available'));
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) return const SizedBox.shrink();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => _showNotifications(context, userId),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 9 ? '9+' : '$count'),
            child: const Icon(Icons.notifications_none),
          ),
        );
      },
    );
  }

  Future<void> _showNotifications(BuildContext context, String userId) async {
    QuerySnapshot<Map<String, dynamic>>? snapshot;
    String? errorMessage;
    try {
      snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .limit(20)
          .get();
    } on FirebaseException catch (error) {
      errorMessage = error.message ?? 'Unable to load notifications.';
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text('Notifications'),
            subtitle: Text('Match updates and contact requests'),
          ),
          if (errorMessage != null)
            ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Notifications unavailable'),
              subtitle: Text(errorMessage),
            ),
          if (errorMessage == null && snapshot!.docs.isEmpty)
            const ListTile(title: Text('No notifications yet.')),
          ...?snapshot?.docs.map(
            (doc) => ListTile(
              leading: Icon(
                doc.data()['type'] == 'possible_match'
                    ? Icons.compare_arrows
                    : Icons.mail_outline,
              ),
              title: Text(doc.data()['title']?.toString() ?? 'Returna update'),
              subtitle: Text(doc.data()['body']?.toString() ?? ''),
              onTap: () => doc.reference.update({'read': true}),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportThumbnail extends StatelessWidget {
  const _ReportThumbnail({required this.item, required this.isLost});

  final LostFoundReport item;
  final bool isLost;

  @override
  Widget build(BuildContext context) {
    if (item.photoData == null &&
        item.photoUrl == null &&
        item.category.toLowerCase().contains('bag')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/products/bag.png',
          width: 64,
          height: 64,
          fit: BoxFit.contain,
        ),
      );
    }
    if (item.photoData != null) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(item.photoData!),
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    if (item.photoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          item.photoUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _FallbackReportIcon(isLost: isLost),
        ),
      );
    }
    return _FallbackReportIcon(isLost: isLost);
  }
}

class _MatchUpdateBanner extends StatelessWidget {
  const _MatchUpdateBanner({required this.match});

  final LostFoundReport match;

  @override
  Widget build(BuildContext context) {
    final score = match.matchProbability ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.nightBordeaux,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.ivoryMist),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Possible match found',
                  style: TextStyle(
                    color: AppTheme.ivoryMist,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${match.title} has a ${score.toStringAsFixed(0)}% match.',
                  style: TextStyle(
                    color: AppTheme.ivoryMist.withValues(alpha: .78),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppTheme.ivoryMist,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackReportIcon extends StatelessWidget {
  const _FallbackReportIcon({required this.isLost});

  final bool isLost;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundColor: isLost
        ? AppTheme.nightBordeaux.withValues(alpha: .14)
        : AppTheme.coolHorizon.withValues(alpha: .24),
    child: Icon(
      isLost ? Icons.search : Icons.check_circle_outline,
      color: isLost ? AppTheme.nightBordeaux : AppTheme.coolHorizon,
    ),
  );
}

class _NearbyReportsControl extends StatelessWidget {
  const _NearbyReportsControl({
    required this.isLocating,
    required this.hasLocation,
    required this.mapVisible,
    required this.onPressed,
  });

  final bool isLocating;
  final bool hasLocation;
  final bool mapVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final status = isLocating
        ? 'Finding reports near you'
        : hasLocation
            ? 'Showing nearby reports first'
            : 'Location unavailable, showing all reports';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.near_me_outlined, color: AppTheme.nightBordeaux),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nearby reports',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(mapVisible ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }
}
