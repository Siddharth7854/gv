import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grievance_new.dart';
import 'simple_auth_provider.dart';

// Dashboard Statistics Model
class DashboardStats {
  final int totalCount;
  final int pendingCount;
  final int inProgressCount;
  final int resolvedCount;

  DashboardStats({
    required this.totalCount,
    required this.pendingCount,
    required this.inProgressCount,
    required this.resolvedCount,
  });
}

// Dashboard Provider using AsyncNotifier
final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardStats>(
      DashboardNotifier.new,
    );

class DashboardNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    // Get current user
    final authState = ref.watch(simpleAuthProvider);
    if (authState.isAuthenticated && authState.user != null) {
      try {
        final citizenId = int.parse(authState.user!.userId);
        debugPrint(
          '[DashboardNotifier] Loading stats for citizen ID: $citizenId',
        );
        return await _loadDashboardStats(citizenId);
      } catch (e) {
        debugPrint(
          '[DashboardNotifier] Error parsing userId "${authState.user!.userId}": $e',
        );
        // Return empty stats if userId parsing fails
        return DashboardStats(
          totalCount: 0,
          pendingCount: 0,
          inProgressCount: 0,
          resolvedCount: 0,
        );
      }
    }

    // Return empty stats if not authenticated
    debugPrint('[DashboardNotifier] Not authenticated, returning empty stats');
    return DashboardStats(
      totalCount: 0,
      pendingCount: 0,
      inProgressCount: 0,
      resolvedCount: 0,
    );
  }

  Future<DashboardStats> _loadDashboardStats(int citizenId) async {
    try {
      // Use the shared API service instance from auth provider
      final apiService = ref.read(simpleSqlServerApiServiceProvider);
      final result = await apiService.getDashboardStats(citizenId);

      if (result['success'] == true && result['stats'] != null) {
        final overview = result['stats']['overview'];
        return DashboardStats(
          totalCount: overview['total_grievances'] ?? 0,
          pendingCount: overview['pending'] ?? 0,
          inProgressCount:
              overview['pending'] ?? 0, // API returns combined pending
          resolvedCount: overview['resolved'] ?? 0,
        );
      } else {
        return DashboardStats(
          totalCount: 0,
          pendingCount: 0,
          inProgressCount: 0,
          resolvedCount: 0,
        );
      }
    } catch (e) {
      debugPrint('Dashboard stats error: $e');
      throw Exception('Failed to load dashboard stats: $e');
    }
  }

  Future<void> refreshStats() async {
    final authState = ref.read(simpleAuthProvider);
    if (authState.isAuthenticated && authState.user != null) {
      state = const AsyncValue.loading();
      try {
        final citizenId = int.parse(authState.user!.userId);
        debugPrint(
          '[DashboardNotifier] Refreshing stats for citizen ID: $citizenId',
        );
        final stats = await _loadDashboardStats(citizenId);
        state = AsyncValue.data(stats);
      } catch (e, stackTrace) {
        debugPrint('[DashboardNotifier] Error refreshing stats: $e');
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }
}

// Recent Grievances Provider
final recentGrievancesProvider =
    AsyncNotifierProvider<RecentGrievancesNotifier, List<Grievance>>(
      RecentGrievancesNotifier.new,
    );

class RecentGrievancesNotifier extends AsyncNotifier<List<Grievance>> {
  @override
  Future<List<Grievance>> build() async {
    final authState = ref.watch(simpleAuthProvider);
    if (authState.isAuthenticated && authState.user != null) {
      try {
        final citizenId = int.parse(authState.user!.userId);
        debugPrint(
          '[RecentGrievancesNotifier] Loading grievances for citizen ID: $citizenId',
        );
        return await _loadRecentGrievances(citizenId);
      } catch (e) {
        debugPrint(
          '[RecentGrievancesNotifier] Error parsing userId "${authState.user!.userId}": $e',
        );
        return [];
      }
    }
    debugPrint(
      '[RecentGrievancesNotifier] Not authenticated, returning empty list',
    );
    return [];
  }

  Future<List<Grievance>> _loadRecentGrievances(int citizenId) async {
    try {
      final apiService = ref.read(simpleSqlServerApiServiceProvider);
      final grievances = await apiService.getGrievancesByCitizen(citizenId);

      // Return the most recent 5 grievances
      grievances.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return grievances.take(5).toList();
    } catch (e) {
      debugPrint('Recent grievances error: $e');
      throw Exception('Failed to load recent grievances: $e');
    }
  }
}
