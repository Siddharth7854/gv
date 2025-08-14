import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/gov_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/grievances_provider.dart';
import '../../services/local_storage_service.dart';

class NewGrievanceScreen extends ConsumerStatefulWidget {
  const NewGrievanceScreen({super.key});

  @override
  ConsumerState<NewGrievanceScreen> createState() => _NewGrievanceScreenState();
}

class _NewGrievanceScreenState extends ConsumerState<NewGrievanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  // Media & Location
  final List<XFile> _selectedImages = [];
  final List<String> _audioRecordings = [];
  String? _currentLocation;
  Position? _userPosition;
  bool _isRecording = false;

  String? _selectedCategory;
  String? _selectedPriority = 'Medium';
  String? _selectedUrgency = 'Normal';

  final List<String> _categories = [
    'Water Supply',
    'Electricity',
    'Roads & Transportation',
    'Sanitation',
    'Healthcare',
    'Education',
    'Police & Law',
    'Municipal Services',
    'Agricultural Issues',
    'Environmental Issues',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Location Services
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _userPosition = position;
          _currentLocation =
              'Lat: ${position.latitude.toStringAsFixed(6)}, '
              'Long: ${position.longitude.toStringAsFixed(6)}';
          _locationController.text = _currentLocation ?? '';
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Image Picker
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1920,
                  maxHeight: 1080,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    _selectedImages.add(image);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final List<XFile> images = await picker.pickMultiImage(
                  maxWidth: 1920,
                  maxHeight: 1080,
                  imageQuality: 85,
                );
                if (images.isNotEmpty) {
                  setState(() {
                    _selectedImages.addAll(images);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Audio Recording (Placeholder)
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      setState(() {
        _audioRecordings.add(
          'audio_${DateTime.now().millisecondsSinceEpoch}.wav',
        );
        _isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio recording stopped'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Start recording
      final permission = await Permission.microphone.request();
      if (permission.isGranted) {
        setState(() {
          _isRecording = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio recording started'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submit New Grievance',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: GovTheme.headerGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.report_problem,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Submit Your Grievance',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide detailed information to help us resolve your issue quickly',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Basic Information Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Grievance Title *',
                        hintText: 'Brief description of your issue',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title for your grievance';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Detailed Description *',
                        hintText:
                            'Provide complete details about your grievance...',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please provide a detailed description';
                        }
                        if (value.length < 20) {
                          return 'Description should be at least 20 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Category & Priority Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category & Priority',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Priority
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              prefixIcon: const Icon(Icons.priority_high),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: ['Low', 'Medium', 'High', 'Critical'].map((
                              priority,
                            ) {
                              return DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPriority = value;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Urgency
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedUrgency,
                            decoration: InputDecoration(
                              labelText: 'Urgency',
                              prefixIcon: const Icon(Icons.timer),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: ['Normal', 'Urgent', 'Emergency'].map((
                              urgency,
                            ) {
                              return DropdownMenuItem(
                                value: urgency,
                                child: Text(urgency),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUrgency = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Location Information Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                        Text(
                          'Location Information',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _getCurrentLocation,
                          tooltip: 'Refresh Location',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Current Location
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Current Location',
                        hintText: 'GPS coordinates will appear here',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _getCurrentLocation,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      readOnly: true,
                    ),

                    if (_userPosition != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Location captured successfully',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Media Attachments Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evidence & Media',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add photos and audio recordings to support your grievance',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Media Upload Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add_a_photo),
                            label: Text(
                              'Add Photos (${_selectedImages.length})',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _toggleRecording,
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(_isRecording ? 'Stop' : 'Record'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.red : null,
                            foregroundColor: _isRecording ? Colors.white : null,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Images Preview
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Selected Images:',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb
                                        ? Image.network(
                                            _selectedImages[index].path,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                          )
                                        : FutureBuilder<Uint8List>(
                                            future: _selectedImages[index]
                                                .readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Image.memory(
                                                  snapshot.data!,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                );
                                              } else {
                                                return Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey[300],
                                                  child:
                                                      const CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                );
                                              }
                                            },
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
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
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

                    // Audio Recordings
                    if (_audioRecordings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Audio Recordings:',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_audioRecordings.length, (index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.audiotrack, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Audio Recording ${index + 1}',
                                  style: GoogleFonts.roboto(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _audioRecordings.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // Recording indicator
                    if (_isRecording) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Recording in progress...',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitGrievance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Submit Grievance',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _submitGrievance() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Get current user
        final user = ref.read(simpleCurrentUserProvider);
        if (user == null) {
          throw Exception('User not found. Please login again.');
        }

        // Prepare image paths (simplified for now)
        List<String>? imagePaths;
        if (_selectedImages.isNotEmpty) {
          imagePaths = _selectedImages.map((image) => image.path).toList();
        }

        // Prepare audio paths
        List<String>? audioPaths;
        if (_audioRecordings.isNotEmpty) {
          audioPaths = _audioRecordings;
        }

        // Get API service and set auth token
        final apiService = ref.read(sqlServerApiServiceProvider);

        // Get auth token from storage and set it
        final authState = ref.read(simpleAuthProvider);
        if (authState.isAuthenticated) {
          // Try to get token from localStorage - use direct service since no provider defined
          final localStorage = LocalStorageService();
          final token = await localStorage.getToken();
          if (token != null) {
            apiService.setAuthToken(token);
          }
        }

        // Submit grievance
        final result = await apiService.submitGrievance({
          'citizen_id': int.parse(user.userId),
          'category_id': _getCategoryId(_selectedCategory!),
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'priority': _selectedPriority!,
          'urgency': _selectedUrgency!,
          'location_latitude': _userPosition?.latitude,
          'location_longitude': _userPosition?.longitude,
          'location_address': _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : _currentLocation,
          'image_paths': imagePaths,
          'audio_paths': audioPaths,
        });

        // Close loading dialog
        Navigator.of(context).pop();

        // Refresh grievances list
        ref.read(grievancesProvider.notifier).refreshGrievances();

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Success!',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your grievance has been submitted successfully.',
                  style: GoogleFonts.roboto(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grievance ID: ${result['grievance_id'] ?? 'GRV${DateTime.now().millisecondsSinceEpoch}'}',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Expected Resolution: 7-15 working days',
                        style: GoogleFonts.roboto(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (error) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Error',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              'Failed to submit grievance: ${error.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.roboto(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  int _getCategoryId(String categoryName) {
    // Map category names to IDs (you may need to adjust these based on your database)
    const categoryMap = {
      'Water Supply': 1,
      'Electricity': 2,
      'Roads & Transportation': 3,
      'Sanitation': 4,
      'Healthcare': 5,
      'Education': 6,
      'Police & Law': 7,
      'Municipal Services': 8,
      'Agricultural Issues': 9,
      'Environmental Issues': 10,
      'Other': 11,
    };
    return categoryMap[categoryName] ?? 11; // Default to 'Other'
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Help & Guidelines',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tips for submitting effective grievances:',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              _buildHelpPoint('Be specific and clear in your description'),
              _buildHelpPoint('Select the most appropriate category'),
              _buildHelpPoint('Set priority based on urgency level'),
              _buildHelpPoint(
                'Provide complete details to help quick resolution',
              ),
              const SizedBox(height: 16),
              Text(
                'Expected Response Times:',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildHelpPoint('Emergency: 24 hours'),
              _buildHelpPoint('High Priority: 3-5 days'),
              _buildHelpPoint('Normal: 7-15 days'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(child: Text(text, style: GoogleFonts.roboto(fontSize: 14))),
        ],
      ),
    );
  }
}
