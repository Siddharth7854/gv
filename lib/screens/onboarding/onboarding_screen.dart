import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/gov_theme.dart';
import '../../services/onboarding_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Welcome to Government Grievance Portal',
      description:
          'Your voice matters! Submit and track grievances easily with our secure government portal.',
      imagePath: 'assets/images/onboarding_1.png',
      icon: Icons.account_balance,
    ),
    OnboardingData(
      title: 'Submit Grievances Anytime',
      description:
          'Report issues, complaints, or suggestions 24/7. Add photos, audio, and location details.',
      imagePath: 'assets/images/onboarding_2.png',
      icon: Icons.assignment_outlined,
    ),
    OnboardingData(
      title: 'Track Your Progress',
      description:
          'Get real-time updates on your grievances. Monitor status changes and responses from officials.',
      imagePath: 'assets/images/onboarding_3.png',
      icon: Icons.track_changes,
    ),
    OnboardingData(
      title: 'Secure & Transparent',
      description:
          'Your data is protected with government-grade security. All processes are transparent and auditable.',
      imagePath: 'assets/images/onboarding_4.png',
      icon: Icons.security,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GovTheme.primaryBlue.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentPage < _onboardingData.length - 1)
                      TextButton(
                        onPressed: _skipOnboarding,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: GovTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_onboardingData[index]);
                  },
                ),
              ),

              // Bottom Navigation
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Page Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingData.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? GovTheme.primaryBlue
                                : GovTheme.primaryBlue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Navigation Buttons
                    Row(
                      children: [
                        // Previous Button
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousPage,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: GovTheme.primaryBlue),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Previous',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: GovTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ),

                        if (_currentPage > 0) const SizedBox(width: 16),

                        // Next/Get Started Button
                        Expanded(
                          flex: _currentPage == 0 ? 1 : 1,
                          child: ElevatedButton(
                            onPressed:
                                _currentPage == _onboardingData.length - 1
                                ? _completeOnboarding
                                : _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GovTheme.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentPage == _onboardingData.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Image
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: GovTheme.primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(data.icon, size: 80, color: GovTheme.primaryBlue),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            style: GoogleFonts.roboto(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: GovTheme.darkGray,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            data.description,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: GovTheme.neutralGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipOnboarding() async {
    await OnboardingService.markOnboardingComplete();
    widget.onComplete?.call();
  }

  void _completeOnboarding() async {
    await OnboardingService.markOnboardingComplete();
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String imagePath;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
  });
}
