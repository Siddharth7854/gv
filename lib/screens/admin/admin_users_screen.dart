import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import '../../core/theme/gov_theme.dart';
import '../../providers/admin_providers_fix.dart';
import '../../core/utils/web_utils.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load real users data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminUsersProvider.notifier).fetchUsers(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get filtered users from real data
  List<Map<String, dynamic>> _getFilteredUsers(
    List<Map<String, dynamic>> users,
  ) {
    if (_searchQuery.isEmpty) return users;
    return users.where((user) {
      final name = user['full_name']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final phone = user['phone']?.toString().toLowerCase() ?? '';
      final citizenId = user['citizen_id']?.toString().toLowerCase() ?? '';

      return name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery.toLowerCase()) ||
          citizenId.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Top Actions Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text('User Management', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: GovTheme.primaryBlue)),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                      onPressed: _exportUsers,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add User'),
                      style: ElevatedButton.styleFrom(backgroundColor: GovTheme.primaryBlue, foregroundColor: Colors.white),
                      onPressed: _addUser,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: GovTheme.primaryBlue),
                      onPressed: () {
                        ref.read(adminUsersProvider.notifier).fetchUsers(refresh: true);
                      },
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              // Modern Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildSearchBar(),
                  ),
                ),
              ),
              // Modern Stat Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: _buildStatsCards(),
              ),
              // Users List/Table
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: _buildUsersList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    final adminUsersState = ref.watch(adminUsersProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name, email, phone, or ID...',
              prefixIcon: adminUsersState.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              // Optionally, you can implement debounced search to the backend
              // For now, we'll filter locally for better performance
            },
          ),
          if (adminUsersState.users.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${_getFilteredUsers(adminUsersState.users).length} of ${adminUsersState.users.length} users',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Last updated: just now',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final adminUsersState = ref.watch(adminUsersProvider);
    final users = adminUsersState.users;

    // Calculate stats from real data
    final totalUsers = users.length;
    final activeUsers = users
        .where((u) => (u['status']?.toString().toLowerCase() ?? '') == 'active')
        .length;
    final citizens = users
        .where((u) => (u['role']?.toString().toLowerCase() ?? '') == 'citizen')
        .length;
    final officials = users
        .where((u) => (u['role']?.toString().toLowerCase() ?? '') == 'official')
        .length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Stack in 2x2 grid on smaller screens
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Users',
                        totalUsers.toString(),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Active Users',
                        activeUsers.toString(),
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Citizens',
                        citizens.toString(),
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Officials',
                        officials.toString(),
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Single row on larger screens
            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Users',
                    totalUsers.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active Users',
                    activeUsers.toString(),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Citizens',
                    citizens.toString(),
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Officials',
                    officials.toString(),
                    Colors.orange,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, color: color, size: 28, semanticLabel: title),
          const SizedBox(height: 10),
          Text(
            count,
            style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: color),
            semanticsLabel: '$title count: $count',
          ),
          const SizedBox(height: 6),
          Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    final adminUsersState = ref.watch(adminUsersProvider);

    if (adminUsersState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading users...'),
          ],
        ),
      );
    }

    if (adminUsersState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading users',
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(
              adminUsersState.error!,
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(adminUsersProvider.notifier).fetchUsers(refresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final users = _getFilteredUsers(adminUsersState.users);

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No users found'
                  : 'No users match your search',
              style: GoogleFonts.roboto(fontSize: 18, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Try searching with a different term',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            // Mobile card layout
            return _buildMobileUsersList(users);
          } else {
            // Desktop table layout
            return _buildDesktopUsersList(users);
          }
        },
      ),
    );
  }

  Widget _buildMobileUsersList(List<Map<String, dynamic>> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ...existing code...
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopUsersList(List<Map<String, dynamic>> users) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1200,
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: 120, child: _buildHeaderCell('User ID')),
                  SizedBox(width: 180, child: _buildHeaderCell('Name')),
                  SizedBox(width: 200, child: _buildHeaderCell('Email')),
                  SizedBox(width: 140, child: _buildHeaderCell('Phone')),
                  SizedBox(width: 100, child: _buildHeaderCell('Role')),
                  SizedBox(width: 100, child: _buildHeaderCell('Status')),
                  SizedBox(width: 100, child: _buildHeaderCell('Grievances')),
                  SizedBox(width: 120, child: _buildHeaderCell('Actions')),
                ],
              ),
            ),
            // Table Body
            Container(
              height: 500,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return _buildUserRow(users[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: GovTheme.darkGray,
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              user['id']?.toString() ??
                  user['citizen_id']?.toString() ??
                  'No ID',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: GovTheme.primaryBlue,
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: Text(
              user['full_name']?.toString() ?? 'Unknown User',
              style: GoogleFonts.roboto(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 200,
            child: Text(
              user['email']?.toString() ?? 'No email',
              style: GoogleFonts.roboto(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              user['phone']?.toString() ?? 'No phone',
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 100,
            child: _buildRoleChip(user['role']?.toString() ?? 'Citizen'),
          ),
          SizedBox(
            width: 100,
            child: _buildStatusChip(user['status']?.toString() ?? 'unknown'),
          ),
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                user['grievancesCount']?.toString() ?? '0',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editUser(user),
                  color: GovTheme.primaryBlue,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteUser(
                    user['id']?.toString() ??
                        user['citizen_id']?.toString() ??
                        '',
                  ),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    final normalizedRole = role.toLowerCase();
    Color color = normalizedRole == 'citizen' ? Colors.purple : Colors.orange;
    String displayRole = 'Unknown';
    if (role.isNotEmpty) {
      displayRole =
          role.substring(0, 1).toUpperCase() + role.substring(1).toLowerCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayRole,
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final normalizedStatus = status.toLowerCase();
    Color color = normalizedStatus == 'active' ? Colors.green : Colors.red;
    String displayStatus = 'Unknown';
    if (status.isNotEmpty) {
      displayStatus =
          status.substring(0, 1).toUpperCase() +
          status.substring(1).toLowerCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayStatus,
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _exportUsers() {
    final usersState = ref.read(adminUsersProvider);
    final users = usersState.users;

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No users data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // CSV headers
      final List<List<String>> csvData = [
        [
          'Citizen ID',
          'Full Name',
          'Email',
          'Phone',
          'Role',
          'Status',
          'Created At',
          'Last Updated',
        ],
      ];

      // Add user data
      for (final user in users) {
        csvData.add([
          (user['citizen_id']?.toString() ?? user['id']?.toString() ?? ''),
          (user['full_name']?.toString() ?? user['name']?.toString() ?? ''),
          (user['email']?.toString() ?? ''),
          (user['phone']?.toString() ?? ''),
          (user['role']?.toString() ?? 'Citizen'),
          (user['status']?.toString() ??
              (user['is_active'] == true ? 'Active' : 'Inactive')),
          (user['created_at']?.toString() ?? ''),
          (user['updated_at']?.toString() ??
              user['last_login']?.toString() ??
              ''),
        ]);
      }

      // Generate CSV string
      final String csvString = const ListToCsvConverter().convert(csvData);

      // Platform-specific download
      try {
        downloadCsv(
          csvString,
          'users_export_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
      } catch (e) {
        // For non-web platforms, show message that download is not available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV export is only available on web platform'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${users.length} users successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addUser() {
    showDialog(context: context, builder: (context) => _AddUserDialog());
  }

  // Removed unused _viewUserDetails function

  void _editUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => _EditUserDialog(user: user),
    );
  }

  void _deleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete User',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                color: GovTheme.darkGray,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this user?',
              style: GoogleFonts.roboto(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'User ID: $userId',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All user data will be permanently deleted.',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteUser(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Delete User'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteUser(String userId) async {
    try {
      // Show immediate loading state with optimistic update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('Deleting user...', style: GoogleFonts.roboto()),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Immediately remove user from UI for instant feedback
      ref.read(adminUsersProvider.notifier).removeUserOptimistically(userId);

      // Call the delete user API in background
      final result = await ref
          .read(adminUsersProvider.notifier)
          .deleteUser(userId);

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(result['message'] ?? 'User deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Restore user in UI if deletion failed
        ref.read(adminUsersProvider.notifier).fetchUsers(refresh: true);

        // Show specific error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result['error'] ?? 'Failed to delete user. User restored.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Restore user in UI if error occurred
      ref.read(adminUsersProvider.notifier).fetchUsers(refresh: true);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error: $e. User restored.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

// User Details Dialog Widget
class _UserDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserDetailsDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: GovTheme.primaryBlue.withValues(alpha: 0.1),
            child: Text(
              (user['full_name']?.toString().isNotEmpty == true)
                  ? user['full_name']!.toString()[0].toUpperCase()
                  : 'U',
              style: GoogleFonts.roboto(
                color: GovTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['full_name']?.toString() ?? 'Unknown User',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: GovTheme.darkGray,
                    fontSize: 18,
                  ),
                ),
                Text(
                  user['id']?.toString() ??
                      user['citizen_id']?.toString() ??
                      'No ID',
                  style: GoogleFonts.roboto(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
              'Email',
              user['email']?.toString() ?? 'Not provided',
              Icons.email,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Phone',
              user['phone']?.toString() ?? 'Not provided',
              Icons.phone,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Role',
              user['role']?.toString() ?? 'Citizen',
              Icons.work,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Status',
              user['status']?.toString() ?? 'Unknown',
              Icons.toggle_on,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Grievances Filed',
              user['grievancesCount']?.toString() ?? '0',
              Icons.assignment,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Joined',
              _formatDate(user['joinedAt']),
              Icons.calendar_today,
            ),
            if (user['district'] != null ||
                user['block'] != null ||
                user['ward'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Details',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        color: GovTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (user['district'] != null)
                      _buildDetailRow(
                        'District',
                        user['district'].toString(),
                        Icons.location_city,
                      ),
                    if (user['block'] != null)
                      _buildDetailRow(
                        'Block',
                        user['block'].toString(),
                        Icons.location_on,
                      ),
                    if (user['ward'] != null)
                      _buildDetailRow(
                        'Ward',
                        user['ward'].toString(),
                        Icons.place,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Could add more actions here like viewing user's grievances
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: GovTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('View Grievances'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: GovTheme.darkGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateValue.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateValue.toString();
    }
  }
}

// Edit User Dialog Widget
class _EditUserDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const _EditUserDialog({required this.user});

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user['full_name']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.user['email']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.user['phone']?.toString() ?? '',
    );
    _selectedStatus =
        widget.user['status']?.toString().toLowerCase() ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GovTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.edit, color: GovTheme.primaryBlue, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Edit User',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
              color: GovTheme.darkGray,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User ID (Read-only)
              TextFormField(
                initialValue:
                    widget.user['id']?.toString() ??
                    widget.user['citizen_id']?.toString() ??
                    '',
                decoration: InputDecoration(
                  labelText: 'User ID',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (!RegExp(
                    r'^[6-9]\d{9}$',
                  ).hasMatch(value.replaceAll(RegExp(r'[^\d]'), ''))) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status *',
                  prefixIcon: const Icon(Icons.toggle_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: GovTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll just update the status using the existing API
      // In a real implementation, you'd have a full update user API
      final userId =
          widget.user['id']?.toString() ??
          widget.user['citizen_id']?.toString() ??
          '';
      final success = await ref
          .read(adminUsersProvider.notifier)
          .updateUserStatus(userId, _selectedStatus);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('User updated successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to update user'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Add User Dialog Widget
class _AddUserDialog extends ConsumerStatefulWidget {
  const _AddUserDialog();

  @override
  ConsumerState<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Citizen';
  String _selectedStatus = 'active';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Add New User',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
              color: GovTheme.darkGray,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    final phoneNumber = value.replaceAll(RegExp(r'[^\d]'), '');
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phoneNumber)) {
                      return 'Please enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role *',
                    prefixIcon: const Icon(Icons.work),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'Citizen', child: Text('Citizen')),
                    DropdownMenuItem(
                      value: 'Official',
                      child: Text('Official'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Status
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status *',
                    prefixIcon: const Icon(Icons.toggle_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactive'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Add User'),
        ),
      ],
    );
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Show info dialog that this is a demo
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GovTheme.infoBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(Icons.info_outline, color: GovTheme.infoBlue, size: 28),
          ),
          title: Text(
            'Add User Feature',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              color: GovTheme.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'User registration functionality is handled through the citizen registration system. This admin interface currently supports viewing and managing existing users.',
            style: GoogleFonts.roboto(height: 1.5, color: GovTheme.neutralGray),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: GovTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
