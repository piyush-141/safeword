import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/login_screen.dart';
import 'screens/vault_list_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling — dark icons on cream canvas
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppTheme.canvas,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // ─── Supabase Init ────────────────────────────────────────────────────────
  const url = 'https://coocdkwwllcoorvgiyix.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvb2Nka3d3bGxjb29ydmdpeWl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NTg1NjQsImV4cCI6MjA5MjUzNDU2NH0.jBqIQ2mEgh19urMP7A2Sn_KcXk7JZk5-3EHpVnbeTNk';

  debugPrint('DEBUG: Initializing Supabase with URL: $url');
  
  if (url.contains('YOUR_')) {
    throw Exception('CRITICAL ERROR: Supabase URL is still a placeholder!');
  }

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
    debug: true,
  );

  runApp(const SafeWordApp());
}

class SafeWordApp extends StatelessWidget {
  const SafeWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _Splash(),
    );
  }
}

/// Decides initial route based on auth state
class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Small delay to show splash
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // If user has a session and vault is unlocked → vault
    // If session but locked → login (re-enter master password)
    // If no session → login
    final isLoggedIn = AuthService.isLoggedIn;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            isLoggedIn ? const VaultListScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo — ink pill container with shield icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.ink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: AppTheme.canvas, size: 44),
            ),
            const SizedBox(height: 28),
            Text(
              AppConfig.appName,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 38,
                fontWeight: FontWeight.w500,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Zero-Knowledge Password Manager',
              style: TextStyle(color: AppTheme.slate, fontSize: 14),
            ),
            const SizedBox(height: 56),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppTheme.ink,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
