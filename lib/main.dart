import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Catat bahwa HP ini pernah membuka aplikasi (untuk dashboard developer).
  // Tidak menyimpan data pribadi apa pun, cuma ID acak + waktu buka.
  FirebaseService.instance.registerDeviceOpen();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cooler Controller',
      theme: ThemeData.dark(),
      home: const SplashScreen(),
    );
  }
}
