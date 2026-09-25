import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:errasoft/features/auth/register/home/data/models/lost_found_report.dart';
import 'package:errasoft/features/auth/register/home/presentation/cubit/home_cubit.dart';
import 'package:errasoft/features/add_item/presentation/screens/location_picker_screen.dart';
import 'package:errasoft/themes/app_theme.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final timeController = TextEditingController();
  final descriptionController = TextEditingController();
  String reportType = 'Lost';
  String selectedCategory = 'Electronics';
  String? selectedPlace;
  LatLng? selectedCoordinates;
  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  bool isDetectingLocation = true;
  final formKey = GlobalKey<FormState>();

  static const categories = [
    'Electronics',
    'Bags',
    'Keys',
    'Documents',
    'Accessories',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
  }

  Future<void> _detectCurrentLocation() async {
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
      setState(() {
        selectedPlace = 'Current location';
        selectedCoordinates = LatLng(position.latitude, position.longitude);
        locationController.text =
            'Current location (${position.latitude.toStringAsFixed(4)}, '
            '${position.longitude.toStringAsFixed(4)})';
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => isDetectingLocation = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    timeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    timeController.text =
        '${date.day}/${date.month}/${date.year}, $hour:$minute $period';
  }

  Future<void> _pickLocation() async {
    final selected = await Navigator.push<SelectedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LocationPickerScreen(initialPosition: selectedCoordinates),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      selectedPlace = selected.label;
      selectedCoordinates = selected.position;
    });
    locationController.text =
        '${selected.label} (${selected.position.latitude.toStringAsFixed(4)}, ${selected.position.longitude.toStringAsFixed(4)})';
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Add item photo',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 55,
      maxWidth: 720,
    );
    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 700000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This image is too large to save without Storage.'),
        ),
      );
      return;
    }
    setState(() {
      selectedImage = image;
      selectedImageBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report item')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Report an item',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.nightBordeaux,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Give people enough detail to recognize it.',
                    style: TextStyle(
                      color: AppTheme.nightBordeaux.withValues(alpha: .65),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Lost', label: Text('Lost')),
                      ButtonSegment(value: 'Found', label: Text('Found')),
                    ],
                    selected: {reportType},
                    onSelectionChanged: (value) {
                      setState(() => reportType = value.first);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Item name',
                       hintText: 'What are you looking for?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => selectedCategory = value ?? selectedCategory,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locationController,
                    readOnly: true,
                    onTap: _pickLocation,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Where was it?',
                      hintText: 'Gate 3, Library, Parking',
                      suffixIcon: isDetectingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                           : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: timeController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'When did it happen?',
                      hintText: 'Select date and time',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Color, identifying marks, and what was inside',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (selectedImageBytes == null)
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Add photo'),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            selectedImageBytes!,
                            height: 190,
                            fit: BoxFit.cover,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(selectedImage?.name ?? 'Change photo'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty ||
                          locationController.text.trim().isEmpty ||
                          descriptionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Add the item name, location, and description first.',
                            ),
                          ),
                        );
                        return;
                      }
                      final newReport = LostFoundReport(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text.trim().isNotEmpty
                            ? titleController.text.trim()
                            : 'Untitled item',
                        type: reportType == 'Found'
                            ? ReportType.found
                            : ReportType.lost,
                        category: selectedCategory,
                        latitude: selectedCoordinates?.latitude,
                        longitude: selectedCoordinates?.longitude,
                        photoData: selectedImageBytes == null
                            ? null
                            : base64Encode(selectedImageBytes!),
                        location: locationController.text.trim().isNotEmpty
                            ? locationController.text.trim()
                            : 'Unknown',
                        time: timeController.text.trim().isNotEmpty
                            ? timeController.text.trim()
                            : 'Today',
                        description:
                            descriptionController.text.trim().isNotEmpty
                            ? descriptionController.text.trim()
                            : 'No description provided.',
                      );

                      context.read<HomeCubit>().addReport(newReport);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$reportType item saved. We will notify you about strong matches.',
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Submit report'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
