import 'package:flutter/material.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Covers A1 — typed variables
  UserType _selectedUserType = UserType.homeowner;
  String _selectedDistrict = 'gasabo';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Covers A3 — Map
  final Map<String, String> _districts = {
    'gasabo': 'Gasabo District',
    'kicukiro': 'Kicukiro District',
    'nyarugenge': 'Nyarugenge District',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Covers B5 — async/await
  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isLoading = false);

      if (mounted) {
        // Covers A4 — if/else control flow
        if (_selectedUserType == UserType.homeowner) {
          // Create homeowner session
          final homeowner = Homeowner(
            id: 'h${DateTime.now().millisecondsSinceEpoch}',
            name: _nameController.text.trim(),
            phoneNumber: '+250${_phoneController.text.trim()}',
            location: _districts[_selectedDistrict]!,
            email: _emailController.text.trim(),
            district: _selectedDistrict,
            joinedAt: DateTime.now(),
          );
          UserSession.loginAsHomeowner(homeowner);
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Navigate to artisan profile setup
          Navigator.pushReplacementNamed(
            context,
            '/artisan-setup',
            arguments: {
              'name': _nameController.text.trim(),
              'phone': '+250${_phoneController.text.trim()}',
              'email': _emailController.text.trim(),
              'district': _selectedDistrict,
            },
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User type selector
              const Text(
                'I am a...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Homeowner option
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _selectedUserType = UserType.homeowner),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedUserType == UserType.homeowner
                              ? AppTheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                _selectedUserType == UserType.homeowner
                                    ? AppTheme.primary
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '🏠',
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Homeowner',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color:
                                    _selectedUserType == UserType.homeowner
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'I need services',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    _selectedUserType == UserType.homeowner
                                        ? Colors.white70
                                        : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Artisan option
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _selectedUserType = UserType.artisan),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedUserType == UserType.artisan
                              ? AppTheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedUserType == UserType.artisan
                                ? AppTheme.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '🔧',
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Artisan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color:
                                    _selectedUserType == UserType.artisan
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'I offer services',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    _selectedUserType == UserType.artisan
                                        ? Colors.white70
                                        : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Full name
              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Jean Pierre Habimana',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email
              _buildLabel('Email Address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'e.g. jean@gmail.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone number
              _buildLabel('Phone Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'e.g. 781234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                  prefixText: '+250 ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  // Covers D4 — pattern check
                  final phoneRegex = RegExp(r'^[0-9]{9}$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Phone number must be 9 digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // District
              _buildLabel('District'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: _districts.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedDistrict = value!),
                validator: (value) =>
                    value == null ? 'Please select your district' : null,
              ),

              const SizedBox(height: 16),

              // Password
              _buildLabel('Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'At least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
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
              ),

              const SizedBox(height: 16),

              // Confirm password
              _buildLabel('Confirm Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword =
                            !_obscureConfirmPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  // Covers D4 — match check
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Signup button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signup,
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              const SizedBox(height: 16),

              // Login redirect
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      );
}