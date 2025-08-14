import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/gov_theme.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/grievances_provider.dart';
import '../../models/grievance_new.dart';
import '../profile/profile_screen.dart';
import '../grievance/new_grievance_screen.dart';
import '../grievance/grievance_details_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const GrievancesTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: GovTheme.primaryBlue,
          unselectedItemColor: GovTheme.neutralGray,
          selectedLabelStyle: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Grievances',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewGrievanceScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Grievance'),
              backgroundColor: GovTheme.primaryBlue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(simpleCurrentUserProvider);
    debugPrint(
      '[DashboardTab] Building dashboard, user: ${user?.fullName ?? "NULL"}',
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Dashboard',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // Show notifications screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications feature coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _showLogoutDialog(context, ref);
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: GovTheme.headerGradient),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(context, user),

            const SizedBox(height: 24),

            // Quick Stats
            Text(
              'Overview',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: GovTheme.darkGray,
              ),
            ),

            const SizedBox(height: 16),

            // Stats Grid
            _buildStatsGrid(context, ref),

            const SizedBox(height: 24),

            // Recent Activity
            Text(
              'Recent Activity',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: GovTheme.darkGray,
              ),
            ),

            const SizedBox(height: 16),

            _buildRecentActivity(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, user) {
    return Animate(
      effects: const [FadeEffect(), ScaleEffect()],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GovTheme.primaryBlue.withOpacity(0.8),
              GovTheme.secondaryBlue.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: GovTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.waving_hand,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        user?.fullName ?? 'Employee',
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return dashboardState.when(
      data: (stats) {
        debugPrint('[DashboardTab] Stats loaded successfully: $stats');
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              icon: Icons.access_time,
              title: 'Pending',
              count: stats.pendingCount.toString(),
              color: GovTheme.warningAmber,
            ),
            _buildStatCard(
              icon: Icons.sync,
              title: 'In Progress',
              count: stats.inProgressCount.toString(),
              color: GovTheme.infoBlue,
            ),
            _buildStatCard(
              icon: Icons.check_circle,
              title: 'Resolved',
              count: stats.resolvedCount.toString(),
              color: GovTheme.successGreen,
            ),
            _buildStatCard(
              icon: Icons.assignment,
              title: 'Total',
              count: stats.totalCount.toString(),
              color: GovTheme.primaryBlue,
            ),
          ],
        );
      },
      loading: () {
        debugPrint('[DashboardTab] Stats loading...');
        return SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: GovTheme.primaryBlue),
                SizedBox(height: 16),
                Text(
                  'Loading dashboard...',
                  style: GoogleFonts.roboto(
                    color: GovTheme.neutralGray,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        debugPrint('[DashboardTab] Stats error: $error');
        debugPrint('[DashboardTab] Stack trace: $stackTrace');
        return Container(
          height: 200,
          padding: EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error loading dashboard',
                  style: GoogleFonts.roboto(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: GoogleFonts.roboto(
                    color: GovTheme.neutralGray,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(dashboardProvider);
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    return Animate(
      effects: const [ScaleEffect(duration: Duration(milliseconds: 300))],
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: GovTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              count,
              style: GoogleFonts.roboto(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: GovTheme.darkGray,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: GovTheme.neutralGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final recentGrievancesState = ref.watch(recentGrievancesProvider);

    return recentGrievancesState.when(
      data: (grievances) {
        if (grievances.isEmpty) {
          return _buildEmptyRecentActivity(context);
        }
        return _buildRecentActivityList(context, grievances);
      },
      loading: () => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: GovTheme.cardShadow,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _buildEmptyRecentActivity(context),
    );
  }

  Widget _buildEmptyRecentActivity(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: GovTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GovTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 64,
              color: GovTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Recent Activity',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: GovTheme.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your grievance activity will appear here.\nSubmit your first grievance to get started!',
            style: GoogleFonts.roboto(
              fontSize: 15,
              color: GovTheme.neutralGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to new grievance screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewGrievanceScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Submit New Grievance',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GovTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(
    BuildContext context,
    List<Grievance> grievances,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: GovTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GovTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: GovTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recent Grievances',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GovTheme.darkGray,
                    ),
                  ),
                ),
                Text(
                  '${grievances.length} items',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: GovTheme.neutralGray,
                  ),
                ),
              ],
            ),
          ),
          // Grievance List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: grievances.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final grievance = grievances[index];
              return _buildGrievanceCard(context, grievance);
            },
          ),
          // View All Button
          if (grievances.length >= 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Simple message for now - can be enhanced later
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigate to Grievances tab'),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: GovTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'View All Grievances',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrievanceCard(BuildContext context, Grievance grievance) {
    final statusColor = _getStatusColor(grievance.status);
    final priorityColor = _getPriorityColor(grievance.priority);

    return Animate(
      effects: const [
        FadeEffect(),
        SlideEffect(begin: Offset(0.05, 0)),
      ],
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GrievanceDetailsScreen(grievance: grievance),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status Indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and ID
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            grievance.title,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: GovTheme.darkGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#${grievance.grievanceNumber ?? grievance.grievanceId}',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: GovTheme.neutralGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Status and Priority Chips
                    Row(
                      children: [
                        _buildCompactChip(
                          label: grievance.status,
                          color: statusColor,
                          icon: _getStatusIcon(grievance.status),
                        ),
                        const SizedBox(width: 6),
                        _buildCompactChip(
                          label: grievance.priority,
                          color: priorityColor,
                          icon: Icons.flag,
                        ),
                        const Spacer(),
                        Text(
                          _formatCompactDate(grievance.submittedAt),
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: GovTheme.neutralGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Category
                    Text(
                      grievance.categoryName ?? 'General',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: GovTheme.neutralGray.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: GovTheme.neutralGray.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for status and priority colors
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return GovTheme.successGreen;
      case 'in progress':
        return GovTheme.infoBlue;
      case 'submitted':
      case 'under review':
        return GovTheme.warningAmber;
      default:
        return GovTheme.neutralGray;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle;
      case 'in progress':
        return Icons.sync;
      case 'submitted':
      case 'under review':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return GovTheme.errorRed;
      case 'medium':
        return GovTheme.warningAmber;
      case 'low':
        return GovTheme.successGreen;
      default:
        return GovTheme.neutralGray;
    }
  }

  String _formatCompactDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return '1d ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to logout from the Government Grievance Portal?',
            style: GoogleFonts.roboto(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(simpleAuthProvider.notifier).logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GovTheme.errorRed,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

class GrievancesTab extends ConsumerWidget {
  const GrievancesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grievancesAsync = ref.watch(grievancesProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'My Grievances',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(grievancesProvider.notifier).refreshGrievances();
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: GovTheme.headerGradient),
        ),
      ),
      body: grievancesAsync.when(
        data: (grievances) {
          if (grievances.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildGrievancesList(grievances, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: GovTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 80,
                color: GovTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Grievances Yet',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GovTheme.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You haven\'t submitted any grievances yet.\nStart by submitting your first grievance.',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: GovTheme.neutralGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrievancesList(List<Grievance> grievances, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(grievancesProvider.notifier).refreshGrievances();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grievances.length,
        itemBuilder: (context, index) {
          final grievance = grievances[index];
          return _buildGrievanceCard(context, grievance, ref);
        },
      ),
    );
  }

  Widget _buildGrievanceCard(
    BuildContext context,
    Grievance grievance,
    WidgetRef ref,
  ) {
    // Get status color and icon
    Color statusColor;
    IconData statusIcon;
    String status = grievance.status.toLowerCase();

    switch (status) {
      case 'resolved':
        statusColor = GovTheme.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'in progress':
        statusColor = GovTheme.infoBlue;
        statusIcon = Icons.sync;
        break;
      case 'submitted':
      case 'under review':
        statusColor = GovTheme.warningAmber;
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = GovTheme.neutralGray;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to grievance details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GrievanceDetailsScreen(grievance: grievance),
            ),
          );
        },
        onLongPress: () {
          // Show context menu for actions
          _showGrievanceActions(context, grievance, ref);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          status.toUpperCase(),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(grievance.submittedAt),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: GovTheme.neutralGray,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                grievance.title,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: GovTheme.darkGray,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                grievance.description,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: GovTheme.neutralGray,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer with ID and category
              Row(
                children: [
                  Icon(Icons.tag, size: 16, color: GovTheme.neutralGray),
                  const SizedBox(width: 4),
                  Text(
                    'ID: ${grievance.grievanceId ?? 'N/A'}',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: GovTheme.neutralGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (grievance.categoryName != null) ...[
                    Icon(Icons.category, size: 14, color: GovTheme.neutralGray),
                    const SizedBox(width: 4),
                    Text(
                      grievance.categoryName!,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: GovTheme.neutralGray,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: GovTheme.neutralGray,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: GovTheme.errorRed),
            const SizedBox(height: 24),
            Text(
              'Error Loading Grievances',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: GovTheme.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: GovTheme.neutralGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Retry loading
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown Date';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  void _showGrievanceActions(
    BuildContext context,
    Grievance grievance,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Grievance Actions',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GovTheme.darkGray,
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.visibility, color: GovTheme.primaryBlue),
              ),
              title: Text(
                'View Details',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GrievanceDetailsScreen(grievance: grievance),
                  ),
                );
              },
            ),

            if (grievance.status.toLowerCase() == 'submitted')
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GovTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete, color: GovTheme.errorRed),
                ),
                title: Text(
                  'Delete Grievance',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                    color: GovTheme.errorRed,
                  ),
                ),
                subtitle: Text(
                  'Only submitted grievances can be deleted',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: GovTheme.neutralGray,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, grievance, ref);
                },
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Grievance grievance,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GovTheme.errorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(
            Icons.warning_outlined,
            color: GovTheme.errorRed,
            size: 28,
          ),
        ),
        title: Text(
          'Delete Grievance',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: GovTheme.errorRed,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Are you sure you want to delete this grievance?\n\n"${grievance.title}"\n\nThis action cannot be undone.',
          style: GoogleFonts.roboto(height: 1.5, color: GovTheme.neutralGray),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: GovTheme.neutralGray,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: GovTheme.errorRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteGrievance(context, grievance, ref);
    }
  }

  Future<void> _deleteGrievance(
    BuildContext context,
    Grievance grievance,
    WidgetRef ref,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await ref
          .read(grievancesProvider.notifier)
          .deleteGrievance(grievance.grievanceId!);

      // Hide loading
      if (context.mounted) Navigator.of(context).pop();

      if (success) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Grievance deleted successfully'),
                ],
              ),
              backgroundColor: GovTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Failed to delete grievance'),
                ],
              ),
              backgroundColor: GovTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading if still showing
      if (context.mounted) Navigator.of(context).pop();

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error: ${e.toString()}'),
              ],
            ),
            backgroundColor: GovTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
