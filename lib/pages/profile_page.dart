import 'package:flutter/material.dart';
import '../app/app_state.dart';
import '../app/app_theme.dart';
import '../widgets/stat_card.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _editProfile() async {
    final app = AppState.instance;
    final nameController = TextEditingController(text: app.name);
    final emailController = TextEditingController(text: app.email);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newName = nameController.text.trim();
      final newEmail = emailController.text.trim();
      if (newName.isNotEmpty && newEmail.contains('@')) {
        app.updateProfile(newName, newEmail);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama dan email harus diisi dengan benar.')),
        );
      }
    }
    nameController.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kOrange.withValues(alpha: 0.35), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: kOrange.withValues(alpha: 0.13),
                      child: const Icon(Icons.person_rounded, size: 48, color: kOrange),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(app.name,
                      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(app.email, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profil'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.route_rounded,
                  label: 'Jarak',
                  value: '${app.totalDistance.toStringAsFixed(1)} km',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.fitness_center_rounded,
                  label: 'Aktivitas',
                  value: '${app.activities.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Pengaturan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengaturan akan dikembangkan berikutnya.')),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Tentang StraFit'),
                  subtitle: const Text('Track your move. Improve your pace.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'StraFit',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Proyek Pemrograman Aplikasi Bergerak',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text('Keluar', style: TextStyle(color: Colors.red)),
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
