import 'package:flutter/material.dart';

import 'package:errasoft/core/utils/local_storage.dart';
import 'package:errasoft/themes/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _matchAlertsEnabled = true;
  bool _alertsLoaded = false;

  Future<_ProfileDetails> _loadProfile() async {
    final storage = LocalStorage.instance;
    if (!_alertsLoaded) {
      _matchAlertsEnabled = await storage.getMatchAlertsEnabled();
      _alertsLoaded = true;
    }
    final name = await storage.getUserName();
    final email = await storage.getUserEmail();
    final userId = await storage.getUserId();
    return _ProfileDetails(
      name: name?.trim().isNotEmpty == true ? name! : 'Your profile',
      email: email?.trim().isNotEmpty == true
          ? email!
          : 'Account details unavailable',
      userId: userId ?? 'local account',
    );
  }

  void _showVerification() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trust and verification'),
        content: const Text(
          'Complete your profile and add clear item details to build trust with the community. Verification will be available when account services are connected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMatchAlerts() async {
    final nextValue = !_matchAlertsEnabled;
    setState(() => _matchAlertsEnabled = nextValue);
    await LocalStorage.instance.saveMatchAlertsEnabled(nextValue);
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Settings'),
              subtitle: Text('Manage how Returna works for you'),
            ),
            SwitchListTile(
              value: _matchAlertsEnabled,
              onChanged: (_) => _toggleMatchAlerts(),
              title: const Text('Match alerts'),
              subtitle: const Text('Receive updates when a report looks similar'),
            ),
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Privacy'),
              subtitle: Text('Your contact details stay private until you connect'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<_ProfileDetails>(
        future: _loadProfile(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!;
          final initials = profile.name
              .trim()
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.nightBordeaux,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppTheme.ivoryMist,
                      child: Text(
                        initials.isEmpty ? 'P' : initials,
                        style: const TextStyle(
                          color: AppTheme.nightBordeaux,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: AppTheme.ivoryMist,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.email,
                            style: TextStyle(
                              color: AppTheme.ivoryMist.withValues(alpha: .72),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Community member',
                            style: TextStyle(
                              color: AppTheme.coolHorizon.withValues(alpha: .95),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Your activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.nightBordeaux,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(child: _ActivityMetric(value: '0', label: 'Reports')),
                  SizedBox(width: 12),
                  Expanded(child: _ActivityMetric(value: '0', label: 'Matches')),
                  SizedBox(width: 12),
                  Expanded(child: _ActivityMetric(value: '0', label: 'Resolved')),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.nightBordeaux,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: const Text('Trust and verification'),
                      subtitle: const Text('Build confidence with complete reports'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showVerification,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_none),
                      title: const Text('Match alerts'),
                      subtitle: Text(
                        _matchAlertsEnabled
                            ? 'Enabled for possible matches'
                            : 'Currently paused',
                      ),
                      trailing: Switch(
                        value: _matchAlertsEnabled,
                        onChanged: (_) => _toggleMatchAlerts(),
                      ),
                      onTap: _toggleMatchAlerts,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showSettings,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Account ID: ${profile.userId}',
                style: TextStyle(color: AppTheme.nightBordeaux.withValues(alpha: .5)),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileDetails {
  const _ProfileDetails({
    required this.name,
    required this.email,
    required this.userId,
  });

  final String name;
  final String email;
  final String userId;
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.nightBordeaux,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
