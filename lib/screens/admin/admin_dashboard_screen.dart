import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_grievances_screen.dart';
import 'admin_users_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_login_screen.dart';
import '../../providers/admin_providers_fix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _showNotifications = false;
  bool _sidebarOpen = true;

  void _toggleNotifications() {
    setState(() {
      _showNotifications = !_showNotifications;
    });
  }
  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
  }

  Widget _buildChart() {
  final List<FlSpot> spots = List.generate(7, (i) => FlSpot(i.toDouble(), (i * i).toDouble()));
  return Padding(
    padding: const EdgeInsets.all(32.0),
    child: SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 36,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildNotificationsPanel() {
    final notifications = [
      'User John added',
      'Grievance #123 resolved',
      'New grievance submitted',
      'Admin login from new device',
    ];
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.notifications, color: Colors.purple[700]),
          title: Text(notifications[index], style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        );
      },
    );
  }

  Widget _buildAccentButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, int index) {
    final selected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.white : Colors.white70),
      title: Text(label, style: GoogleFonts.inter(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700)),
      selected: selected,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Sidebar Drawer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            left: _sidebarOpen ? 0 : -260,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: 240,
              child: _buildSidebar(context),
            ),
          ),
          // Main Content with overlay
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            margin: EdgeInsets.only(left: _sidebarOpen ? 240 : 0),
            child: Stack(
              children: [
                // Topbar with sidebar toggle
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    color: Colors.white,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(_sidebarOpen ? Icons.menu_open : Icons.menu, color: Colors.blue[900], size: 28),
                          onPressed: _toggleSidebar,
                          tooltip: _sidebarOpen ? 'Close Sidebar' : 'Open Sidebar',
                        ),
                        const SizedBox(width: 8),
                        Text('Admin Panel', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.blue[900])),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.purple, size: 28),
                          onPressed: _toggleNotifications,
                          tooltip: 'Notifications',
                        ),
                        const SizedBox(width: 18),
                        CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Icon(Icons.person, color: Colors.blue[900]),
                        ),
                        const SizedBox(width: 18),
                      ],
                    ),
                  ),
                ),
                // Main content below topbar
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: _buildMainContent(context),
                ),
                // Notifications Drawer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  right: _showNotifications ? 0 : -350,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(-2, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue[900],
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Notifications', style: GoogleFonts.roboto(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: _toggleNotifications,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildNotificationsPanel(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Overlay for sidebar on small screens
          if (_sidebarOpen && MediaQuery.of(context).size.width < 700)
            GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                color: Colors.black.withOpacity(0.2),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab(context);
      case 1:
        return const AdminGrievancesScreen();
      case 2:
        return const AdminUsersScreen();
      case 3:
        return const AdminSettingsScreen();
      default:
        return _buildDashboardTab(context);
    }
  }

  Widget _buildDashboardTab(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    return SafeArea(
      child: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                      Icon(Icons.verified_user, color: Colors.blue[900], size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text('Government Admin Dashboard', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.blue[900])),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add User'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
                        onPressed: () => _showAddUserDialog(context),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_comment),
                        label: const Text('Add Grievance'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], foregroundColor: Colors.white),
                        onPressed: () => _showAddGrievanceDialog(context),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.purple, size: 28),
                        onPressed: _toggleNotifications,
                        tooltip: 'Notifications',
                      ),
                      const SizedBox(width: 18),
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Icon(Icons.person, color: Colors.blue[900]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stat Cards Responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildAnimatedStatCard('Total Users', stats.usersCount.toString(), Icons.people, Colors.blue)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildAnimatedStatCard('Total Grievances', stats.grievancesCount.toString(), Icons.assignment, Colors.orange)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildAnimatedStatCard('Resolved', stats.resolvedCount.toString(), Icons.check_circle, Colors.green)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildAnimatedStatCard('Pending', stats.pendingCount.toString(), Icons.hourglass_empty, Colors.red)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildAnimatedStatCard('Resolved %', '${stats.resolvedPercentage.toStringAsFixed(1)}%', Icons.percent, Colors.green)),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: _buildAnimatedStatCard('Total Users', stats.usersCount.toString(), Icons.people, Colors.blue)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildAnimatedStatCard('Total Grievances', stats.grievancesCount.toString(), Icons.assignment, Colors.orange)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildAnimatedStatCard('Resolved', stats.resolvedCount.toString(), Icons.check_circle, Colors.green)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildAnimatedStatCard('Pending', stats.pendingCount.toString(), Icons.hourglass_empty, Colors.red)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildAnimatedStatCard('Resolved %', '${stats.resolvedPercentage.toStringAsFixed(1)}%', Icons.percent, Colors.green)),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Chart Card Responsive
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Grievance Trends', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.blue[900])),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35,
                          width: double.infinity,
                          child: _buildChart(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Notifications Panel Responsive
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildNotificationsPanel(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStatCard(String title, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: double.tryParse(value.replaceAll('%', '')) ?? 0),
      duration: const Duration(milliseconds: 900),
      builder: (context, val, child) {
        return Container(
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.12), color.withOpacity(0.22)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title == 'Resolved %' ? '${val.toStringAsFixed(1)}%' : val.toInt().toString(),
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 8),
              Text(title, style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[700], fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final emailController = TextEditingController();
        final phoneController = TextEditingController();
        final passwordController = TextEditingController();
        return AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add User'),
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final phone = phoneController.text.trim();
                final password = passwordController.text.trim();
                if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) return;
                await ref.read(adminUsersProvider.notifier).addUser(name, email, phone, password);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddGrievanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final descController = TextEditingController();
        return AlertDialog(
          title: const Text('Add New Grievance'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add Grievance'),
              onPressed: () async {
                final title = titleController.text.trim();
                final desc = descController.text.trim();
                if (title.isEmpty || desc.isEmpty) return;
                await ref.read(adminGrievancesProvider.notifier).addGrievance(title, desc);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 240,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Icon(Icons.verified_user, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 14),
                Text('Gov Admin', style: GoogleFonts.inter(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSidebarItem(Icons.dashboard, 'Dashboard', 0),
                  _buildSidebarItem(Icons.assignment, 'Grievances', 1),
                  _buildSidebarItem(Icons.people, 'Users', 2),
                  _buildSidebarItem(Icons.settings, 'Settings', 3),
                  const SizedBox(height: 32),
                  _buildAccentButton(Icons.notifications, 'Notifications', Colors.purple, _toggleNotifications),
                  const SizedBox(height: 14),
                  _buildAccentButton(Icons.person_add, 'Add User', Colors.blue, () => _showAddUserDialog(context)),
                  const SizedBox(height: 14),
                  _buildAccentButton(Icons.add_comment, 'Add Grievance', Colors.orange, () => _showAddGrievanceDialog(context)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: Text('Logout', style: GoogleFonts.roboto(color: Colors.white)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              hoverColor: Colors.blue[800],
              onTap: () {
                ref.read(adminAuthProvider.notifier).logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AdminLoginScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}