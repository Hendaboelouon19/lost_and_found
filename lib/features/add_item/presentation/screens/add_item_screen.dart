import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:errasoft/features/auth/register/home/data/models/lost_found_report.dart';
import 'package:errasoft/features/auth/register/home/presentation/cubit/home_cubit.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final timeController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();
  String reportType = 'Lost';

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    timeController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report item')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'Electronics, Keys, Bag...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Gate 3, Library, Parking',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    hintText: 'Today, 5:30 PM',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Add photo'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final newReport = LostFoundReport(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim().isNotEmpty ? titleController.text.trim() : 'Untitled item',
                      type: reportType == 'Found' ? ReportType.found : ReportType.lost,
                      category: categoryController.text.trim().isNotEmpty ? categoryController.text.trim() : 'General',
                      location: locationController.text.trim().isNotEmpty ? locationController.text.trim() : 'Unknown',
                      time: timeController.text.trim().isNotEmpty ? timeController.text.trim() : 'Today',
                      description: descriptionController.text.trim().isNotEmpty
                          ? descriptionController.text.trim()
                          : 'No description provided.',
                    );

                    context.read<HomeCubit>().addReport(newReport);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$reportType item saved locally'),
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
    );
  }
}
