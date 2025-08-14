import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../core/theme/gov_theme.dart';
import '../../providers/admin_providers_fix.dart';
import 'admin_grievance_timeline.dart';
import '../../core/utils/web_utils.dart';

class AdminGrievancesScreen extends ConsumerStatefulWidget {
  const AdminGrievancesScreen({super.key});

  @override
  ConsumerState<AdminGrievancesScreen> createState() =>
      _AdminGrievancesScreenState();
}

class _AdminGrievancesScreenState extends ConsumerState<AdminGrievancesScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Quick Actions Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: GovTheme.primaryBlue),
                  onPressed: () {
                    // Refresh real data
                    ref.read(adminGrievancesProvider.notifier).fetchGrievances();
                    ref.invalidate(dashboardStatsProvider);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.download, color: GovTheme.primaryBlue),
                  tooltip: 'Export Grievances',
                  onPressed: () => _exportGrievances(),
                ),
              ],
            ),
          ),

          // Search and Filter Bar
          _buildSearchAndFilterBar(),

          // Stats Cards
          _buildStatsCards(),

          // Grievances List
          Expanded(child: _buildGrievancesList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search grievances...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          const SizedBox(width: 16),

          // Status Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: ['All', 'Pending', 'In Progress', 'Resolved']
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Consumer(
        builder: (context, ref, child) {
          final dashboardState = ref.watch(dashboardStatsProvider);
          final totalCount = dashboardState.stats['totalGrievances'] ?? 0;
          final pendingCount = dashboardState.stats['pendingGrievances'] ?? 0;
          final inProgressCount = dashboardState.stats['inProgressGrievances'] ?? 0;
          final resolvedCount = dashboardState.stats['resolvedGrievances'] ?? 0;

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Stack in 2x2 grid on smaller screens
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total',
                            totalCount.toString(),
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            pendingCount.toString(),
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'In Progress',
                            inProgressCount.toString(),
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Resolved',
                            resolvedCount.toString(),
                            Colors.green,
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
                        'Total',
                        totalCount.toString(),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Pending',
                        pendingCount.toString(),
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'In Progress',
                        inProgressCount.toString(),
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Resolved',
                        resolvedCount.toString(),
                        Colors.green,
                      ),
                    ),
                  ],
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: GoogleFonts.roboto(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildGrievancesList() {
    return Consumer(
      builder: (context, ref, child) {
        final grievancesAsync = ref.watch(adminGrievancesProvider);

        // Initialize grievances fetch if needed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (grievancesAsync.grievances.isEmpty &&
              !grievancesAsync.isLoading) {
            ref.read(adminGrievancesProvider.notifier).fetchGrievances();
          }
        });

        if (grievancesAsync.isLoading && grievancesAsync.grievances.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (grievancesAsync.error != null &&
            grievancesAsync.grievances.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading grievances',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  grievancesAsync.error!,
                  style: GoogleFonts.roboto(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(adminGrievancesProvider.notifier).fetchGrievances();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Filter grievances based on search and status
        List<Map<String, dynamic>> filteredGrievances = grievancesAsync
            .grievances
            .where((grievance) {
              bool statusMatch =
                  _selectedFilter == 'All' ||
                  grievance['status'] == _selectedFilter;

              bool searchMatch =
                  _searchQuery.isEmpty ||
                  grievance['title']?.toString().toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ==
                      true ||
                  grievance['citizen_name']?.toString().toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ==
                      true ||
                  grievance['grievance_number']?.toString().toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ==
                      true;

              return statusMatch && searchMatch;
            })
            .toList();

        if (filteredGrievances.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No grievances found',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
                  Text(
                    'Try adjusting your filters',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                // Mobile card layout
                return _buildMobileGrievancesList(filteredGrievances);
              } else {
                // Desktop table layout with horizontal scroll
                return _buildDesktopGrievancesList(filteredGrievances);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMobileGrievancesList(List<Map<String, dynamic>> grievances) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grievances.length,
      itemBuilder: (context, index) {
        final grievance = grievances[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grievance['title'] ?? 'No Title',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            grievance['grievance_number'] ??
                                grievance['id']?.toString() ??
                                'N/A',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(grievance['status'] ?? 'Pending'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  grievance['description'] ?? 'No description available',
                  style: GoogleFonts.roboto(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        grievance['citizen_name'] ?? 'Unknown',
                        style: GoogleFonts.roboto(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      grievance['category'] ?? 'General',
                      style: GoogleFonts.roboto(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      grievance['priority'] ?? 'Medium',
                      style: GoogleFonts.roboto(fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(grievance['submitted_at']),
                      style: GoogleFonts.roboto(fontSize: 14),
                    ),
                  ],
                ),
                if (grievance['location_address'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          grievance['location_address'],
                          style: GoogleFonts.roboto(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showGrievanceDetails(grievance),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                    ),
                    TextButton.icon(
                      onPressed: () => _editGrievance(grievance),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopGrievancesList(List<Map<String, dynamic>> grievances) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1400, // Fixed width for table
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
                  SizedBox(width: 120, child: _buildHeaderCell('ID')),
                  SizedBox(
                    width: 250,
                    child: _buildHeaderCell('Title & Description'),
                  ),
                  SizedBox(width: 150, child: _buildHeaderCell('Citizen')),
                  SizedBox(width: 120, child: _buildHeaderCell('Category')),
                  SizedBox(width: 100, child: _buildHeaderCell('Status')),
                  SizedBox(width: 100, child: _buildHeaderCell('Priority')),
                  SizedBox(width: 120, child: _buildHeaderCell('Date')),
                  SizedBox(width: 150, child: _buildHeaderCell('Location')),
                  SizedBox(width: 120, child: _buildHeaderCell('Actions')),
                ],
              ),
            ),

            // Table Body
            Expanded(
              child: ListView.builder(
                itemCount: grievances.length,
                itemBuilder: (context, index) {
                  final grievance = grievances[index];
                  return _buildGrievanceRow(grievance, index);
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

  Widget _buildGrievanceRow(Map<String, dynamic> grievance, int index) {
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
              grievance['grievance_number'] ?? grievance['id']?.toString() ?? 'N/A',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: GovTheme.primaryBlue,
              ),
            ),
          ),
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grievance['title'] ?? 'No Title',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  grievance['description'] ?? 'No description',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              grievance['citizen_name'] ?? 'Unknown',
              style: GoogleFonts.roboto(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              grievance['category'] ?? 'General',
              style: GoogleFonts.roboto(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 100, child: _buildStatusChip(grievance['status'] ?? 'Pending')),
          SizedBox(
            width: 100,
            child: _buildPriorityChip(grievance['priority'] ?? 'Medium'),
          ),
          SizedBox(
            width: 120,
            child: Text(
              _formatDate(grievance['submitted_at']),
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              grievance['location_address'] ?? 'N/A',
              style: GoogleFonts.roboto(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () => _viewGrievance(grievance),
                  color: GovTheme.primaryBlue,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editGrievance(grievance),
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'In Progress':
        color = Colors.blue;
        break;
      case 'Resolved':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'High':
        color = Colors.red;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      case 'Low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority,
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _viewGrievance(Map<String, dynamic> grievance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Grievance Details',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${grievance['grievance_number'] ?? grievance['id'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Title: ${grievance['title'] ?? 'No Title'}'),
              const SizedBox(height: 8),
              Text('Description: ${grievance['description'] ?? 'No description'}'),
              const SizedBox(height: 8),
              Text('Citizen: ${grievance['citizen_name'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Category: ${grievance['category'] ?? 'General'}'),
              const SizedBox(height: 8),
              Text('Status: ${grievance['status'] ?? 'Pending'}'),
              const SizedBox(height: 8),
              Text('Priority: ${grievance['priority'] ?? 'Medium'}'),
              const SizedBox(height: 8),
              Text('Date: ${_formatDate(grievance['submitted_at'])}'),
              const SizedBox(height: 8),
              Text('Location: ${grievance['location_address'] ?? 'N/A'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editGrievance(Map<String, dynamic> grievance) {
    showDialog(
      context: context,
      builder: (context) => _StatusUpdateDialog(grievance: grievance),
    );
  }

  // Helper Methods
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      final date = dateValue is String
          ? DateTime.parse(dateValue)
          : dateValue as DateTime;
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  void _showGrievanceDetails(Map<String, dynamic> grievance) {
    // Fetch status history for this grievance (simulate or use actual API if available)
    // For now, assume status_history is present in the grievance map or empty list
    final List<Map<String, dynamic>> statusHistory =
        List<Map<String, dynamic>>.from(grievance['status_history'] ?? []);
    final DateTime submittedAt = grievance['submitted_at'] is DateTime
        ? grievance['submitted_at']
        : DateTime.tryParse(grievance['submitted_at']?.toString() ?? '') ??
              DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(grievance['title'] ?? 'Grievance Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'ID:',
                grievance['grievance_number'] ??
                    grievance['id']?.toString() ??
                    'N/A',
              ),
              _buildDetailRow('Status:', grievance['status'] ?? 'Pending'),
              _buildDetailRow('Priority:', grievance['priority'] ?? 'Medium'),
              _buildDetailRow('Category:', grievance['category'] ?? 'General'),
              _buildDetailRow(
                'Submitted By:',
                grievance['citizen_name'] ?? 'Unknown',
              ),
              _buildDetailRow('Date:', _formatDate(grievance['submitted_at'])),
              if (grievance['location_address'] != null)
                _buildDetailRow('Location:', grievance['location_address']),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(grievance['description'] ?? 'No description available'),
              const SizedBox(height: 24),
              // Timeline for admin (same as user)
              AdminGrievanceTimeline(
                statusHistory: statusHistory,
                submittedAt: submittedAt,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _exportGrievances() {
    final grievancesState = ref.read(adminGrievancesProvider);
    final grievances = grievancesState.grievances;

    if (grievances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No grievances data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // CSV headers
      final List<List<String>> csvData = [
        [
          'ID',
          'Grievance Number',
          'Title',
          'Description',
          'Citizen Name',
          'Category',
          'Status',
          'Priority',
          'Submitted Date',
          'Location',
          'Submitted By',
        ],
      ];

      // Add grievance data
      for (final grievance in grievances) {
        csvData.add([
          (grievance['id']?.toString() ?? ''),
          (grievance['grievance_number']?.toString() ??
              grievance['id']?.toString() ??
              ''),
          (grievance['title']?.toString() ?? ''),
          (grievance['description']?.toString() ?? ''),
          (grievance['citizen_name']?.toString() ?? ''),
          (grievance['category']?.toString() ?? ''),
          (grievance['status']?.toString() ?? ''),
          (grievance['priority']?.toString() ?? ''),
          _formatDate(grievance['submitted_at']),
          (grievance['location_address']?.toString() ?? ''),
          (grievance['citizen_name']?.toString() ?? ''),
        ]);
      }

      // Generate CSV string
      final String csvString = const ListToCsvConverter().convert(csvData);

      // Platform-specific download
      try {
        downloadCsv(
          csvString,
          'grievances_export_${DateTime.now().millisecondsSinceEpoch}.csv',
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
            content: Text(
              'Exported ${grievances.length} grievances successfully!',
            ),
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
}

// Status Update Dialog with Image Attachment
class _StatusUpdateDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> grievance;

  const _StatusUpdateDialog({required this.grievance});

  @override
  ConsumerState<_StatusUpdateDialog> createState() =>
      _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends ConsumerState<_StatusUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  late String _selectedStatus;
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'Submitted',
    'Under Review',
    'In Progress',
    'Resolved',
    'Rejected',
    'Closed',
    'On Hold',
  ];

  @override
  void initState() {
    super.initState();
    // Get current status or default to 'Under Review'
    final currentStatus = widget.grievance['status'] ?? 'Under Review';
    
    // Validate that the status is in the options list, otherwise use first status
    _selectedStatus = _statusOptions.contains(currentStatus) 
        ? currentStatus 
        : _statusOptions.first;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (!mounted) return;

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _updateGrievanceStatus() async {
    if (!_formKey.currentState!.validate()) return;

    if (_messageController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message for the user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First, upload images if any are selected
      List<String> uploadedImageUrls = [];

      if (_selectedImages.isNotEmpty) {
        // Show uploading images message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Uploading ${_selectedImages.length} images...'),
              ],
            ),
            backgroundColor: GovTheme.primaryBlue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Upload each image (simulate for now)
        for (int i = 0; i < _selectedImages.length; i++) {
          // In real implementation, upload to server here
          // For now, simulate with delay and generate mock URL
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;

          // Generate mock uploaded image URL
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final imageUrl =
              'progress_photos/grievance_${widget.grievance['id']}_${timestamp}_$i.jpg';
          uploadedImageUrls.add(imageUrl);
        }
      }

      // Now update the grievance status with the uploaded image URLs
      final grievanceId = widget.grievance['id']?.toString() ?? '';
      final success = await ref
          .read(adminGrievancesProvider.notifier)
          .updateGrievanceStatus(
            grievanceId,
            _selectedStatus,
            _messageController.text.trim(),
            uploadedImageUrls,
            ref: ref,
          );
      if (!mounted) return;

      if (success) {
        Navigator.pop(context);

        // Show success message with image count
        final imageText = uploadedImageUrls.isNotEmpty
            ? ' with ${uploadedImageUrls.length} progress photos'
            : '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Status updated to $_selectedStatus successfully$imageText',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh the grievances list
        ref.read(adminGrievancesProvider.notifier).fetchGrievances();
      } else {
        throw Exception('Failed to update grievance status');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to update status: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              color: GovTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.edit_note, color: GovTheme.primaryBlue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Status',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: GovTheme.darkGray,
                  ),
                ),
                Text(
                  'ID: ${widget.grievance['id'] ?? widget.grievance['grievance_number']}',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grievance Title
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
                        'Grievance: ${widget.grievance['title'] ?? 'N/A'}',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          color: GovTheme.darkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current Status: ${widget.grievance['status'] ?? 'Pending'}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // New Status Dropdown
                Text(
                  'New Status:',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                    color: GovTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  items: _statusOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || !_statusOptions.contains(value)) {
                      return 'Please select a valid status';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Message to User
                Text(
                  'Message to User (will appear in timeline)',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                    color: GovTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'This message is required and will be visible to the user in their timeline.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Message is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Image Attachment Section
                Row(
                  children: [
                    Text(
                      'Attach Images (Optional)',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w500,
                        color: GovTheme.darkGray,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate, size: 18),
                      label: const Text('Add Images'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GovTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FutureBuilder<Uint8List>(
                                    future: _selectedImages[index]
                                        .readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        );
                                      } else {
                                        return Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedImages.length} image(s) selected',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No images selected',
                          style: GoogleFonts.roboto(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
          onPressed: _isLoading ? null : _updateGrievanceStatus,
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
              : const Text('Update Status'),
        ),
      ],
    );
  }
}