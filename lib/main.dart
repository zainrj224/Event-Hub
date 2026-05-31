import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/presentation/screens/sign_in_screen.dart';
import 'core/cache/cache_service.dart';
import 'main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Init cache — wrapped so a missing package never blanks the app
  try {
    await CacheService.instance.init();
  } catch (_) {}

  runApp(const EventHubApp());
}

class EventHubApp extends StatelessWidget {
  const EventHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeNotifier.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Event Hub',
          debugShowCheckedModeBanner: false,
          // ✅ After
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeNotifier.instance.value,
          onGenerateRoute: AppRoutes.generateRoute,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// AuthGate as StatefulWidget — critical fix.
///
/// As StatelessWidget, build() is called many times. Each call passes a
/// potentially new authStateChanges() Stream object to StreamBuilder.
/// StreamBuilder compares streams by identity: a new object means it cancels
/// the old subscription and creates a new one, briefly emitting
/// ConnectionState.waiting. During Flutter Web route transitions, build() fires
/// rapidly → multiple subscriptions pile up → CanvasKit is overwhelmed → freeze.
///
/// As StatefulWidget, the stream is created ONCE in initState() and reused,
/// so StreamBuilder never resubscribes unnecessarily.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final Stream<User?> _authStream = FirebaseAuth.instance.authStateChanges();
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const SplashScreen();

    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(); // also shows during auth check
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShell();
        }
        return const SignInScreen();
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _dotScale;
  late Animation<double> _dotOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Text fades in first
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    // Dot pops in with a bounce after text
    _dotScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
    ));

    _dotOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.65, curve: Curves.easeIn),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // "Event Hub" fades in
            FadeTransition(
              opacity: _fadeIn,
              child: const Text(
                'Event Hub',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Lime dot bounces in after
            FadeTransition(
              opacity: _dotOpacity,
              child: ScaleTransition(
                scale: _dotScale,
                child: const Text(
                  '.',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD4F14E),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
