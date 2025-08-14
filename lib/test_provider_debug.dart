import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/simple_auth_provider.dart';
import 'providers/simple_auth_state.dart';

class ProviderDebugScreen extends ConsumerStatefulWidget {
  const ProviderDebugScreen({super.key});

  @override
  ConsumerState<ProviderDebugScreen> createState() =>
      _ProviderDebugScreenState();
}

class _ProviderDebugScreenState extends ConsumerState<ProviderDebugScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint(
      '[ProviderDebugScreen] initState - Mounting provider debug screen',
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[ProviderDebugScreen] build called');

    // Watch the auth state
    final authState = ref.watch(simpleAuthProvider);
    debugPrint('[ProviderDebugScreen] Current auth state: $authState');

    // Listen for changes
    ref.listen<SimpleAuthState>(simpleAuthProvider, (previous, next) {
      debugPrint(
        '[ProviderDebugScreen] Auth state changed from $previous to $next',
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Debug')),
      body: Column(
        children: [
          Text('Auth State: ${authState.isAuthenticated}'),
          Text('Loading: ${authState.isLoading}'),
          Text('User: ${authState.user?.fullName ?? "None"}'),
          Text('Error: ${authState.error ?? "None"}'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              debugPrint('[ProviderDebugScreen] Debug button pressed');
              ref.read(simpleAuthProvider.notifier).debugSetAuthenticated();
            },
            child: const Text('Debug Set Authenticated'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('[ProviderDebugScreen] Login button pressed');
              ref
                  .read(simpleAuthProvider.notifier)
                  .login('9999999999', 'password123');
            },
            child: const Text('Test Login'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('[ProviderDebugScreen] Logout button pressed');
              ref.read(simpleAuthProvider.notifier).logout();
            },
            child: const Text('Test Logout'),
          ),
        ],
      ),
    );
  }
}
