import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===================================================================
// FIREBASE SERVICE
// -------------------------------------------------------------------
// Satu tempat untuk semua akses Firebase (Auth + Firestore).
//
// PRINSIP KEAMANAN YANG DIPAKAI DI SINI (jangan diubah sembarangan):
//  1. Password akun pengguna TIDAK PERNAH disimpan dalam bentuk asli.
//     Yang dikirim ke Firestore hanya SHA-256 hash-nya (`passHash`).
//     Bahkan developer/admin tidak bisa membaca password asli siapa
//     pun lewat aplikasi ini -- yang bisa dilihat cuma daftar
//     username, kapan dibuat, dan status cooler-nya.
//  2. Login developer memakai Firebase Authentication (email/password)
//     yang sungguhan divalidasi oleh server Firebase, BUKAN sekadar
//     `if (user == "admin12")` di kode Dart. Kalau memakai cara kedua,
//     siapa pun yang decompile APK bisa lihat/patch pengecekan itu.
//     Dengan Firebase Auth, validasinya terjadi di server Google, jadi
//     tidak bisa dibypass hanya dengan baca kode aplikasi.
//  3. Siapa yang boleh buka data developer diatur DUA LAPIS:
//       a. Di aplikasi: halaman dashboard developer hanya bisa dibuka
//          setelah `signInAsDeveloper()` berhasil.
//       b. Di server (WAJIB): Firestore Security Rules (lihat file
//          `firestore.rules` di root project) yang menolak semua
//          pembacaan koleksi `users`/`devices`/`coolers` kecuali UID
//          yang login terdaftar di koleksi `admins`. Lapis ini yang
//          betul-betul mencegah orang lain membaca data walau dia
//          tahu URL/API key Firebase kamu.
// ===================================================================
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _devEmailDomain = 'developer.coolerapp.local';

  String _hash(String plain) => sha256.convert(utf8.encode(plain)).toString();

  // ===================== AKUN PENGGUNA (COOLER) =====================

  /// Dipanggil saat login / register berhasil di sisi lokal, supaya
  /// developer bisa melihat daftar username yang pernah dipakai.
  /// Hanya `passHash` yang dikirim -- bukan password asli.
  Future<void> upsertUser({required String username, required String passHash}) async {
    final ref = _db.collection('users').doc(username);
    final snap = await ref.get();
    await ref.set({
      'username': username,
      'passHash': passHash,
      'createdAt': snap.exists ? snap.data()!['createdAt'] : FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===================== HEARTBEAT COOLER (ON/OFF) ====================

  /// Dipanggil tiap kali status koneksi ke cooler berubah (online lewat
  /// MQTT/BLE) supaya dashboard developer bisa menghitung berapa cooler
  /// yang sedang menyala.
  Future<void> setCoolerStatus({required String username, required bool online}) async {
    await _db.collection('coolers').doc(username).set({
      'username': username,
      'online': online,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Panggil berkala (mis. tiap 30 detik selagi ControllerPage aktif)
  /// supaya "online" tidak nyangkut true selamanya kalau app di-kill
  /// paksa. Dashboard menganggap cooler offline kalau lastSeenAt sudah
  /// lebih lama dari [staleAfter].
  Future<void> heartbeatCooler(String username) => setCoolerStatus(username: username, online: true);

  static const Duration staleAfter = Duration(minutes: 2);

  // ===================== REGISTRASI PERANGKAT (HP) =====================

  /// Dipanggil sekali tiap app dibuka, supaya developer tahu berapa HP
  /// unik yang pernah install & buka aplikasi ini. ID perangkat dibuat
  /// acak dan disimpan lokal -- bukan data pribadi.
  Future<void> registerDeviceOpen() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('device_anon_id');
    if (deviceId == null) {
      deviceId = DateTime.now().microsecondsSinceEpoch.toString() +
          '-' +
          (DateTime.now().hashCode ^ identityHashCode(prefs)).toString();
      await prefs.setString('device_anon_id', deviceId);
    }
    await _db.collection('devices').doc(deviceId).set({
      'deviceId': deviceId,
      'firstSeenAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ========================= DEVELOPER LOGIN =========================

  bool get isDeveloperLoggedIn => _auth.currentUser != null;

  /// Login developer pakai username, bukan email -- di-internal-kan jadi
  /// email dummy `<username>@developer.coolerapp.local` supaya bisa
  /// dipakai dengan Firebase Auth (yang butuh format email).
  /// Akun developer-nya sendiri harus dibuat DULU lewat Firebase
  /// Console (bukan lewat app ini), lihat README bagian "Setup Firebase".
  Future<String?> signInAsDeveloper({required String username, required String password}) async {
    try {
      final email = '${username.trim().toLowerCase()}@$_devEmailDomain';
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // sukses
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          return 'Username atau password developer salah.';
        default:
          return 'Login gagal (${e.code}).';
      }
    } catch (_) {
      return 'Login gagal. Cek koneksi internet.';
    }
  }

  Future<void> signOutDeveloper() => _auth.signOut();

  // ===================== DATA UNTUK DASHBOARD =====================

  /// Jumlah cooler yang statusnya online & belum basi (masih heartbeat).
  Stream<int> onlineCoolerCount() {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(staleAfter));
    return _db
        .collection('coolers')
        .where('online', isEqualTo: true)
        .where('lastSeenAt', isGreaterThan: cutoff)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Jumlah HP unik yang pernah membuka aplikasi ini.
  Stream<int> installedDeviceCount() {
    return _db.collection('devices').snapshots().map((s) => s.docs.length);
  }

  /// Daftar username (TANPA password/hash ditampilkan di UI manapun).
  Stream<List<Map<String, dynamic>>> userList() {
    return _db.collection('users').orderBy('createdAt', descending: true).snapshots().map(
          (s) => s.docs.map((d) => {'username': d.id, ...d.data()}).toList(),
        );
  }

  /// Hapus akun pengguna dari database pusat. Ini TIDAK mencabut
  /// pairing BLE yang sudah tersimpan permanen di flash ESP32 -- unit
  /// fisiknya tetap perlu di-reset manual kalau mau benar-benar lepas
  /// dari akun itu. Ini hanya menghapus akun dari sisi server/app.
  Future<void> deleteUserAccount(String username) async {
    await _db.collection('users').doc(username).delete();
    await _db.collection('coolers').doc(username).delete();
  }
}
