import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../app_colors.dart';
import '../providers/app_state.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController orbit;
  late final AnimationController reveal;

  @override
  void initState() {
    super.initState();
    orbit = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    final loginCheck = _checkLoginState();
    
    await Future.delayed(const Duration(milliseconds: 2600));
    
    if (!mounted) return;
    
    final destination = await loginCheck;
    
    if (!mounted) return;
    
    if (destination == '/home') {
      try {
        await Provider.of<AppState>(context, listen: false).loadUserData();
      } catch (e) {
        debugPrint('Error loading user data in splash: $e');
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  Future<String> _checkLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool rememberMe = prefs.getBool('remember_me') ?? false;
      final user = FirebaseAuth.instance.currentUser;
      
      if (rememberMe && user != null) {
        return '/home';
      } else {
        if (user != null) {
          await FirebaseAuth.instance.signOut();
          const storage = FlutterSecureStorage();
          await storage.delete(key: 'jwt_token');
        }
      }
    } catch (e) {
      debugPrint('Error checking login state in splash screen: $e');
    }
    return '/onboarding';
  }

  @override
  void dispose() {
    orbit.dispose();
    reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.auroraGradient),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: orbit,
              builder: (_, __) => CustomPaint(size: Size.infinite, painter: _OrbitPainter(orbit.value)),
            ),
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: reveal, curve: Curves.easeOutBack),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        color: Colors.white.withValues(alpha: 0.12),
                        border: Border.all(color: Colors.white30),
                        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: .34), blurRadius: 42)],
                      ),
                      child: const Icon(Icons.explore_rounded, color: Colors.white, size: 66),
                    ),
                    const SizedBox(height: 28),
                    const Text('ExploreMate', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text('AI travel intelligence online', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 34),
                    const SizedBox(width: 160, child: LinearProgressIndicator(minHeight: 3, color: AppColors.accent)),
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

class _OrbitPainter extends CustomPainter {
  final double progress;
  _OrbitPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    for (var i = 0; i < 5; i++) {
      final radius = 92.0 + i * 42;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: .05),
      );
      final angle = progress * math.pi * 2 + i * .9;
      final dot = Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
      canvas.drawCircle(dot, 3.5, Paint()..color = i.isEven ? AppColors.accent : AppColors.secondary);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) => oldDelegate.progress != progress;
}
