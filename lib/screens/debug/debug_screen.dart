import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/onboarding_service.dart';
import '../../services/local_storage_service.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                await OnboardingService.resetOnboarding();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Onboarding reset!')),
                  );
                }
              },
              child: const Text('Reset Onboarding'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final localStorage = LocalStorageService();
                await localStorage.clear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All storage cleared!')),
                  );
                }
              },
              child: const Text('Clear All Storage'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final isComplete =
                    await OnboardingService.isOnboardingComplete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Onboarding Complete: $isComplete')),
                  );
                }
              },
              child: const Text('Check Onboarding Status'),
            ),
          ],
        ),
      ),
    );
  }
}
