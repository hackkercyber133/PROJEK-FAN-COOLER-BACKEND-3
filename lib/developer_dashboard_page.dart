import 'package:flutter/material.dart';
import 'services/firebase_service.dart';

class DeveloperDashboardPage extends StatelessWidget {
  const DeveloperDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF090d14),
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: const Text('Developer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar dari mode developer',
            onPressed: () async {
              await svc.signOutDeveloper();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _CounterCard(
                    icon: Icons.ac_unit,
                    label: 'Cooler Online',
                    color: Colors.cyanAccent,
                    stream: svc.onlineCoolerCount(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CounterCard(
                    icon: Icons.phone_android,
                    label: 'HP Terinstall',
                    color: Colors.orangeAccent,
                    stream: svc.installedDeviceCount(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Daftar Akun Pengguna',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Password tidak ditampilkan di sini -- disimpan sebagai hash satu-arah dan tidak bisa dibaca ulang, bahkan oleh developer.',
              style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: svc.userList(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('Gagal memuat: ${snap.error}', style: const TextStyle(color: Colors.redAccent)),
                  );
                }
                final users = snap.data ?? [];
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Belum ada akun terdaftar.', style: TextStyle(color: Colors.white38)),
                  );
                }
                return Column(
                  children: users.map((u) => _UserTile(username: u['username'] as String)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Stream<int> stream;

  const _CounterCard({required this.icon, required this.label, required this.color, required this.stream});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snap) {
              final val = snap.data;
              return Text(
                val == null ? '-' : '$val',
                style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String username;
  const _UserTile({required this.username});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14181f),
        title: const Text('Hapus akun?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Akun "$username" akan dihapus dari server. '
          'Unit cooler fisiknya tetap perlu di-reset manual kalau ingin benar-benar melepas pairing-nya.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseService.instance.deleteUserAccount(username);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Akun "$username" dihapus.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.cyanAccent),
        title: Text(username, style: const TextStyle(color: Colors.white)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: 'Hapus akun',
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }
}
