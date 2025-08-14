import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/gov_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GovTheme.headerGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Government Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: GovTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.account_balance,
                  size: 60,
                  color: GovTheme.primaryBlue,
                ),
              ).animate().scale(duration: 800.ms).fadeIn(duration: 600.ms),

              const SizedBox(height: 32),

              // App Title
              Text(
                    'Government',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              Text(
                    'Grievance Portal',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 48),

              // Loading indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),

              const SizedBox(height: 16),

              Text(
                'Connecting to secure server...',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ).animate().fadeIn(delay: 1200.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
