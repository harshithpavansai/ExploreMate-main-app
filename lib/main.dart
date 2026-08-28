import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_console_screen.dart';
import 'themes/app_theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Background message handler — must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('[FCM] Background message: ${message.notification?.title}');
}

Future<void> _initFCM() async {
  final messaging = FirebaseMessaging.instance;

  // Request permission
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    final token = await messaging.getToken();
    log('[FCM] Token: $token');
  }

  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Foreground handler — show in-app snackbar (via global key)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    log('[FCM] Foreground message: ${message.notification?.title}');
    // Can show an in-app notification overlay here
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize push notifications
  await _initFCM();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF07111F),
    ),
  );
  runApp(const ExploreMateApp());
}

class ExploreMateApp extends StatelessWidget {
  const ExploreMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'ExploreMate',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: state.themeMode,
            home: const SplashScreen(),
            routes: {
              '/onboarding': (_) => const OnboardingScreen(),
              '/login': (_) => const LoginScreen(),
              '/signup': (_) => const SignupScreen(),
              '/home': (_) => const HomeScreen(),
              '/admin': (_) => const AdminConsoleScreen(),
            },
          );
        },
      ),
    );
  }
}
