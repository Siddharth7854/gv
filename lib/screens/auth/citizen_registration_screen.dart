import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/gov_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

class CitizenRegistrationScreen extends ConsumerStatefulWidget {
  const CitizenRegistrationScreen({super.key});

  @override
  ConsumerState<CitizenRegistrationScreen> createState() =>
      _CitizenRegistrationScreenState();
}

class _CitizenRegistrationScreenState
    extends ConsumerState<CitizenRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aadharController = TextEditingController();
  final _districtController = TextEditingController();
  final _blockController = TextEditingController();
  final _wardController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aadharController.dispose();
    _districtController.dispose();
    _blockController.dispose();
    _wardController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authProvider.notifier)
          .register(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? '${_phoneController.text.trim()}@citizen.gov.in'
                : _emailController.text.trim(),
            password: _passwordController.text,
            phone: _phoneController.text.trim(),
            aadharNumber: _aadharController.text.trim(),
            district: _districtController.text.trim(),
            block: _blockController.text.trim(),
            ward: _wardController.text.trim(),
            address: _addressController.text.trim(),
            pincode: _pincodeController.text.trim(),
          );

      if (mounted) {
        final authState = ref.read(authProvider);
        if (authState is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${authState.message}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registration successful! Please login with your mobile number.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Citizen Registration',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: GovTheme.headerGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.how_to_reg, size: 60, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        'Register as Citizen',
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Submit your grievances and track their status',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0),

                const SizedBox(height: 32),

                // Personal Information Section
                Text(
                  'Personal Information',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 16),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 16),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your mobile number';
                    }
                    if (value.length != 10) {
                      return 'Please enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 16),

                // Aadhar Number
                TextFormField(
                  controller: _aadharController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Aadhar Number *',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your Aadhar number';
                    }
                    if (value.length != 12) {
                      return 'Please enter a valid 12-digit Aadhar number';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 24),

                // Address Information Section
                Text(
                  'Address Information',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ).animate().fadeIn(delay: 800.ms),

                const SizedBox(height: 16),

                // District
                TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: 'District *',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your district';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 900.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 16),

                // Block/Tehsil
                TextFormField(
                  controller: _blockController,
                  decoration: const InputDecoration(
                    labelText: 'Block/Tehsil *',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your block/tehsil';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 16),

                // Ward/Village
                TextFormField(
                  controller: _wardController,
                  decoration: const InputDecoration(
                    labelText: 'Ward/Village *',
                    prefixIcon: Icon(Icons.home_work),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your ward/village';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 1100.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 16),

                // Full Address
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Full Address *',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full address';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 1200.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 16),

                // Pincode
                TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pincode *',
                    prefixIcon: Icon(Icons.pin_drop),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your pincode';
                    }
                    if (value.length != 6) {
                      return 'Please enter a valid 6-digit pincode';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 1300.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 24),

                // Account Information Section
                Text(
                  'Account Information',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ).animate().fadeIn(delay: 1400.ms),

                const SizedBox(height: 16),

                // Email (Optional)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 1500.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 1600.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 1700.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 32),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleRegistration,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Register as Citizen',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 1800.ms).slideY(begin: 0.3, end: 0),

                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Login',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1900.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
