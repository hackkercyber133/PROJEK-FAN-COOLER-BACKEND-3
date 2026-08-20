import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controller_page.dart';
import 'developer_login_page.dart';
import 'services/firebase_service.dart';

const String kBleCharacteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

// ===================================================================
// AUTH SCREEN — punya 2 tab:
//  1) LOGIN     : masuk pakai username & password yang sudah dibuat
//                 sebelumnya (dipakai lagi kalau login di HP lain).
//  2) DAFTAR    : "klaim" fan cooler yang baru pertama kali dipakai.
//                 Prosesnya: buat username & password baru -> scan
//                 Bluetooth -> pilih unit ESP32 fisik yang mau
//                 diklaim -> app kirim data itu ke ESP32 lewat BLE.
//                 ESP32 menyimpan akun itu secara permanen supaya
//                 selanjutnya hanya merespon username & password ini.
// ===================================================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090d14),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Tahan lama ikon ini untuk masuk sebagai developer.
            // Sengaja tidak ada tombol/menu terlihat untuk pengguna biasa.
            GestureDetector(
              onLongPress: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeveloperLoginPage()),
                );
              },
              child: const Icon(Icons.ac_unit_rounded, color: Colors.cyanAccent, size: 44),
            ),
            const SizedBox(height: 10),
            const Text(
              'COOLER CONTROLLER',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 20),
            ),
            const SizedBox(height: 4),
            const Text(
              'Setiap cooler punya akses sendiri',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.cyanAccent),
                ),
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'Login'),
                  Tab(text: 'Tambah Cooler Baru'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _LoginTab(),
                  _RegisterTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================= LOGIN =============================
class _LoginTab extends StatefulWidget {
  const _LoginTab();
  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _login() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi username dan password dulu')),
      );
      return;
    }
    setState(() => _loading = true);
    final hash = sha256.convert(utf8.encode(pass)).toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', user);
    await prefs.setString('passhash', hash);
    // Kirim username + hash password (bukan password asli) ke server,
    // supaya akun ini muncul di daftar developer.
    unawaited(FirebaseService.instance.upsertUser(username: user, passHash: hash));

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ControllerPage(username: user, passhash: hash)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _field(_userCtrl, 'Username', Icons.person, false),
          const SizedBox(height: 14),
          _field(_passCtrl, 'Password', Icons.lock, true),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _loading ? null : _login,
            icon: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.login),
            label: Text(_loading ? 'Memproses...' : 'Masuk'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum punya cooler yang diklaim? Buka tab "Tambah Cooler Baru".',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, bool isPassword) {
    return TextField(
      controller: c,
      obscureText: isPassword ? _obscure : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

// ============================ REGISTER ============================
class _RegisterTab extends StatefulWidget {
  const _RegisterTab();
  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

enum _RegisterStep { form, scanning, connecting, done }

class _RegisterTabState extends State<_RegisterTab> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  bool _obscure = true;

  _RegisterStep _step = _RegisterStep.form;
  List<ScanResult> _results = [];
  String _statusMsg = '';
  StreamSubscription<List<ScanResult>>? _scanSub;

  @override
  void dispose() {
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  bool _validateForm() {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (user.length < 3) {
      _snack('Username minimal 3 karakter');
      return false;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(user)) {
      _snack('Username cuma boleh huruf, angka, underscore (tanpa spasi)');
      return false;
    }
    if (pass.length < 4) {
      _snack('Password minimal 4 karakter');
      return false;
    }
    if (pass != _passConfirmCtrl.text) {
      _snack('Konfirmasi password tidak sama');
      return false;
    }
    return true;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _startScan() async {
    if (!_validateForm()) return;
    setState(() {
      _step = _RegisterStep.scanning;
      _results = [];
      _statusMsg = 'Mencari cooler di sekitar lewat Bluetooth...';
    });

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      setState(() {
        _results = results.where((r) => r.device.platformName.contains('ESP32')).toList();
      });
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
  }

  Future<void> _claimDevice(ScanResult result) async {
    setState(() {
      _step = _RegisterStep.connecting;
      _statusMsg = 'Menghubungkan ke ${result.device.platformName}...';
    });
    _scanSub?.cancel();
    await FlutterBluePlus.stopScan();

    try {
      await result.device.connect(timeout: const Duration(seconds: 10));
      final services = await result.device.discoverServices();

      BluetoothCharacteristic? target;
      for (var service in services) {
        for (var c in service.characteristics) {
          if (c.uuid.toString() == kBleCharacteristicUuid) target = c;
        }
      }

      if (target == null) {
        _fail('Unit ini bukan Cooler Controller yang cocok.');
        return;
      }

      final user = _userCtrl.text.trim();
      final pass = _passCtrl.text;
      final hash = sha256.convert(utf8.encode(pass)).toString();

      setState(() => _statusMsg = 'Mengirim data akun ke cooler...');

      // Dengarkan notifikasi balasan dari ESP32 (status registered:true)
      bool confirmed = false;
      await target.setNotifyValue(true);
      final sub = target.onValueReceived.listen((value) {
        final payload = utf8.decode(value);
        try {
          final data = jsonDecode(payload);
          if (data['registered'] == true && data['username'] == user) {
            confirmed = true;
          }
        } catch (_) {}
      });

      await target.write(utf8.encode(jsonEncode({
        'action': 'register',
        'username': user,
        'passhash': hash,
      })));

      // Tunggu balasan sampai beberapa detik
      final start = DateTime.now();
      while (!confirmed && DateTime.now().difference(start).inSeconds < 6) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      await sub.cancel();
      await result.device.disconnect();

      if (!confirmed) {
        _fail('Cooler tidak merespon. Kalau unit ini sudah pernah diklaim akun lain, harus di-erase & flash ulang dulu.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', user);
      await prefs.setString('passhash', hash);
      unawaited(FirebaseService.instance.upsertUser(username: user, passHash: hash));

      if (!mounted) return;
      setState(() {
        _step = _RegisterStep.done;
        _statusMsg = 'Berhasil! Cooler ini sekarang milik "$user".';
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ControllerPage(username: user, passhash: hash)),
      );
    } catch (e) {
      _fail('Gagal menghubungkan ke cooler. Coba lagi.');
    }
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() {
      _step = _RegisterStep.form;
      _statusMsg = '';
    });
    _snack(msg);
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _RegisterStep.form) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            const Text(
              'Buat akun untuk fan cooler kamu. Setelah dibuat, tempel HP dekat ESP32 (Bluetooth) untuk mengklaim unit itu jadi milikmu.',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 18),
            _field(_userCtrl, 'Username baru', Icons.person_add, false),
            const SizedBox(height: 14),
            _field(_passCtrl, 'Password baru', Icons.lock, true),
            const SizedBox(height: 14),
            _field(_passConfirmCtrl, 'Konfirmasi password', Icons.lock_outline, true),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Scan & Klaim Cooler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    if (_step == _RegisterStep.scanning) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Text(_statusMsg, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.cyanAccent),
                        SizedBox(height: 14),
                        Text('Mencari...', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (ctx, i) {
                      final r = _results[i];
                      return Card(
                        color: Colors.grey.shade900,
                        child: ListTile(
                          leading: const Icon(Icons.developer_board, color: Colors.cyanAccent),
                          title: Text(
                            r.device.platformName.isEmpty ? '(Tanpa nama)' : r.device.platformName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text('${r.rssi} dBm', style: const TextStyle(color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                          onTap: () => _claimDevice(r),
                        ),
                      );
                    },
                  ),
          ),
          TextButton(
            onPressed: () {
              _scanSub?.cancel();
              FlutterBluePlus.stopScan();
              setState(() => _step = _RegisterStep.form);
            },
            child: const Text('Batal'),
          ),
        ],
      );
    }

    // connecting / done
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _step == _RegisterStep.done
                ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 56)
                : const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 18),
            Text(_statusMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, bool isPassword) {
    return TextField(
      controller: c,
      obscureText: isPassword ? _obscure : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

