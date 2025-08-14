import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/gov_theme.dart';
import '../../models/grievance_new.dart';
import '../../services/sql_server_api_service.dart';

class AdminGrievanceUpdateScreen extends ConsumerStatefulWidget {
  final Grievance grievance;

  const AdminGrievanceUpdateScreen({super.key, required this.grievance});

  @override
  ConsumerState<AdminGrievanceUpdateScreen> createState() =>
      _AdminGrievanceUpdateScreenState();
}

class _AdminGrievanceUpdateScreenState
    extends ConsumerState<AdminGrievanceUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  String _selectedStatus = 'Under Review';
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'Under Review',
    'In Progress',
    'Resolved',
    'Rejected',
    'On Hold',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.grievance.status;
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        if (_selectedImages.length + images.length > 5) {
          _showErrorSnackBar('You can select maximum 5 images total');
          return;
        }

        // Show loading while processing images
        setState(() {
          _isLoading = true;
        });

        List<File> newImages = [];
        for (XFile xfile in images) {
          File imageFile = File(xfile.path);

          // Check file size (max 5MB per image)
          int fileSizeBytes = await imageFile.length();
          double fileSizeMB = fileSizeBytes / (1024 * 1024);

          if (fileSizeMB > 5.0) {
            _showErrorSnackBar(
              'Image ${xfile.name} is too large. Max size is 5MB',
            );
            continue;
          }

          newImages.add(imageFile);
        }

        setState(() {
          _selectedImages.addAll(newImages);
          _isLoading = false;
        });

        if (newImages.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newImages.length} image(s) added successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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

  void _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_commentsController.text.trim().isEmpty) {
      _showErrorSnackBar('Please add update comments');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = SqlServerApiService();
      final imagePaths = _selectedImages.map((file) => file.path).toList();

      // Call API to update grievance with images
      await apiService.updateGrievanceWithImages(
        widget.grievance.grievanceId ?? 0,
        _selectedStatus,
        _commentsController.text.trim(),
        imagePaths,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Grievance updated successfully with ${_selectedImages.length} images!',
                ),
              ],
            ),
            backgroundColor: GovTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to update grievance: $e');
      }
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Update Grievance',
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grievance Info Card
              _buildGrievanceInfoCard(),

              const SizedBox(height: 20),

              // Status Update Card
              _buildStatusUpdateCard(),

              const SizedBox(height: 20),

              // Progress Images Card
              _buildProgressImagesCard(),

              const SizedBox(height: 20),

              // Comments Card
              _buildCommentsCard(),

              const SizedBox(height: 30),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrievanceInfoCard() {
    return Container(
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: GovTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Grievance Information',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GovTheme.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            widget.grievance.title,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ],
      ),
    );
  }

  Widget _buildStatusUpdateCard() {
    return Container(
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.update,
                  color: GovTheme.successGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Status Update',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GovTheme.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Current Status: ${widget.grievance.status}',
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'New Status',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: GovTheme.primaryBlue, width: 2),
              ),
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(status),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStatus = value;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a status';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressImagesCard() {
    return Container(
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovTheme.warningAmber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: GovTheme.warningAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Progress Images',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GovTheme.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Add photos to show the current progress (Optional)',
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Image Upload Button
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _pickImages,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate),
            label: Text(
              _isLoading
                  ? 'Processing images...'
                  : _selectedImages.isEmpty
                  ? 'Add Progress Photos (Max 5)'
                  : '${_selectedImages.length} Photo(s) Selected - Add More',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isLoading ? Colors.grey : GovTheme.primaryBlue,
              side: BorderSide(
                color: _isLoading ? Colors.grey : GovTheme.primaryBlue,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          // File size info
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Supported formats: JPG, PNG • Max size: 5MB per image • Max ${5 - _selectedImages.length} more images',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // Selected Images Preview
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 120,
                    height: 120,
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
                            width: 120,
                            height: 120,
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
                              width: 28,
                              height: 28,
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
        ],
      ),
    );
  }

  Widget _buildCommentsCard() {
    return Container(
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovTheme.infoBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.comment, color: GovTheme.infoBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Update Comments',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GovTheme.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _commentsController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  'Enter detailed comments about the status update, actions taken, or next steps...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: GovTheme.primaryBlue, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter update comments';
              }
              if (value.trim().length < 10) {
                return 'Comments must be at least 10 characters long';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor: GovTheme.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Updating Grievance...',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Update Grievance',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
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
      case 'on hold':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
