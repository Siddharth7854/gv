import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/theme/gov_theme.dart';
import 'services/notification_manager.dart';

import 'providers/simple_auth_provider.dart';
import 'providers/simple_auth_state.dart';
import 'providers/admin_providers_fix.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/onboarding_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => navigatorKey,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase conditionally (skip on Windows to avoid C++ SDK issues)
  try {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('🔥 Firebase initialized successfully');
    } else {
      debugPrint(
        '⏭️ Skipping Firebase on $defaultTargetPlatform - using mock services',
      );
    }
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    debugPrint('🔄 Continuing with mock services...');
  }

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Notification Manager (handles Firebase FCM + Cross-Platform)
  try {
    await NotificationManager.initialize();
    debugPrint('🔔 Notification Manager initialized successfully');
  } catch (e) {
    debugPrint('❌ Notification Manager initialization failed: $e');
  }

  runApp(const ProviderScope(child: GrievanceApp()));
}

class GrievanceApp extends ConsumerWidget {
  const GrievanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Government Grievance Portal',
      theme: GovTheme.lightTheme,
      darkTheme: GovTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      navigatorKey: ref.watch(navigatorKeyProvider),
      home: const AppWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        // Add other named routes as needed
      },
    );
  }
}

class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> {
  bool _hasCheckedAuth = false;
  bool _isCheckingOnboarding = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[AppWrapper] initState - calling checkAuthStatus (after onboarding)',
    );
    // First check onboarding status
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      debugPrint('[AppWrapper] Checking onboarding status...');
      final isComplete = await OnboardingService.isOnboardingComplete();

      if (mounted) {
        setState(() {
          _showOnboarding = !isComplete;
          _isCheckingOnboarding = false;
        });

        debugPrint('[AppWrapper] Onboarding complete: $isComplete');

        if (isComplete) {
          debugPrint('[AppWrapper] Onboarding complete, checking auth...');
          // Only check auth if onboarding is complete
          ref.read(simpleAuthProvider.notifier).checkAuthStatus();
        }
      }
    } catch (e) {
      debugPrint('[AppWrapper] Error checking onboarding: $e');
      if (mounted) {
        setState(() {
          _showOnboarding = true; // Show onboarding on error
          _isCheckingOnboarding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth states
    final userAuth = ref.watch(simpleAuthProvider);
    final adminAuth = ref.watch(adminAuthProvider);

    debugPrint(
      '[AppWrapper] Build called - userAuth: $userAuth, adminAuth: $adminAuth',
    );

    // Show loading during initial checks
    if (_isCheckingOnboarding) {
      debugPrint('[AppWrapper] Still checking onboarding...');
      return const SplashScreen();
    }

    // Show onboarding if not completed
    if (_showOnboarding) {
      debugPrint('[AppWrapper] Showing onboarding screen');
      return OnboardingScreen(
        onComplete: () async {
          await OnboardingService.setOnboardingComplete();
          setState(() {
            _showOnboarding = false;
          });
          // After onboarding, check auth
          ref.read(simpleAuthProvider.notifier).checkAuthStatus();
        },
      );
    }

    // Listen to auth state changes
    ref.listen<SimpleAuthState>(simpleAuthProvider, (previous, next) {
      debugPrint(
        '[AppWrapper] User auth state changed from $previous to $next',
      );

      if (!_hasCheckedAuth && !next.isLoading) {
        setState(() {
          _hasCheckedAuth = true;
        });
      }
    });

    // Show loading while checking auth
    if (!_hasCheckedAuth || userAuth.isLoading) {
      debugPrint('[AppWrapper] Checking auth or loading...');
      return const SplashScreen();
    }

    debugPrint('[AppWrapper] User auth runtime type: ${userAuth.runtimeType}');

    // Navigate based on auth status
    if (adminAuth.isAuthenticated) {
      debugPrint('[AppWrapper] Showing AdminDashboard');
      return const AdminDashboardScreen();
    } else if (userAuth.isAuthenticated && userAuth.user != null) {
      debugPrint(
        '[AppWrapper] Showing HomeScreen for user: ${userAuth.user!.name}',
      );
      return const HomeScreen();
    } else {
      debugPrint('[AppWrapper] Showing LoginScreen (default)');
      return const LoginScreen();
    }
  }
}
