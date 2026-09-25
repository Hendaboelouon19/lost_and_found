import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:async';

import 'package:errasoft/features/auth/register/home/data/models/lost_found_report.dart';
import 'package:errasoft/features/item_details/presentation/screens/item_details_screen.dart';
import 'package:errasoft/themes/app_theme.dart';

class LostFoundMap extends StatefulWidget {
  const LostFoundMap({
    super.key,
    required this.items,
    this.initialCenter,
    this.onLocationSelected,
  });

  final List<LostFoundReport> items;
  final LatLng? initialCenter;
  final ValueChanged<LatLng>? onLocationSelected;

  @override
  State<LostFoundMap> createState() => _LostFoundMapState();
}

class _LostFoundMapState extends State<LostFoundMap> {
  static const egyptCenter = LatLng(26.8206, 30.8025);
  final mapController = MapController();
  bool isLocating = false;
  bool mapReady = false;
  bool isSearching = false;
  final searchController = TextEditingController();
  List<_MapSearchResult> searchResults = [];
  Timer? searchDebounce;
  int searchRequestId = 0;
  LatLng? pendingMove;

  Future<void> _goToCurrentLocation() async {
    setState(() => isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are turned off.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }
      final position = await Geolocator.getCurrentPosition();
      _moveMap(LatLng(position.latitude, position.longitude), 14);
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

  Future<void> _searchPlaces(String query) async {
    searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => searchResults = []);
      return;
    }
    searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _loadPlaces(query),
    );
  }

  Future<void> _loadPlaces(String query) async {
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
      setState(() {
        searchResults = (response.data ?? []).map((item) {
          final data = item as Map<String, dynamic>;
          return _MapSearchResult(
            label: data['display_name']?.toString() ?? query,
            point: LatLng(
              double.parse(data['lat'].toString()),
              double.parse(data['lon'].toString()),
            ),
          );
        }).toList();
      });
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

  void _choosePlace(_MapSearchResult result) {
    searchController.text = result.label;
    setState(() => searchResults = []);
    _moveMap(result.point, 15);
    widget.onLocationSelected?.call(result.point);
    FocusScope.of(context).unfocus();
  }

  Future<void> _submitSearch(String query) async {
    if (searchResults.isNotEmpty) {
      _choosePlace(searchResults.first);
      return;
    }
    if (query.trim().length < 3) return;
    await _loadPlaces(query);
    if (mounted && searchResults.isNotEmpty) {
      _choosePlace(searchResults.first);
    }
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

  void _showItem(LostFoundReport item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItemPreviewSheet(item: item),
    );
  }

  List<Marker> _markers() {
    const fallbackLocations = [
      LatLng(30.0444, 31.2357),
      LatLng(30.0131, 31.2089),
      LatLng(31.2001, 29.9187),
      LatLng(31.0409, 31.3785),
    ];
    return widget.items.asMap().entries.map((entry) {
      final item = entry.value;
      final fallback = fallbackLocations[entry.key % fallbackLocations.length];
      final point = item.latitude != null && item.longitude != null
          ? LatLng(item.latitude!, item.longitude!)
          : fallback;
      final color = item.type.isLost
          ? AppTheme.nightBordeaux
          : AppTheme.coolHorizon;
      return Marker(
        point: point,
        width: 52,
        height: 62,
        child: GestureDetector(
          onTap: () => _showItem(item),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: Icon(
                  item.type.isLost ? Icons.search : Icons.check,
                  color: AppTheme.ivoryMist,
                  size: 18,
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: AppTheme.nightBordeaux,
                size: 18,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.coolHorizon.withValues(alpha: .35)),
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter ?? egyptCenter,
              initialZoom: widget.initialCenter == null ? 5.4 : 14,
              onMapReady: () {
                mapReady = true;
                if (pendingMove != null) {
                  mapController.move(pendingMove!, 14);
                  pendingMove = null;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.errasoft',
              ),
              MarkerLayer(markers: _markers()),
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
                    onChanged: _searchPlaces,
                    onSubmitted: _submitSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText:
                          'Search universities, clubs, streets, or places',
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
                                onTap: () => _choosePlace(result),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (searchResults.isEmpty)
            Positioned(
              top: 78,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  const _MapLegend(
                    color: AppTheme.nightBordeaux,
                    label: 'Lost',
                  ),
                  const SizedBox(width: 8),
                  const _MapLegend(color: AppTheme.coolHorizon, label: 'Found'),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.ivoryMist.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Text(
                        'Egypt reports',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            right: 16,
            bottom: 62,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onPressed: () => _zoomBy(1),
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onPressed: () => _zoomBy(-1),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'home-current-location',
                  onPressed: isLocating ? null : _goToCurrentLocation,
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
          const Positioned(left: 16, bottom: 16, child: _MapHint()),
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

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
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

class _MapSearchResult {
  const _MapSearchResult({required this.label, required this.point});

  final String label;
  final LatLng point;
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.ivoryMist.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
    ),
  );
}

class _MapHint extends StatelessWidget {
  const _MapHint();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.ivoryMist.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 17,
            color: AppTheme.nightBordeaux,
          ),
          SizedBox(width: 6),
          Text('Tap a pin for details'),
        ],
      ),
    ),
  );
}

class ItemPreviewSheet extends StatelessWidget {
  const ItemPreviewSheet({super.key, required this.item});
  final LostFoundReport item;

  @override
  Widget build(BuildContext context) {
    final isLost = item.type.isLost;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: const BoxDecoration(
          color: AppTheme.ivoryMist,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isLost
                      ? AppTheme.nightBordeaux
                      : AppTheme.coolHorizon,
                  child: Icon(
                    isLost ? Icons.search : Icons.check,
                    color: AppTheme.ivoryMist,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.nightBordeaux,
                    ),
                  ),
                ),
                Text(
                  item.type.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.nightBordeaux,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (item.photoData != null || item.photoUrl != null) ...[
              _PopupImage(item: item),
              const SizedBox(height: 16),
            ],
            Text(
              item.description,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(item.category)),
                Chip(label: Text(item.location)),
                Chip(label: Text(item.time)),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailsScreen(item: item),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open full details'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailsScreen(item: item),
                    ),
                  );
                },
                icon: const Icon(Icons.mail_outline),
                label: const Text('Contact the poster'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopupImage extends StatelessWidget {
  const _PopupImage({required this.item});

  final LostFoundReport item;

  @override
  Widget build(BuildContext context) {
    if (item.photoData == null &&
        item.photoUrl == null &&
        item.category.toLowerCase().contains('bag')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/products/bag.png',
          width: double.infinity,
          height: 150,
          fit: BoxFit.contain,
        ),
      );
    }
    if (item.photoData != null) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            base64Decode(item.photoData!),
            width: double.infinity,
            height: 150,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        item.photoUrl!,
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          height: 60,
          child: Center(child: Text('Image unavailable')),
        ),
      ),
    );
  }
}
