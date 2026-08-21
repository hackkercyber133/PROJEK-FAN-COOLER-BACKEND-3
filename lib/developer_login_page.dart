import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'developer_dashboard_page.dart';

// ===================================================================
// DEVELOPER LOGIN
// Halaman ini SENGAJA tidak muncul di menu mana pun untuk pengguna
// biasa. Satu-satunya jalan masuk adalah ikon kecil tersembunyi di
// pojok AuthScreen (lihat auth_screen.dart -> long-press logo).
// ===================================================================
class DeveloperLoginPage extends StatefulWidget {
  const DeveloperLoginPage({super.key});

  @override
  State<DeveloperLoginPage> createState() => _DeveloperLoginPageState();
}

class _DeveloperLoginPageState extends State<DeveloperLoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (user.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Isi username dan password developer.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final err = await FirebaseService.instance.signInAsDeveloper(username: user, password: pass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      setState(() => _error = err);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DeveloperDashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090d14),
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: const Text('Developer Access'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.admin_panel_settings, color: Colors.orangeAccent, size: 48),
              const SizedBox(height: 10),
              const Text(
                'Halaman ini khusus developer aplikasi.\nBukan untuk pengguna biasa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _userCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Username developer', Icons.person),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Password developer', Icons.lock).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _loading ? null : _login,
                icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.login),
                label: Text(_loading ? 'Memeriksa...' : 'Masuk sebagai Developer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.orangeAccent),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
