import 'package:flutter/material.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';

class HomeownerEditProfileScreen extends StatefulWidget {
  const HomeownerEditProfileScreen({super.key});

  @override
  State<HomeownerEditProfileScreen> createState() =>
      _HomeownerEditProfileScreenState();
}

class _HomeownerEditProfileScreenState
    extends State<HomeownerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedDistrict;
  bool _isLoading = false;

  final Map<String, String> _districtLabels = {
    'gasabo': 'Gasabo, Kigali',
    'kicukiro': 'Kicukiro, Kigali',
    'nyarugenge': 'Nyarugenge, Kigali',
  };

  @override
  void initState() {
    super.initState();
    final h = UserSession.currentHomeowner;
    _nameController = TextEditingController(text: h?.name ?? '');
    _phoneController = TextEditingController(text: h?.phoneNumber ?? '');
    _selectedDistrict = h?.district ?? 'gasabo';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final homeowner = UserSession.currentHomeowner!;
      await SupabaseService.updateProfile(
        id: homeowner.id,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        district: _selectedDistrict,
      );

      UserSession.loginAsHomeowner(Homeowner(
        id: homeowner.id,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        location: _districtLabels[_selectedDistrict]!,
        email: homeowner.email,
        district: _selectedDistrict,
        joinedAt: homeowner.joinedAt,
        isVerified: homeowner.isVerified,
        totalJobsPosted: homeowner.totalJobsPosted,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor:
                          AppTheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : 'H',
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Tap to change photo',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),

              const SizedBox(height: 32),

              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'e.g. Jean Pierre Habimana',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (v.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildLabel('Phone Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+250 781234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 9) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

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
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                items: _districtLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedDistrict = v);
                },
              ),

              const SizedBox(height: 32),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
