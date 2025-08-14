import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/gov_theme.dart';
import '../../providers/simple_auth_provider.dart';
import '../../services/fcm_service_cross_platform.dart';
import 'citizen_registration_screen.dart';
import '../admin/admin_login_screen.dart';
import '../home/home_screen.dart';
import '../test_fcm_token_mobile.dart';
import '../test/fcm_test_screen.dart';

/// Professional Government Portal Login Screen with FCM Testing
/// Implements secure authentication with government design standards and cross-platform notifications
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Enhanced FCM Test with permissions check
  void _testFCMNotification() async {
    try {
      debugPrint('[FCM Test] Testing cross-platform notification system...');

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('🔄 Initializing FCM and sending test notification...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Initialize cross-platform FCM service
      await FCMService.initialize();

      // Check permissions
      final permissionsEnabled = await FCMService.areNotificationsEnabled();
      debugPrint('[FCM Test] Permissions enabled: $permissionsEnabled');

      // Get FCM token
      final token = await FCMService.getToken();
      debugPrint('[FCM Test] Token: $token');

      // Get service status
      final status = await FCMService.getServiceStatus();
      debugPrint('[FCM Test] Service status: $status');

      // Show test notification
      await FCMService.showTestNotification();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔔 FCM Test Notification Sent!'),
                Text('Platform: ${FCMService.platformInfo}'),
                Text(
                  'Permissions: ${permissionsEnabled ? "✅ Granted" : "❌ Denied"}',
                ),
                Text('Check your notification center/system tray'),
              ],
            ),
            backgroundColor: permissionsEnabled ? Colors.green : Colors.orange,
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      debugPrint('[FCM Test] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ FCM notification test failed: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Government Standards: Secure login process with proper validation
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;

      try {
        debugPrint('[GovernmentPortal] Initiating secure authentication...');

        // Clear any cached user state to ensure fresh login
        ref.invalidate(simpleAuthProvider);

        // Wait a moment for state to clear
        await Future.delayed(Duration(milliseconds: 100));

        // Perform login
        await ref.read(simpleAuthProvider.notifier).login(phone, password);

        // Add a small delay to ensure state propagation
        await Future.delayed(Duration(milliseconds: 300));

        // Check if login was successful and navigate
        final authState = ref.read(simpleAuthProvider);
        debugPrint('[GovernmentPortal] Post-login auth state: $authState');
        debugPrint(
          '[GovernmentPortal] isAuthenticated: ${authState.isAuthenticated}',
        );
        debugPrint('[GovernmentPortal] user: ${authState.user?.fullName}');

        if (authState.isAuthenticated && authState.user != null && mounted) {
          debugPrint(
            '[GovernmentPortal] Login successful, navigating to HomeScreen',
          );

          // Force navigation to HomeScreen with complete route clearing
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          debugPrint(
            '[GovernmentPortal] Login failed - auth state not correct',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login failed - Please try again'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[GovernmentPortal] Login error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(simpleAuthProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Header Section
              Column(
                children: [
                  // Government Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: GovTheme.headerGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      size: 50,
                      color: Colors.white,
                    ),
                  ).animate().scale(delay: 200.ms),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Government Portal',
                    style: GoogleFonts.roboto(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Citizen Grievance Management System',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),

              const SizedBox(height: 48),

              // Login Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Welcome Text
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ).animate().fadeIn(delay: 800.ms),

                      const SizedBox(height: 8),

                      Text(
                        'Please sign in to continue',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ).animate().fadeIn(delay: 900.ms),

                      const SizedBox(height: 32),

                      // Phone Number Field
                      TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Mobile Number',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your mobile number';
                              }
                              if (value.length != 10) {
                                return 'Please enter a valid 10-digit mobile number';
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(delay: 1000.ms)
                          .slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(delay: 1100.ms)
                          .slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 16),

                      // Remember Me & Forgot Password
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          Text(
                            'Remember me',
                            style: GoogleFonts.roboto(fontSize: 14),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 1200.ms),

                      const SizedBox(height: 32),

                      // Login Button
                      SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1300.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 24),

                      // FCM Test Buttons Row - Development Only
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _testFCMNotification,
                              icon: Icon(Icons.notifications_active, size: 18),
                              label: Text(
                                'FCM Test',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: BorderSide(color: Colors.blue),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const TestFCMTokenMobile(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.token, size: 18),
                              label: Text(
                                'FCM Token',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: BorderSide(color: Colors.green),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // FCM Comprehensive Test Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FCMTestWidget(),
                              ),
                            );
                          },
                          icon: Icon(Icons.bug_report, size: 18),
                          label: Text(
                            'FCM Comprehensive Test',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: BorderSide(color: Colors.orange),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CitizenRegistrationScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 1400.ms),

                      const SizedBox(height: 16),

                      // Admin Login Button
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AdminLoginScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.admin_panel_settings),
                        label: Text(
                          'Admin Login',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: GovTheme.primaryBlue,
                        ),
                      ).animate().fadeIn(delay: 1500.ms),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Error Message
              if (authState.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          authState.error ?? 'An error occurred',
                          style: GoogleFonts.roboto(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
