import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/gov_theme.dart';

class AdminGrievanceTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> statusHistory;
  final DateTime submittedAt;

  const AdminGrievanceTimeline({
    super.key,
    required this.statusHistory,
    required this.submittedAt,
  });

  @override
  Widget build(BuildContext context) {
    // Sort status history by changed_at ascending for correct timeline order
    final sortedHistory = List<Map<String, dynamic>>.from(statusHistory);
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
                      'changed_at': submittedAt.toIso8601String(),
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
                ),
              );
            })
            .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grievance Timeline',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...timelineItems,
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? GovTheme.successGreen
                  : GovTheme.neutralGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : GovTheme.neutralGray,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? GovTheme.darkGray
                        : GovTheme.neutralGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: GovTheme.neutralGray,
                    height: 1.4,
                  ),
                ),
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
