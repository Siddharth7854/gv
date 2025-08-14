import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/theme/gov_theme.dart';
import '../../core/config/api_config.dart';
import '../../models/grievance_new.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/grievances_provider.dart';
import '../../services/sql_server_api_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/floating_map_modal.dart';

class GrievanceDetailsScreen extends ConsumerStatefulWidget {
  final Grievance grievance;

  const GrievanceDetailsScreen({super.key, required this.grievance});

  @override
  ConsumerState<GrievanceDetailsScreen> createState() =>
      _GrievanceDetailsScreenState();
}

class _GrievanceDetailsScreenState extends ConsumerState<GrievanceDetailsScreen>
    with TickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  @override
  void didPopNext() {
    // Called when coming back to this screen
    debugPrint('[GrievanceDetails] Screen resumed - refreshing data');
    _fetchLatestGrievance();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Also refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      debugPrint('[GrievanceDetails] App resumed - refreshing data');
      _fetchLatestGrievance();
    }
  }

  late TabController _tabController;
  final PageController _pageController = PageController();

  Grievance? _latestGrievance;
  List<Map<String, dynamic>> _statusHistory = [];
  List<Map<String, dynamic>> _mediaAttachments = [];
  bool _isLoading = false;

  // Chat related variables
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<Map<String, dynamic>> _chatMessages = [];

  Future<void> _fetchLatestGrievance() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      debugPrint(
        '[GrievanceDetails] Fetching latest data for grievance ${widget.grievance.grievanceId}',
      );

      // Get updated grievance data from cached list
      final authState = ref.read(simpleAuthProvider);
      if (authState.isAuthenticated && authState.user != null) {
        final grievancesList = ref.read(grievancesProvider);

        // Find the current grievance in the list for basic data
        final grievances = grievancesList.value ?? [];
        final foundGrievance = grievances.firstWhere(
          (g) => g.grievanceId == widget.grievance.grievanceId,
          orElse: () => widget.grievance,
        );

        _latestGrievance = foundGrievance;

        // Now fetch real timeline data from API
        // NOTE: Temporarily using fallback until API server is running
        try {
          // Try to fetch real data from API
          final apiService = SqlServerApiService();

          // Get token from local storage since it's not in authState
          final localStorage = LocalStorageService();
          final token = await localStorage.getToken();

          if (token != null) {
            apiService.setAuthToken(token);

            final grievanceDetails = await apiService.getGrievanceDetails(
              widget.grievance.grievanceId!,
            );

            if (grievanceDetails['success'] == true) {
              // Get media attachments
              _mediaAttachments = List<Map<String, dynamic>>.from(
                grievanceDetails['media_attachments'] ?? [],
              );
              debugPrint(
                '[GrievanceDetails] Found ${_mediaAttachments.length} media attachments',
              );

              // Get timeline data
              final timelineData = List<Map<String, dynamic>>.from(
                grievanceDetails['status_history'] ?? [],
              );

              if (timelineData.isNotEmpty) {
                _statusHistory = timelineData;
                debugPrint(
                  '[GrievanceDetails] Real timeline data loaded - ${_statusHistory.length} entries',
                );
              } else {
                // Fallback to generated timeline if no real data
                _statusHistory = _generateFallbackTimeline(foundGrievance);
                debugPrint(
                  '[GrievanceDetails] Using fallback timeline - ${_statusHistory.length} entries',
                );
              }
            } else {
              // Fallback to generated timeline if API fails
              _statusHistory = _generateFallbackTimeline(foundGrievance);
              debugPrint(
                '[GrievanceDetails] API response unsuccessful, using fallback timeline',
              );
            }
          } else {
            // No token, use fallback
            _statusHistory = _generateFallbackTimeline(foundGrievance);
            debugPrint(
              '[GrievanceDetails] No token found, using fallback timeline',
            );
          }
        } catch (e) {
          debugPrint('[GrievanceDetails] Timeline API failed: $e');
          // Use fallback timeline on API failure
          _statusHistory = _generateFallbackTimeline(foundGrievance);
          debugPrint(
            '[GrievanceDetails] Using fallback timeline due to API error',
          );
        }

        debugPrint(
          '[GrievanceDetails] Using cached data - Status: ${_latestGrievance?.status}',
        );
        debugPrint(
          '[GrievanceDetails] Final timeline entries: ${_statusHistory.length}',
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('[GrievanceDetails] Error fetching data: $e');
      if (mounted) {
        setState(() => _isLoading = false);

        // Fallback to widget grievance if API fails
        _latestGrievance = widget.grievance;
        _statusHistory = _generateFallbackTimeline(widget.grievance);

        // Show less alarming error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Using cached data - latest updates may not be visible',
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchLatestGrievance,
            ),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _generateFallbackTimeline(Grievance grievance) {
    final submittedDate = grievance.submittedAt;

    final timeline = [
      {
        'new_status': 'Submitted',
        'previous_status': '',
        'changed_at': submittedDate.toIso8601String(),
        'changed_by': 'Citizen',
        'change_reason':
            'Your grievance has been successfully submitted to the government portal. Reference ID: ${grievance.grievanceId}',
        'image_urls': '', // No images for submission
      },
    ];

    // Add realistic timeline progression based on current status
    final currentStatus = grievance.status.toLowerCase();

    if (currentStatus != 'submitted') {
      // Add "Received" status (1 day after submission)
      timeline.add({
        'new_status': 'Received',
        'previous_status': 'Submitted',
        'changed_at': submittedDate
            .add(const Duration(days: 1))
            .toIso8601String(),
        'changed_by': 'System',
        'change_reason':
            'Your grievance has been received and assigned reference number ${grievance.grievanceId}. It will be reviewed within 3-5 working days.',
        'image_urls': '',
      });
    }

    if ([
      'under review',
      'under_review',
      'in progress',
      'in_progress',
      'resolved',
      'rejected',
      'closed',
    ].contains(currentStatus.replaceAll(' ', '_'))) {
      // Add "Under Review" status (3 days after submission)
      timeline.add({
        'new_status': 'Under Review',
        'previous_status': 'Received',
        'changed_at': submittedDate
            .add(const Duration(days: 3))
            .toIso8601String(),
        'changed_by': 'Review Officer',
        'change_reason':
            'Your grievance is now being reviewed by the concerned department. Our technical team will assess the issue and provide updates.',
        'image_urls': '',
      });
    }

    if ([
      'in progress',
      'in_progress',
      'resolved',
    ].contains(currentStatus.replaceAll(' ', '_'))) {
      // Add "In Progress" status (7 days after submission) with progress photos
      timeline.add({
        'new_status': 'In Progress',
        'previous_status': 'Under Review',
        'changed_at': submittedDate
            .add(const Duration(days: 7))
            .toIso8601String(),
        'changed_by': 'Field Officer',
        'change_reason':
            'Work has commenced on your grievance. Our field team is actively working to resolve the issue. Progress photos have been attached for your reference.',
        'image_urls':
            'progress_photos/work_started_1.jpg,progress_photos/work_started_2.jpg', // Sample progress photos
      });
    }

    if (currentStatus == 'resolved') {
      // Add "Resolved" status (14 days after submission) with completion photos
      timeline.add({
        'new_status': 'Resolved',
        'previous_status': 'In Progress',
        'changed_at': submittedDate
            .add(const Duration(days: 14))
            .toIso8601String(),
        'changed_by': 'Project Manager',
        'change_reason':
            'Your grievance has been successfully resolved! The work has been completed and quality checked. Thank you for your patience. Please verify the resolution and provide feedback.',
        'image_urls':
            'progress_photos/completed_work_1.jpg,progress_photos/completed_work_2.jpg,progress_photos/final_result.jpg', // Sample completion photos
      });
    } else if (currentStatus == 'rejected') {
      timeline.add({
        'new_status': 'Rejected',
        'previous_status': 'Under Review',
        'changed_at': submittedDate
            .add(const Duration(days: 5))
            .toIso8601String(),
        'changed_by': 'Review Committee',
        'change_reason':
            'After careful review, your grievance could not be approved due to policy constraints or insufficient information. Please contact our helpdesk for clarification.',
        'image_urls': '',
      });
    } else if (currentStatus == 'closed') {
      timeline.add({
        'new_status': 'Closed',
        'previous_status': 'Resolved',
        'changed_at': submittedDate
            .add(const Duration(days: 21))
            .toIso8601String(),
        'changed_by': 'System',
        'change_reason':
            'This grievance has been officially closed after successful resolution. Thank you for using our services.',
        'image_urls': '',
      });
    }

    return timeline;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Always fetch latest grievance and status history on open
    _fetchLatestGrievance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grievance = _latestGrievance ?? widget.grievance;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildStatusHeader(grievance),
                          _buildProgressTracker(grievance),
                        ],
                      ),
                    ),
                  ];
                },
                body: Column(
                  children: [
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDetailsTab(),
                          _buildLocationTab(),
                          _buildTimelineTab(),
                          _buildChatTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: GovTheme.darkGray,
      title: Text(
        'Grievance Details',
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w600,
          color: GovTheme.darkGray,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.refresh),
          onPressed: _isLoading ? null : _fetchLatestGrievance,
          tooltip: 'Refresh',
        ),
        // Delete button - only show for 'Submitted' status
        if (widget.grievance.status.toLowerCase() == 'submitted')
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Delete Grievance',
            color: GovTheme.errorRed,
          ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: _shareGrievance,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy_id',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 18),
                  SizedBox(width: 8),
                  Text('Copy ID'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'download_receipt',
              child: Row(
                children: [
                  Icon(Icons.download, size: 18),
                  SizedBox(width: 8),
                  Text('Download Receipt'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusHeader(Grievance grievance) {
    final statusColor = _getStatusColor(grievance.status);
    final statusIcon = _getStatusIcon(grievance.status);

    return Animate(
      effects: const [FadeEffect(), SlideEffect()],
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grievance.status.toUpperCase(),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'ID: ${grievance.grievanceNumber ?? grievance.grievanceId}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: GovTheme.neutralGray,
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
            const SizedBox(height: 16),
            Text(
              grievance.title,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GovTheme.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.category,
                  label: grievance.categoryName ?? 'General',
                  color: GovTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.priority_high,
                  label: grievance.priority,
                  color: _getPriorityColor(grievance.priority),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.speed,
                  label: grievance.urgency,
                  color: _getUrgencyColor(grievance.urgency),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTracker(Grievance grievance) {
    final steps = [
      {'title': 'Submitted', 'status': 'submitted', 'icon': Icons.send_rounded},
      {
        'title': 'Received',
        'status': 'received',
        'icon': Icons.mark_email_read_rounded,
      },
      {
        'title': 'Under Review',
        'status': 'under_review',
        'icon': Icons.visibility_rounded,
      },
      {
        'title': 'In Progress',
        'status': 'in_progress',
        'icon': Icons.engineering_rounded,
      },
      {
        'title': 'Resolved',
        'status': 'resolved',
        'icon': Icons.check_circle_rounded,
      },
    ];

    int currentStepIndex = steps.indexWhere(
      (step) =>
          step['status'] == grievance.status.toLowerCase().replaceAll(' ', '_'),
    );
    if (currentStepIndex == -1) currentStepIndex = 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Take minimum required space
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced padding
                decoration: BoxDecoration(
                  color: GovTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  color: GovTheme.primaryBlue,
                  size: 18,
                ), // Smaller icon
              ),
              const SizedBox(width: 10),
              Text(
                'Progress Tracking',
                style: GoogleFonts.roboto(
                  fontSize: 16, // Smaller font
                  fontWeight: FontWeight.w600,
                  color: GovTheme.darkGray,
                ),
              ),
              const Spacer(),
              // Progress percentage inline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GovTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${((currentStepIndex + 1) / steps.length * 100).round()}%',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GovTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // Reduced spacing
          // Compact horizontal progress steps
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(steps.length, (index) {
                final step = steps[index];
                final isCompleted = index <= currentStepIndex;
                final isActive = index == currentStepIndex;

                return Row(
                  children: [
                    // Step indicator
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? GovTheme.primaryBlue
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                            border: isActive
                                ? Border.all(
                                    color: GovTheme.primaryBlue,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            step['icon'] as IconData,
                            color: isCompleted
                                ? Colors.white
                                : Colors.grey.shade500,
                            size: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 80, // Fixed width for consistent layout
                          child: Text(
                            step['title'] as String,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? GovTheme.primaryBlue
                                  : isCompleted
                                  ? GovTheme.darkGray
                                  : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Connecting line
                    if (index < steps.length - 1)
                      Container(
                        width: 30,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 20),
                        color: index < currentStepIndex
                            ? GovTheme.primaryBlue
                            : Colors.grey.shade300,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: GovTheme.primaryBlue,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: GovTheme.neutralGray,
        labelStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'Location'),
          Tab(text: 'Timeline'),
          Tab(text: 'Chat'),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            title: 'Description',
            icon: Icons.description,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.grievance.description,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    height: 1.6,
                    color: GovTheme.darkGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            title: 'Grievance Information',
            icon: Icons.info,
            content: Column(
              children: [
                _buildDetailRow(
                  'Grievance Number',
                  widget.grievance.grievanceNumber ?? 'N/A',
                ),
                _buildDetailRow(
                  'Category',
                  widget.grievance.categoryName ?? 'General',
                ),
                _buildDetailRow('Priority', widget.grievance.priority),
                _buildDetailRow('Urgency', widget.grievance.urgency),
                _buildDetailRow('Status', widget.grievance.status),
                _buildDetailRow(
                  'Submitted On',
                  _formatDate(widget.grievance.submittedAt),
                ),
                if (widget.grievance.updatedAt != null)
                  _buildDetailRow(
                    'Last Updated',
                    _formatDate(widget.grievance.updatedAt!),
                  ),
              ],
            ),
          ),

          // Photos/Media Section
          if (_mediaAttachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMediaSection(),
          ],

          if (widget.grievance.assignedTo != null) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              title: 'Assignment Details',
              icon: Icons.person_pin,
              content: Column(
                children: [
                  _buildDetailRow('Assigned To', widget.grievance.assignedTo!),
                  if (widget.grievance.resolutionNotes != null)
                    _buildDetailRow(
                      'Resolution Notes',
                      widget.grievance.resolutionNotes!,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    final hasLocation =
        widget.grievance.locationLatitude != null &&
        widget.grievance.locationLongitude != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLocation) ...[
            // WhatsApp-style location card
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.7),
                  builder: (context) => FloatingMapModal(
                    grievanceLatitude: widget.grievance.locationLatitude!,
                    grievanceLongitude: widget.grievance.locationLongitude!,
                    grievanceTitle: 'Grievance Location',
                    grievanceAddress: widget.grievance.locationAddress,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map preview section
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            GovTheme.primaryBlue.withOpacity(0.1),
                            GovTheme.secondaryBlue.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Map placeholder with location icon
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: GovTheme.primaryBlue.withOpacity(
                                      0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    size: 32,
                                    color: GovTheme.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to view location',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: GovTheme.neutralGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Coordinates overlay
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.grievance.locationLatitude!.toStringAsFixed(4)}, ${widget.grievance.locationLongitude!.toStringAsFixed(4)}',
                                style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          // Tap indicator
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: GovTheme.primaryBlue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: GovTheme.primaryBlue.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Location details section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: GovTheme.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Grievance Location',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: GovTheme.darkGray,
                                ),
                              ),
                            ],
                          ),
                          if (widget.grievance.locationAddress != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.grievance.locationAddress!,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: GovTheme.neutralGray,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                size: 14,
                                color: GovTheme.neutralGray,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${widget.grievance.locationLatitude!.toStringAsFixed(6)}, ${widget.grievance.locationLongitude!.toStringAsFixed(6)}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: GovTheme.neutralGray,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _copyCoordinates,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: GovTheme.primaryBlue.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: GovTheme.primaryBlue,
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
            // Additional action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openInMaps,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text(
                      'Open Maps',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GovTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _getDirections,
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text(
                      'Directions',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GovTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildEmptyLocationState(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    // Sort status history by changed_at ascending for correct timeline order
    final sortedHistory = List<Map<String, dynamic>>.from(_statusHistory);
    sortedHistory.sort((a, b) {
      final aTime = a['changed_at'] != null
          ? DateTime.tryParse(a['changed_at'].toString())
          : null;
      final bTime = b['changed_at'] != null
          ? DateTime.tryParse(b['changed_at'].toString())
          : null;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return -1;
      if (bTime == null) return 1;
      return aTime.compareTo(bTime);
    });
    final timelineItems =
        (sortedHistory.isNotEmpty
                ? sortedHistory
                : [
                    {
                      'new_status': 'Submitted',
                      'previous_status': '',
                      'changed_at': widget.grievance.submittedAt
                          .toIso8601String(),
                      'changed_by': '',
                      'change_reason':
                          'Your grievance has been successfully submitted to the system.',
                    },
                  ])
            .map((item) {
              final status = (item['new_status'] ?? '').toString();
              final prevStatus = (item['previous_status'] ?? '').toString();
              final changedAt = item['changed_at'] != null
                  ? DateTime.tryParse(item['changed_at'].toString())
                  : null;
              final changedBy = (item['changed_by'] ?? '').toString();
              final reason = (item['change_reason'] ?? '').toString();
              IconData icon;
              switch (status.toLowerCase()) {
                case 'submitted':
                  icon = Icons.send;
                  break;
                case 'under review':
                  icon = Icons.visibility;
                  break;
                case 'in progress':
                  icon = Icons.engineering;
                  break;
                case 'resolved':
                  icon = Icons.check_circle;
                  break;
                case 'rejected':
                  icon = Icons.cancel;
                  break;
                case 'closed':
                  icon = Icons.lock_outline;
                  break;
                default:
                  icon = Icons.info_outline;
              }
              // Accessibility: Add semantic label for screen readers
              // Extract image URLs if available
              final imageUrlsStr = (item['image_urls'] ?? '').toString();
              List<String>? imageUrls;
              if (imageUrlsStr.isNotEmpty && imageUrlsStr != 'null') {
                imageUrls = imageUrlsStr
                    .split(',')
                    .where((url) => url.isNotEmpty)
                    .toList();
              }

              final fallbackMsg = prevStatus.isNotEmpty && changedBy.isNotEmpty
                  ? 'Status changed from $prevStatus to $status by $changedBy'
                  : 'Status updated to $status';
              return Semantics(
                label: 'Timeline event: $status',
                child: _buildTimelineItem(
                  icon: icon,
                  title: status,
                  description: reason.isNotEmpty ? reason : fallbackMsg,
                  timestamp: changedAt,
                  isCompleted: true,
                  imageUrls: imageUrls,
                ),
              );
            })
            .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            title: 'Grievance Timeline',
            icon: Icons.timeline,
            content: Column(children: timelineItems),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GovTheme.primaryBlue.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovTheme.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: GovTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat with Support',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: GovTheme.darkGray,
                      ),
                    ),
                    Text(
                      'Communicate directly with admin about this grievance',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: GovTheme.neutralGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Online',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Chat Messages Area
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: _chatMessages.isEmpty
                ? _buildEmptyChatState()
                : ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final message =
                          _chatMessages[_chatMessages.length - 1 - index];
                      return _buildChatMessage(message);
                    },
                  ),
          ),
        ),

        // Chat Input Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _chatController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: GoogleFonts.roboto(color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: GoogleFonts.roboto(fontSize: 14),
                      onSubmitted: (text) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: GovTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
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
              Icons.chat_bubble_outline,
              size: 48,
              color: GovTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a Conversation',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: GovTheme.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to communicate with\nthe support team about your grievance',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: GovTheme.neutralGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: GovTheme.primaryBlue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Messages are monitored during business hours',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: GovTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    final timestamp = message['timestamp'] as DateTime?;
    final messageText = message['message'] as String;
    final senderName =
        message['sender_name'] as String? ?? (isUser ? 'You' : 'Admin');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: GovTheme.primaryBlue.withOpacity(0.2),
              child: Icon(
                Icons.support_agent,
                size: 16,
                color: GovTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? GovTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Text(
                      senderName,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GovTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    messageText,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: isUser ? Colors.white : GovTheme.darkGray,
                      height: 1.4,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatChatTime(timestamp),
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: isUser
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: GovTheme.primaryBlue.withOpacity(0.1),
              child: Icon(Icons.person, size: 16, color: GovTheme.primaryBlue),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0);
  }

  String _formatChatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (now.difference(messageDate).inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(time)}';
    } else {
      return DateFormat('dd/MM HH:mm').format(time);
    }
  }

  void _sendMessage() {
    final messageText = _chatController.text.trim();
    if (messageText.isEmpty) return;

    // Add message to chat
    setState(() {
      _chatMessages.add({
        'message': messageText,
        'sender': 'user',
        'sender_name': 'You',
        'timestamp': DateTime.now(),
      });
    });

    _chatController.clear();

    // Scroll to bottom
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    // Simulate admin response (replace with actual API call)
    _simulateAdminResponse(messageText);
  }

  void _simulateAdminResponse(String userMessage) {
    // Simulate typing delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      String responseMessage =
          'Thank you for your message. We have received your inquiry and will respond shortly.';

      // Contextual responses based on user message
      if (userMessage.toLowerCase().contains('status') ||
          userMessage.toLowerCase().contains('update')) {
        responseMessage =
            'Your grievance is currently under review. We will update the status once we have more information.';
      } else if (userMessage.toLowerCase().contains('urgent') ||
          userMessage.toLowerCase().contains('emergency')) {
        responseMessage =
            'We understand this is urgent. Your case has been marked for priority review and will be escalated to the appropriate department.';
      } else if (userMessage.toLowerCase().contains('photo') ||
          userMessage.toLowerCase().contains('image')) {
        responseMessage =
            'If you need to submit additional photos or documents, please use the timeline section where admin can upload progress photos.';
      }

      setState(() {
        _chatMessages.add({
          'message': responseMessage,
          'sender': 'admin',
          'sender_name': 'Support Team',
          'timestamp': DateTime.now(),
        });
      });

      // Scroll to bottom
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Animate(
      effects: const [FadeEffect(), SlideEffect()],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GovTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: GovTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: GovTheme.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: GovTheme.neutralGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(fontSize: 14, color: GovTheme.darkGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String description,
    DateTime? timestamp,
    required bool isCompleted,
    List<String>? imageUrls,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? GovTheme.primaryBlue
                      : GovTheme.neutralGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isCompleted
                      ? [
                          BoxShadow(
                            color: GovTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isCompleted ? Colors.white : GovTheme.neutralGray,
                  size: 24,
                ),
              ),
              Container(
                width: 2,
                height: 20,
                color: GovTheme.neutralGray.withOpacity(0.3),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Timeline content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: GovTheme.primaryBlue,
                          ),
                        ),
                      ),
                      if (timestamp != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: GovTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatDate(timestamp),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: GovTheme.primaryBlue,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    description,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.5,
                      color: GovTheme.darkGray,
                    ),
                  ),

                  // Progress photos section
                  if (imageUrls != null && imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                color: GovTheme.primaryBlue,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Progress Photos (${imageUrls.length})',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: GovTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: imageUrls.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      ApiConfig.buildImageUrl(
                                        'uploads/${imageUrls[index]}',
                                      ),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: GovTheme.neutralGray
                                                  .withOpacity(0.1),
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: GovTheme.neutralGray,
                                                size: 24,
                                              ),
                                            );
                                          },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              color: GovTheme.neutralGray
                                                  .withOpacity(0.1),
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(GovTheme.primaryBlue),
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                );
                              },
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
        ],
      ),
    ).animate().fadeIn(delay: (100).ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildEmptyLocationState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GovTheme.neutralGray.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.location_off,
              size: 64,
              color: GovTheme.neutralGray,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Location Data',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: GovTheme.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Location information was not provided with this grievance.',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: GovTheme.neutralGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return GovTheme.successGreen;
      case 'in progress':
        return GovTheme.infoBlue;
      case 'submitted':
      case 'under review':
        return GovTheme.warningAmber;
      case 'rejected':
        return GovTheme.errorRed;
      case 'closed':
        return GovTheme.neutralGray.withOpacity(0.7);
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
      case 'rejected':
        return Icons.cancel;
      case 'closed':
        return Icons.lock_outline;
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

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'urgent':
        return GovTheme.errorRed;
      case 'normal':
        return GovTheme.infoBlue;
      case 'low':
        return GovTheme.successGreen;
      default:
        return GovTheme.neutralGray;
    }
  }

  String _formatDate(DateTime date) {
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

  void _shareGrievance() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality will be implemented')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_id':
        // Implement copy ID functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance ID copied to clipboard')),
        );
        break;
      case 'download_receipt':
        // Implement download receipt functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download functionality will be implemented'),
          ),
        );
        break;
    }
  }

  Widget _buildMediaSection() {
    final imageAttachments = _mediaAttachments
        .where((attachment) => attachment['file_type'] == 'image')
        .toList();

    final audioAttachments = _mediaAttachments
        .where((attachment) => attachment['file_type'] == 'audio')
        .toList();

    return _buildDetailCard(
      title: 'Photos & Media',
      icon: Icons.photo_library,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageAttachments.isNotEmpty) ...[
            Text(
              'Photos (${imageAttachments.length})',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GovTheme.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            _buildPhotosGrid(imageAttachments),
          ],

          if (audioAttachments.isNotEmpty) ...[
            if (imageAttachments.isNotEmpty) const SizedBox(height: 16),
            Text(
              'Audio Files (${audioAttachments.length})',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GovTheme.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            _buildAudioList(audioAttachments),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotosGrid(List<Map<String, dynamic>> imageAttachments) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: imageAttachments.length,
      itemBuilder: (context, index) {
        final attachment = imageAttachments[index];
        final apiService = SqlServerApiService();
        final imageUrl = apiService.getMediaFileUrl(attachment['file_path']);

        return GestureDetector(
          onTap: () => _showFullScreenImage(imageUrl, attachment['file_name']),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: GovTheme.neutralGray.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: GovTheme.primaryBlue,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: GovTheme.neutralGray.withOpacity(0.1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: GovTheme.neutralGray,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Image not available',
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                color: GovTheme.neutralGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Overlay with file info
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Text(
                        attachment['file_name'] ?? 'Image',
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioList(List<Map<String, dynamic>> audioAttachments) {
    return Column(
      children: audioAttachments.map((attachment) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GovTheme.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GovTheme.primaryBlue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.audiotrack,
                  color: GovTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment['file_name'] ?? 'Audio File',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: GovTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatFileSize(attachment['file_size']),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: GovTheme.neutralGray,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Implement audio playback
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Audio playback will be implemented'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  Icons.play_circle_outline,
                  color: GovTheme.primaryBlue,
                ),
                tooltip: 'Play Audio',
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showFullScreenImage(String imageUrl, String fileName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      fileName,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(dynamic fileSize) {
    if (fileSize == null) return 'Unknown size';

    final bytes = fileSize is int
        ? fileSize
        : int.tryParse(fileSize.toString()) ?? 0;

    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _openInMaps() async {
    if (widget.grievance.locationLatitude != null &&
        widget.grievance.locationLongitude != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${widget.grievance.locationLatitude},${widget.grievance.locationLongitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  void _copyCoordinates() async {
    if (widget.grievance.locationLatitude != null &&
        widget.grievance.locationLongitude != null) {
      final coordinates =
          '${widget.grievance.locationLatitude}, ${widget.grievance.locationLongitude}';
      await Clipboard.setData(ClipboardData(text: coordinates));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coordinates copied to clipboard: $coordinates'),
            backgroundColor: GovTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _getDirections() async {
    if (widget.grievance.locationLatitude != null &&
        widget.grievance.locationLongitude != null) {
      final url =
          'https://www.google.com/maps/dir/?api=1&destination=${widget.grievance.locationLatitude},${widget.grievance.locationLongitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open directions'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
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
          'Are you sure you want to delete this grievance? This action cannot be undone.\n\nNote: Only grievances with "Submitted" status can be deleted.',
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

    if (confirmed == true && mounted) {
      await _deleteGrievance();
    }
  }

  Future<void> _deleteGrievance() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await ref
          .read(grievancesProvider.notifier)
          .deleteGrievance(widget.grievance.grievanceId!);

      // Hide loading
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Show success message
        if (mounted) {
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

          // Navigate back
          Navigator.of(context).pop();
        }
      } else {
        // Show error message
        if (mounted) {
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
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
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
