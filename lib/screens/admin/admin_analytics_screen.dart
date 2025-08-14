import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/gov_theme.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  String _selectedPeriod = 'This Month';

  // Mock analytics data
  final Map<String, dynamic> _analyticsData = {
    'totalGrievances': 156,
    'resolvedGrievances': 89,
    'pendingGrievances': 45,
    'inProgressGrievances': 22,
    'averageResolutionTime': '5.2 days',
    'userSatisfactionRate': '87%',
    'categoryBreakdown': {
      'Infrastructure': 45,
      'Utilities': 32,
      'Sanitation': 28,
      'Traffic': 25,
      'Others': 26,
    },
    'monthlyData': [
      {'month': 'Jan', 'total': 120, 'resolved': 85},
      {'month': 'Feb', 'total': 135, 'resolved': 92},
      {'month': 'Mar', 'total': 156, 'resolved': 89},
    ],
    'departmentPerformance': [
      {'name': 'Public Works', 'resolved': 45, 'total': 52, 'rating': 4.2},
      {'name': 'Water Supply', 'resolved': 28, 'total': 35, 'rating': 4.0},
      {'name': 'Sanitation', 'resolved': 16, 'total': 25, 'rating': 3.8},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Actions only - no duplicate header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.file_download, color: GovTheme.primaryBlue),
                  onPressed: _exportReport,
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: GovTheme.primaryBlue),
                  onPressed: _refreshData,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  _buildPeriodSelector(),

                  const SizedBox(height: 24),

                  // KPI Cards
                  _buildKPICards(),

                  const SizedBox(height: 24),

                  // Charts Section
                  _buildChartsSection(),

                  const SizedBox(height: 24),

                  // Department Performance
                  _buildDepartmentPerformance(),

                  const SizedBox(height: 24),

                  // Reports Section
                  _buildReportsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              'Time Period:',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPeriod,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: ['This Week', 'This Month', 'Last 3 Months', 'This Year']
                    .map(
                      (period) =>
                          DropdownMenuItem(value: period, child: Text(period)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          // Mobile: 2x2 grid
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      'Total Grievances',
                      _analyticsData['totalGrievances'].toString(),
                      Icons.assignment,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildKPICard(
                      'Resolved',
                      _analyticsData['resolvedGrievances'].toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      'Avg Resolution',
                      _analyticsData['averageResolutionTime'],
                      Icons.timer,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildKPICard(
                      'Satisfaction',
                      _analyticsData['userSatisfactionRate'],
                      Icons.thumb_up,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop: Single row
          return Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Total Grievances',
                  _analyticsData['totalGrievances'].toString(),
                  Icons.assignment,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Resolved',
                  _analyticsData['resolvedGrievances'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Avg Resolution',
                  _analyticsData['averageResolutionTime'],
                  Icons.timer,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Satisfaction',
                  _analyticsData['userSatisfactionRate'],
                  Icons.thumb_up,
                  Colors.purple,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          // Mobile: Stack vertically
          return Column(
            children: [
              _buildTrendChart(),
              const SizedBox(height: 16),
              _buildCategoryChart(),
            ],
          );
        } else {
          // Desktop: Side by side
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildTrendChart()),
              const SizedBox(width: 16),
              Expanded(child: _buildCategoryChart()),
            ],
          );
        }
      },
    );
  }

  Widget _buildTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Trends',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 200, child: _buildMockLineChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildMockLineChart() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Mock chart placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Chart showing grievance trends over time',
                  style: GoogleFonts.roboto(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Mock data points
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _analyticsData['monthlyData']
                  .map<Widget>(
                    (data) => Column(
                      children: [
                        Text(
                          data['total'].toString(),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          data['month'],
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ..._analyticsData['categoryBreakdown'].entries.map<Widget>(
              (entry) => _buildCategoryItem(
                entry.key,
                entry.value,
                _analyticsData['totalGrievances'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, int count, int total) {
    final percentage = (count / total * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: GoogleFonts.roboto(fontSize: 14)),
              Text(
                '$count ($percentage%)',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getCategoryColor(category),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Infrastructure':
        return Colors.blue;
      case 'Utilities':
        return Colors.green;
      case 'Sanitation':
        return Colors.orange;
      case 'Traffic':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDepartmentPerformance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Department Performance',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Mobile: Card layout
                  return Column(
                    children: _analyticsData['departmentPerformance']
                        .map<Widget>((dept) => _buildDepartmentCard(dept))
                        .toList(),
                  );
                } else {
                  // Desktop: Table layout
                  return _buildDepartmentTable();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(Map<String, dynamic> dept) {
    final efficiency = (dept['resolved'] / dept['total'] * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dept['name'],
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _buildRatingStars(dept['rating']),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Resolved: ${dept['resolved']}/${dept['total']} ($efficiency%)',
              style: GoogleFonts.roboto(fontSize: 14),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: efficiency / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                efficiency > 80
                    ? Colors.green
                    : efficiency > 60
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'Department',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Resolved',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Total',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Efficiency',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Rating',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: _analyticsData['departmentPerformance'].map<DataRow>((dept) {
          final efficiency = (dept['resolved'] / dept['total'] * 100).round();
          return DataRow(
            cells: [
              DataCell(Text(dept['name'])),
              DataCell(Text(dept['resolved'].toString())),
              DataCell(Text(dept['total'].toString())),
              DataCell(
                Row(
                  children: [
                    Text('$efficiency%'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: LinearProgressIndicator(
                        value: efficiency / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          efficiency > 80
                              ? Colors.green
                              : efficiency > 60
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(_buildRatingStars(dept['rating'])),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
              ? Icons.star_half
              : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }

  Widget _buildReportsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate Reports',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Mobile: Stack vertically
                  return Column(
                    children: [
                      _buildReportButton(
                        'Detailed Analytics Report',
                        'Comprehensive overview of all metrics',
                        Icons.analytics,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildReportButton(
                        'Department Performance Report',
                        'Performance analysis by department',
                        Icons.business,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildReportButton(
                        'Citizen Satisfaction Survey',
                        'Feedback and satisfaction metrics',
                        Icons.sentiment_satisfied,
                        Colors.orange,
                      ),
                    ],
                  );
                } else {
                  // Desktop: Side by side
                  return Row(
                    children: [
                      Expanded(
                        child: _buildReportButton(
                          'Detailed Analytics Report',
                          'Comprehensive overview of all metrics',
                          Icons.analytics,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildReportButton(
                          'Department Performance Report',
                          'Performance analysis by department',
                          Icons.business,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildReportButton(
                          'Citizen Satisfaction Survey',
                          'Feedback and satisfaction metrics',
                          Icons.sentiment_satisfied,
                          Colors.orange,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _generateReport(title),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Generate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 36),
            ),
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting analytics report...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _refreshData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing analytics data...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateReport(String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $reportType...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
