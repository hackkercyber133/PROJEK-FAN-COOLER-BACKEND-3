import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'controller_page.dart';

// ===================================================================
// SPLASH SCREEN — animasi pembuka gaya "gaming" (mirip intro Mobile
// Legends / Free Fire): logo berputar dengan glow neon, judul muncul
// dengan efek scale + shimmer, lalu otomatis pindah ke halaman
// berikutnya (Login kalau belum pernah login, atau langsung ke
// Controller kalau sudah ada akun tersimpan di HP).
// ===================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _glowController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _creditOpacity;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut);
    _logoOpacity = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _titleOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)),
    );
    _subtitleOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _creditOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _logoController.forward();
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    await _goNext();
  }

  Future<void> _goNext() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final passhash = prefs.getString('passhash');
    if (!mounted) return;

    Widget next;
    if (username != null && username.isNotEmpty && passhash != null && passhash.isNotEmpty) {
      next = ControllerPage(username: username, passhash: passhash);
    } else {
      next = const AuthScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, anim, __) => next,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.3,
            colors: [Color(0xFF102436), Color(0xFF05070c), Color(0xFF000000)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Partikel garis-garis diagonal tipis di background (nuansa gaming HUD)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ringController,
                builder: (_, __) => CustomPaint(painter: _HudLinesPainter(_ringController.value)),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ===== LOGO + RING BERPUTAR + GLOW =====
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_ringController, _glowController]),
                        builder: (context, child) {
                          final glow = 18 + (_glowController.value * 22);
                          return Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.55),
                                  blurRadius: glow,
                                  spreadRadius: glow / 6,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.rotate(
                                  angle: _ringController.value * 2 * math.pi,
                                  child: CustomPaint(
                                    size: const Size(168, 168),
                                    painter: _NeonRingPainter(),
                                  ),
                                ),
                                Transform.rotate(
                                  angle: -_ringController.value * 2 * math.pi * 1.6,
                                  child: CustomPaint(
                                    size: const Size(128, 128),
                                    painter: _NeonRingPainter(
                                      color: Colors.blueAccent,
                                      strokeWidth: 2,
                                      gapFraction: 0.55,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF00E5FF), Color(0xFF0057B7)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withOpacity(0.6),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 46),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),

                  // ===== JUDUL =====
                  ClipRect(
                    child: SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleOpacity,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF7CF9FF), Color(0xFF37B9FF), Color(0xFF7CF9FF)],
                          ).createShader(bounds),
                          child: const Text(
                            'COOLER CONTROLLER',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.cyanAccent, blurRadius: 22),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _subtitleOpacity,
                    child: Text(
                      'VOLTAGE CONTROL SYSTEM',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 5,
                        color: Colors.cyanAccent.withOpacity(0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== KREDIT DEVELOPER =====
            Positioned(
              bottom: 42,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _creditOpacity,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 1.4,
                      color: Colors.cyanAccent.withOpacity(0.4),
                      margin: const EdgeInsets.only(bottom: 10),
                    ),
                    const Text(
                      'DEVELOPED BY',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 3,
                        color: Colors.white38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'M.ADY AFRIANSYAH',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 2,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ring neon putus-putus yang berputar, seperti loading ring game.
class _NeonRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gapFraction;

  _NeonRingPainter({
    this.color = Colors.cyanAccent,
    this.strokeWidth = 3,
    this.gapFraction = 0.35,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(strokeWidth, strokeWidth, size.width - strokeWidth * 2, size.height - strokeWidth * 2);
    final sweep = (1 - gapFraction) * 2 * math.pi;
    canvas.drawArc(rect, 0, sweep, false, paint);
    canvas.drawArc(rect, math.pi, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Garis-garis diagonal tipis yang bergerak pelan di background, kesan HUD.
class _HudLinesPainter extends CustomPainter {
  final double t;
  _HudLinesPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.045)
      ..strokeWidth = 1;
    const gap = 46.0;
    final offset = (t * gap) % gap;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
        Offset(x + offset, 0),
        Offset(x + offset - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HudLinesPainter oldDelegate) => oldDelegate.t != t;
}

