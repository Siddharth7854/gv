import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../core/theme/gov_theme.dart';
import '../../models/grievance_new.dart';

class EnhancedGrievanceTrackingScreen extends ConsumerStatefulWidget {
  final Grievance grievance;

  const EnhancedGrievanceTrackingScreen({super.key, required this.grievance});

  @override
  ConsumerState<EnhancedGrievanceTrackingScreen> createState() =>
      _EnhancedGrievanceTrackingScreenState();
}

class _EnhancedGrievanceTrackingScreenState
    extends ConsumerState<EnhancedGrievanceTrackingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  List<File> _selectedImages = [];
  final TextEditingController _updateCommentController =
      TextEditingController();

  // Amazon-style tracking steps
  final List<Map<String, dynamic>> _trackingSteps = [
    {
      'title': 'Submitted',
      'description': 'Your grievance has been received',
      'icon': Icons.send_outlined,
      'completedIcon': Icons.send,
      'status': 'completed',
      'date': null,
    },
    {
      'title': 'Under Review',
      'description': 'Department is reviewing your complaint',
      'icon': Icons.visibility_outlined,
      'completedIcon': Icons.visibility,
      'status': 'completed',
      'date': null,
    },
    {
      'title': 'In Progress',
      'description': 'Work has started on your grievance',
      'icon': Icons.engineering_outlined,
      'completedIcon': Icons.engineering,
      'status': 'current',
      'date': null,
    },
    {
      'title': 'Resolved',
      'description': 'Your grievance has been resolved',
      'icon': Icons.check_circle_outline,
      'completedIcon': Icons.check_circle,
      'status': 'pending',
      'date': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateTrackingStatus();
  }

  void _updateTrackingStatus() {
    // Update tracking based on current grievance status
    final currentStatus = widget.grievance.status.toLowerCase();

    for (int i = 0; i < _trackingSteps.length; i++) {
      final step = _trackingSteps[i];
      final stepTitle = step['title'].toString().toLowerCase();

      if (stepTitle == currentStatus) {
        _currentStep = i;
        // Mark all previous steps as completed
        for (int j = 0; j <= i; j++) {
          _trackingSteps[j]['status'] = 'completed';
        }
        // Mark current step
        if (i < _trackingSteps.length) {
          _trackingSteps[i]['status'] = 'current';
        }
        // Mark remaining as pending
        for (int k = i + 1; k < _trackingSteps.length; k++) {
          _trackingSteps[k]['status'] = 'pending';
        }
        break;
      }
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty && images.length <= 5) {
        setState(() {
          _selectedImages = images.map((xfile) => File(xfile.path)).toList();
        });
      } else if (images.length > 5) {
        _showErrorSnackBar('You can select maximum 5 images');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick images: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: GovTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitUpdate() {
    if (_updateCommentController.text.trim().isEmpty &&
        _selectedImages.isEmpty) {
      _showErrorSnackBar('Please add a comment or select images');
      return;
    }

    // TODO: Implement API call to submit update with images
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Update submitted successfully!'),
        backgroundColor: GovTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Clear form
    setState(() {
      _selectedImages.clear();
      _updateCommentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Track Grievance',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: GovTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Grievance Header Card
            _buildGrievanceHeader(),

            // Amazon-style Progress Tracker
            _buildProgressTracker(),

            // Update Section
            _buildUpdateSection(),

            // Timeline History
            _buildTimelineHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrievanceHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: GovTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.grievance.grievanceNumber ?? 'N/A',
                  style: GoogleFonts.roboto(
                    color: GovTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    widget.grievance.status,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.grievance.status,
                  style: GoogleFonts.roboto(
                    color: _getStatusColor(widget.grievance.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.grievance.title,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GovTheme.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.grievance.description,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Submitted: ${DateFormat('dd MMM yyyy').format(widget.grievance.submittedAt)}',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildProgressTracker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Tracking',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GovTheme.darkGray,
            ),
          ),
          const SizedBox(height: 20),

          // Amazon-style horizontal progress bar
          Row(
            children: [
              for (int i = 0; i < _trackingSteps.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      // Step circle
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getStepColor(_trackingSteps[i]['status']),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getStepBorderColor(
                              _trackingSteps[i]['status'],
                            ),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _trackingSteps[i]['status'] == 'completed'
                              ? _trackingSteps[i]['completedIcon']
                              : _trackingSteps[i]['icon'],
                          color: _getStepIconColor(_trackingSteps[i]['status']),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _trackingSteps[i]['title'],
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _trackingSteps[i]['status'] == 'pending'
                              ? Colors.grey[400]
                              : GovTheme.darkGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _trackingSteps[i]['description'],
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (i < _trackingSteps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 60),
                      decoration: BoxDecoration(
                        color: i < _currentStep
                            ? GovTheme.successGreen
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildUpdateSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Progress Update',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GovTheme.darkGray,
            ),
          ),
          const SizedBox(height: 16),

          // Comment Field
          TextFormField(
            controller: _updateCommentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your feedback or ask for updates...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: GovTheme.primaryBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Image Upload Section
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    _selectedImages.isEmpty
                        ? 'Add Photos (Max 5)'
                        : '${_selectedImages.length} Photo(s) Selected',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GovTheme.primaryBlue,
                    side: BorderSide(color: GovTheme.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          // Selected Images Preview
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.file(
                            _selectedImages[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
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
          ],

          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: GovTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit Update',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildTimelineHistory() {
    // Mock timeline data - replace with real data
    final List<Map<String, dynamic>> timeline = [
      {
        'title': 'Grievance Submitted',
        'description':
            'Your grievance has been successfully submitted to the department.',
        'date': widget.grievance.submittedAt,
        'status': 'completed',
        'images': [],
      },
      {
        'title': 'Under Review',
        'description':
            'Department officer has started reviewing your complaint.',
        'date': widget.grievance.submittedAt.add(const Duration(hours: 2)),
        'status': 'completed',
        'images': [],
      },
      {
        'title': 'Investigation Started',
        'description': 'Field officer assigned for investigation.',
        'date': widget.grievance.submittedAt.add(const Duration(days: 1)),
        'status': 'current',
        'images': ['https://via.placeholder.com/300x200'],
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline History',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GovTheme.darkGray,
            ),
          ),
          const SizedBox(height: 20),

          ...timeline.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == timeline.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item['status'] == 'completed'
                            ? GovTheme.successGreen
                            : item['status'] == 'current'
                            ? GovTheme.primaryBlue
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Container(width: 2, height: 60, color: Colors.grey[300]),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: GovTheme.darkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['description'],
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(item['date']),
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (item['images'] != null &&
                          item['images'].isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: item['images'].length,
                            itemBuilder: (context, imgIndex) {
                              return Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.network(
                                    item['images'][imgIndex],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return GovTheme.infoBlue;
      case 'under review':
        return GovTheme.warningAmber;
      case 'in progress':
        return GovTheme.primaryBlue;
      case 'resolved':
        return GovTheme.successGreen;
      case 'rejected':
        return GovTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  Color _getStepColor(String status) {
    switch (status) {
      case 'completed':
        return GovTheme.successGreen;
      case 'current':
        return GovTheme.primaryBlue;
      default:
        return Colors.white;
    }
  }

  Color _getStepBorderColor(String status) {
    switch (status) {
      case 'completed':
        return GovTheme.successGreen;
      case 'current':
        return GovTheme.primaryBlue;
      default:
        return Colors.grey[300]!;
    }
  }

  Color _getStepIconColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.white;
      case 'current':
        return Colors.white;
      default:
        return Colors.grey[400]!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _updateCommentController.dispose();
    super.dispose();
  }
}
