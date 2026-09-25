import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

import 'package:errasoft/themes/app_theme.dart';

class SelectedLocation {
  const SelectedLocation({required this.position, required this.label});

  final LatLng position;
  final String label;
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialPosition});

  final LatLng? initialPosition;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const egyptCenter = LatLng(26.8206, 30.8025);
  final mapController = MapController();
  LatLng? selectedPosition;
  bool isLocating = false;
  bool isSearching = false;
  bool mapReady = false;
  LatLng? pendingMove;
  String selectedLabel = 'Tap anywhere in Egypt to choose a location';
  final searchController = TextEditingController();
  List<_LocationResult> searchResults = [];
  Timer? searchDebounce;
  int searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    selectedPosition = widget.initialPosition;
    if (selectedPosition != null) {
      selectedLabel = 'Selected location';
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are turned off.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      _selectLocation(location, 'Current device location');
      _moveMap(location, 15);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLocating = false);
    }
  }

  void _selectLocation(
    LatLng location, [
    String label = 'Selected map location',
  ]) {
    setState(() {
      selectedPosition = location;
      selectedLabel = label;
    });
  }

  Future<void> _searchLocations(String query) async {
    searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => searchResults = []);
      return;
    }
    searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _loadSearchResults(query),
    );
  }

  Future<void> _loadSearchResults(String query) async {
    final requestId = ++searchRequestId;
    setState(() => isSearching = true);
    try {
      final response = await Dio().get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query.trim(),
          'format': 'jsonv2',
          'limit': 6,
          'countrycodes': 'eg',
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'errasoft-lost-found/1.0'}),
      );
      if (!mounted || requestId != searchRequestId) return;
      final results = (response.data ?? []).map((item) {
        final data = item as Map<String, dynamic>;
        return _LocationResult(
          label: data['display_name']?.toString() ?? query,
          point: LatLng(
            double.parse(data['lat'].toString()),
            double.parse(data['lon'].toString()),
          ),
        );
      }).toList();
      setState(() => searchResults = results);
    } catch (_) {
      if (mounted && requestId == searchRequestId) {
        setState(() => searchResults = []);
      }
    } finally {
      if (mounted && requestId == searchRequestId) {
        setState(() => isSearching = false);
      }
    }
  }

  void _chooseSearchResult(_LocationResult result) {
    searchController.text = result.label;
    _selectLocation(result.point, result.label);
    setState(() => searchResults = []);
    _moveMap(result.point, 15);
    FocusScope.of(context).unfocus();
  }

  void _moveMap(LatLng point, double zoom) {
    if (mapReady) {
      mapController.move(point, zoom);
    } else {
      pendingMove = point;
    }
  }

  void _zoomBy(double amount) {
    if (!mapReady) return;
    final camera = mapController.camera;
    final nextZoom = (camera.zoom + amount).clamp(3.0, 18.0).toDouble();
    mapController.move(camera.center, nextZoom);
  }

  @override
  Widget build(BuildContext context) {
    final markers = selectedPosition == null
        ? <Marker>[]
        : [
            Marker(
              point: selectedPosition!,
              width: 52,
              height: 62,
              child: const Icon(
                Icons.location_pin,
                color: AppTheme.nightBordeaux,
                size: 48,
              ),
            ),
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('Choose location')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition ?? egyptCenter,
              initialZoom: widget.initialPosition == null ? 5.4 : 15,
              onMapReady: () {
                mapReady = true;
                if (pendingMove != null) {
                  mapController.move(pendingMove!, 15);
                  pendingMove = null;
                }
              },
              onTap: (_, position) => _selectLocation(position),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.errasoft',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: _searchLocations,
                    decoration: InputDecoration(
                      hintText: 'Search a university, club, street, or place',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: searchResults
                            .map(
                              (result) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.place_outlined),
                                title: Text(
                                  result.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _chooseSearchResult(result),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 88,
            left: 16,
            right: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.ivoryMist.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.place, color: AppTheme.nightBordeaux),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 96,
            child: Column(
              children: [
                _PickerMapControl(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onPressed: () => _zoomBy(1),
                ),
                const SizedBox(height: 8),
                _PickerMapControl(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onPressed: () => _zoomBy(-1),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'current-location',
                  onPressed: isLocating ? null : _useCurrentLocation,
                  backgroundColor: AppTheme.ivoryMist,
                  foregroundColor: AppTheme.nightBordeaux,
                  child: isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: FilledButton.icon(
              onPressed: selectedPosition == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      SelectedLocation(
                        position: selectedPosition!,
                        label: selectedLabel,
                      ),
                    ),
              icon: const Icon(Icons.check),
              label: const Text('Use this location'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}

class _LocationResult {
  const _LocationResult({required this.label, required this.point});

  final String label;
  final LatLng point;
}

class _PickerMapControl extends StatelessWidget {
  const _PickerMapControl({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.ivoryMist,
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: AppTheme.nightBordeaux),
          ),
        ),
      ),
    );
  }
}
