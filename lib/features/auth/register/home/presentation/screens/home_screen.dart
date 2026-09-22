import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:errasoft/core/utils/local_storage.dart';
import 'package:errasoft/features/add_item/presentation/screens/add_item_screen.dart';
import 'package:errasoft/features/auth/login/presentation/screens/login_screen.dart';
import 'package:errasoft/features/auth/register/home/data/models/lost_found_report.dart';
import 'package:errasoft/features/auth/register/home/presentation/cubit/home_cubit.dart';
import 'package:errasoft/features/item_details/presentation/screens/item_details_screen.dart';
import 'package:errasoft/features/profile/presentation/screens/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit()..loadItems(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lost & Found'),
          actions: [
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
              MaterialPageRoute(builder: (_) => const AddItemScreen()),
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
                  const Text(
                    'Recent reports',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        ChoiceChip(label: Text('All'), selected: true),
                        SizedBox(width: 8),
                        ChoiceChip(label: Text('Lost'), selected: false),
                        SizedBox(width: 8),
                        ChoiceChip(label: Text('Found'), selected: false),
                        SizedBox(width: 8),
                        ChoiceChip(label: Text('Electronics'), selected: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...state.items.map((item) {
                    final type = item.type.label;
                    final match = item.matchProbability ?? 0.0;
                    final isLost = item.type.isLost;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: isLost ? Colors.orange.shade100 : Colors.green.shade100,
                          child: Icon(
                            isLost ? Icons.search : Icons.check_circle_outline,
                            color: isLost ? Colors.orange : Colors.green,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLost ? Colors.orange.shade100 : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: isLost ? Colors.orange.shade900 : Colors.green.shade900,
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
                              Text('${item.category} • ${item.location}'),
                              const SizedBox(height: 4),
                              Text(item.time),
                              const SizedBox(height: 8),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Match probability: ${match.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailsScreen(item: item),
                            ),
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
    );
  }
}
