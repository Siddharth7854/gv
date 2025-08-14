import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grievance_new.dart';
import 'simple_auth_provider.dart';

// Grievances Provider
final grievancesProvider =
    AsyncNotifierProvider<GrievancesNotifier, List<Grievance>>(
      GrievancesNotifier.new,
    );

class GrievancesNotifier extends AsyncNotifier<List<Grievance>> {
  @override
  Future<List<Grievance>> build() async {
    final authState = ref.watch(simpleAuthProvider);
    if (authState.isAuthenticated && authState.user != null) {
      try {
        final citizenId = int.parse(authState.user!.userId);
        return await _loadGrievances(citizenId);
      } catch (e) {
        print(
          '[GrievancesNotifier] Error parsing userId "${authState.user!.userId}": $e',
        );
        return [];
      }
    }
    return [];
  }

  Future<List<Grievance>> _loadGrievances(int citizenId) async {
    try {
      // Use the shared API service instance that has the auth token
      final apiService = ref.read(simpleSqlServerApiServiceProvider);
      return await apiService.getGrievancesByCitizen(citizenId);
    } catch (e) {
      throw Exception('Failed to load grievances: $e');
    }
  }

  Future<void> refreshGrievances() async {
    final authState = ref.read(simpleAuthProvider);
    if (authState.isAuthenticated && authState.user != null) {
      state = const AsyncValue.loading();
      try {
        // Use the shared API service instance that has the auth token
        final apiService = ref.read(simpleSqlServerApiServiceProvider);
        final citizenId = int.parse(authState.user!.userId);
        final grievances = await apiService.getGrievancesByCitizen(citizenId);
        state = AsyncValue.data(grievances);
      } catch (e, stackTrace) {
        print('[GrievancesNotifier] Error refreshing grievances: $e');
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<bool> deleteGrievance(int grievanceId) async {
    try {
      final apiService = ref.read(simpleSqlServerApiServiceProvider);
      final result = await apiService.deleteGrievance(grievanceId);

      if (result['success'] == true) {
        // Refresh the grievances list
        await refreshGrievances();
        return true;
      }
      return false;
    } catch (e) {
      print('[GrievancesNotifier] Error deleting grievance: $e');
      return false;
    }
  }
}
