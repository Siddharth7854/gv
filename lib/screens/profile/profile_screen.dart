import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/gov_theme.dart';
import '../../providers/simple_auth_provider.dart';
import '../../core/config/api_config.dart';
import '../settings/notification_settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  File? _selectedImage;
  Uint8List? _webImage; // For web compatibility
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(simpleCurrentUserProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Helper method to display image based on platform
  Widget _buildProfileImage() {
    if (kIsWeb && _webImage != null) {
      return Image.memory(_webImage!, fit: BoxFit.cover);
    } else if (!kIsWeb && _selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    } else {
      final user = ref.watch(simpleCurrentUserProvider);
      if (user?.photoUrl != null) {
        // Build full URL for server images
        String imageUrl = user!.photoUrl!;
        if (!imageUrl.startsWith('http')) {
          imageUrl = ApiConfig.buildImageUrl(imageUrl);
        }

        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: GovTheme.lightGray,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: GovTheme.lightBlue,
            child: Icon(Icons.person, size: 80, color: GovTheme.primaryBlue),
          ),
        );
      } else {
        return Container(
          color: GovTheme.lightBlue,
          child: Icon(Icons.person, size: 80, color: GovTheme.primaryBlue),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(simpleCurrentUserProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () async {
              if (_isEditing) {
                if (_formKey.currentState!.validate()) {
                  await _updateProfile();
                }
              }
              setState(() {
                _isEditing = !_isEditing;
              });
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
          children: [
            // Profile Header Card
            _buildProfileHeader(context, user),

            const SizedBox(height: 24),

            // Profile Information Form
            _buildProfileForm(context, user),

            const SizedBox(height: 24),

            // Account Actions
            _buildAccountActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Animate(
      effects: const [FadeEffect(), ScaleEffect()],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: GovTheme.cardShadow,
        ),
        child: Column(
          children: [
            // Profile Picture
            GestureDetector(
              onTap: () => _showProfilePhotoDialog(context, user),
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: GovTheme.primaryBlue, width: 3),
                    ),
                    child: ClipOval(child: _buildProfileImage()),
                  ),
                  // Camera icon overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: GovTheme.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // User Name
            Text(
              user?.fullName ?? 'Employee Name',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GovTheme.darkGray,
              ),
            ),

            const SizedBox(height: 4),

            // User Role
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GovTheme.lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.role ?? 'Employee',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GovTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, user) {
    return Animate(
      effects: const [FadeEffect(), SlideEffect()],
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: GovTheme.cardShadow,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GovTheme.darkGray,
                ),
              ),

              const SizedBox(height: 20),

              // Full Name
              TextFormField(
                controller: _nameController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                enabled: false, // Email should not be editable
                decoration: InputDecoration(
                  labelText: 'Government Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: const Icon(Icons.lock_outline, size: 16),
                ),
              ),

              const SizedBox(height: 20),

              // Block
              TextFormField(
                initialValue: user?.block ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Block',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // District
              TextFormField(
                initialValue: user?.district ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'District',
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Ward
              TextFormField(
                initialValue: user?.ward ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Ward',
                  prefixIcon: const Icon(Icons.home_work_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Address
              TextFormField(
                initialValue: user?.address ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Pincode
              TextFormField(
                initialValue: user?.pincode ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Pincode',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_isEditing) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _updateProfile(),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Animate(
      effects: const [FadeEffect(), SlideEffect()],
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: GovTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Actions',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GovTheme.darkGray,
              ),
            ),

            const SizedBox(height: 16),

            // Change Password
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovTheme.infoBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: GovTheme.infoBlue,
                  size: 20,
                ),
              ),
              title: Text(
                'Change Password',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Update your account password',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: GovTheme.neutralGray,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showChangePasswordDialog(context),
            ),

            const Divider(),

            // Privacy Settings
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.privacy_tip_outlined,
                  color: GovTheme.successGreen,
                  size: 20,
                ),
              ),
              title: Text(
                'Privacy Settings',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Manage your privacy preferences',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: GovTheme.neutralGray,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showPrivacySettingsDialog(context),
            ),

            const Divider(),

            // Notification Settings
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: GovTheme.primaryBlue,
                  size: 20,
                ),
              ),
              title: Text(
                'Notification Settings',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Manage push notifications and FCM token',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: GovTheme.neutralGray,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                print('📱 [DEBUG] Navigating to Notification Settings');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            // Logout
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GovTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout, color: GovTheme.errorRed, size: 20),
              ),
              title: Text(
                'Logout',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: GovTheme.errorRed,
                ),
              ),
              subtitle: Text(
                'Sign out of your account',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: GovTheme.neutralGray,
                ),
              ),
              onTap: () {
                print('🚪 [DEBUG] Logout button tapped in profile menu');
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    // TODO: Implement profile update API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: GovTheme.successGreen,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Change Password',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: GovTheme.darkGray,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current Password
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      style: GoogleFonts.roboto(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // New Password
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      style: GoogleFonts.roboto(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock_reset),
                      ),
                      style: GoogleFonts.roboto(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.roboto(color: GovTheme.neutralGray),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                            });

                            try {
                              final user = ref.read(simpleCurrentUserProvider);
                              if (user == null) {
                                throw Exception('User not found');
                              }
                              final apiService = ref.read(
                                simpleSqlServerApiServiceProvider,
                              );
                              await apiService.changePassword(
                                int.parse(user.userId),
                                currentPasswordController.text,
                                newPasswordController.text,
                              );

                              Navigator.of(context).pop();
                              _showSuccessMessage(
                                'Password changed successfully',
                              );
                            } catch (e) {
                              _showErrorMessage(
                                e.toString().replaceFirst('Exception: ', ''),
                              );
                            } finally {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text('Change Password', style: GoogleFonts.roboto()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPrivacySettingsDialog(BuildContext context) {
    bool emailNotifications = true;
    bool smsNotifications = false;
    bool profileVisibility = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Privacy Settings',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: GovTheme.darkGray,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Email Notifications
                  ListTile(
                    leading: Icon(
                      Icons.email_outlined,
                      color: GovTheme.primaryBlue,
                    ),
                    title: Text(
                      'Email Notifications',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Receive updates via email',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: GovTheme.neutralGray,
                      ),
                    ),
                    trailing: Switch(
                      value: emailNotifications,
                      onChanged: (value) {
                        setState(() {
                          emailNotifications = value;
                        });
                      },
                      activeColor: GovTheme.primaryBlue,
                    ),
                  ),

                  // SMS Notifications
                  ListTile(
                    leading: Icon(
                      Icons.sms_outlined,
                      color: GovTheme.primaryBlue,
                    ),
                    title: Text(
                      'SMS Notifications',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Receive updates via SMS',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: GovTheme.neutralGray,
                      ),
                    ),
                    trailing: Switch(
                      value: smsNotifications,
                      onChanged: (value) {
                        setState(() {
                          smsNotifications = value;
                        });
                      },
                      activeColor: GovTheme.primaryBlue,
                    ),
                  ),

                  // Profile Visibility
                  ListTile(
                    leading: Icon(
                      Icons.visibility_outlined,
                      color: GovTheme.primaryBlue,
                    ),
                    title: Text(
                      'Profile Visibility',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Make profile visible to officials',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: GovTheme.neutralGray,
                      ),
                    ),
                    trailing: Switch(
                      value: profileVisibility,
                      onChanged: (value) {
                        setState(() {
                          profileVisibility = value;
                        });
                      },
                      activeColor: GovTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.roboto(color: GovTheme.neutralGray),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSuccessMessage(
                      'Privacy settings updated successfully',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GovTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Save Settings', style: GoogleFonts.roboto()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    print('🚪 [DEBUG] _showLogoutDialog called');
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                print('🚪 [DEBUG] Logout button pressed in dialog');
                Navigator.of(context).pop();
                print('🚪 [DEBUG] Dialog closed, calling logout...');
                ref.read(simpleAuthProvider.notifier).logout();
                print('🚪 [DEBUG] Logout method called');
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

  // Profile Photo Methods
  void _showProfilePhotoDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Photo Display
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: GovTheme.primaryBlue, width: 3),
                  ),
                  child: ClipOval(child: _buildProfileImage()),
                ),

                const SizedBox(height: 24),

                // User Name
                Text(
                  user?.fullName ?? 'Employee Name',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GovTheme.darkGray,
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Take Photo
                    _buildPhotoActionButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),

                    // Choose from Gallery
                    _buildPhotoActionButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
                      },
                    ),

                    // Remove Photo (only show if there's a photo)
                    if (_selectedImage != null ||
                        _webImage != null ||
                        user?.photoUrl != null)
                      _buildPhotoActionButton(
                        icon: Icons.delete,
                        label: 'Remove',
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          _removeProfilePhoto();
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Close Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: GovTheme.neutralGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDestructive
                  ? GovTheme.errorRed.withOpacity(0.1)
                  : GovTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive ? GovTheme.errorRed : GovTheme.primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDestructive ? GovTheme.errorRed : GovTheme.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _webImage = null;
          });
        }

        // Upload to server
        await _uploadProfilePhotoToServer(pickedFile);
      }
    } catch (e) {
      _showErrorMessage('Failed to take photo: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _webImage = null;
          });
        }

        // Upload to server
        await _uploadProfilePhotoToServer(pickedFile);
      }
    } catch (e) {
      _showErrorMessage('Failed to pick photo: ${e.toString()}');
    }
  }

  Future<void> _uploadProfilePhotoToServer(XFile imageFile) async {
    try {
      // Show loading
      _showLoadingMessage('Uploading profile photo...');

      final user = ref.read(simpleCurrentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final apiService = ref.read(simpleSqlServerApiServiceProvider);

      final response = await apiService.uploadProfilePhoto(
        int.parse(user.userId),
        imageFile.path,
      );

      // Update user in auth provider
      final updatedUser = user.copyWith(photoUrl: response['photoUrl']);
      await ref.read(simpleAuthProvider.notifier).updateUser(updatedUser);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSuccessMessage('Profile photo updated successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorMessage('Failed to upload photo: ${e.toString()}');

      // Reset local image on error
      setState(() {
        _selectedImage = null;
        _webImage = null;
      });
    }
  }

  void _removeProfilePhoto() async {
    try {
      // Show loading
      _showLoadingMessage('Removing profile photo...');

      final user = ref.read(simpleCurrentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final apiService = ref.read(simpleSqlServerApiServiceProvider);
      await apiService.removeProfilePhoto(int.parse(user.userId));

      // Update user in auth provider
      final updatedUser = user.copyWith(photoUrl: null);
      await ref.read(simpleAuthProvider.notifier).updateUser(updatedUser);

      setState(() {
        _selectedImage = null;
        _webImage = null;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSuccessMessage('Profile photo removed successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorMessage('Failed to remove photo: ${e.toString()}');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.roboto(color: Colors.white)),
        backgroundColor: GovTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.roboto(color: Colors.white)),
        backgroundColor: GovTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLoadingMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.roboto(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: GovTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(minutes: 1), // Long duration for loading
      ),
    );
  }
}
