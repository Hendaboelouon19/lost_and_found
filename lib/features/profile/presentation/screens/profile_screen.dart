import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 48,
              child: Icon(Icons.person, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'John Doe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'john.doe@email.com',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.shopping_bag_outlined),
                    title: Text('Orders'),
                    trailing: Text('12'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.favorite_outline),
                    title: Text('Favorites'),
                    trailing: Text('9'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.settings_outlined),
                    title: Text('Settings'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
