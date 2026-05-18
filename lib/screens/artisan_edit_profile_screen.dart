import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickfix/models/artisan.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';

class ArtisanEditProfileScreen extends StatefulWidget {
  const ArtisanEditProfileScreen({super.key});

  @override
  State<ArtisanEditProfileScreen> createState() =>
      _ArtisanEditProfileScreenState();
}

class _ArtisanEditProfileScreenState extends State<ArtisanEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _aboutController;
  late TextEditingController _priceController;
  late TextEditingController _experienceController;

  late String _selectedTrade;
  late Set<String> _selectedSkills;
  late String _selectedLocation;

  // Image state
  Uint8List? _imageBytes;
  String? _currentAvatarUrl;
  bool _isUploadingImage = false;
  bool _isLoading = false;

  final Map<String, List<String>> _tradeSkills = {
    'Plumber': [
      'Pipe Repair', 'Leak Detection', 'Water Heater',
      'Drain Cleaning', 'Bathroom Fitting',
    ],
    'Electrician': [
      'Wiring', 'Solar Installation', 'Circuit Breaker',
      'Lighting', 'Generator Repair',
    ],
    'Painter': [
      'Interior Painting', 'Exterior Painting', 'Wall Texturing',
      'Waterproofing', 'Colour Consultation',
    ],
    'Carpenter': [
      'Furniture Repair', 'Door Fitting', 'Cabinets',
      'Roofing', 'Custom Woodwork',
    ],
    'Cleaner': [
      'Deep Cleaning', 'Post-Construction', 'Office Cleaning',
      'Carpet Cleaning', 'Window Cleaning',
    ],
    'Mason': [
      'Bricklaying', 'Plastering', 'Tiling',
      'Foundation Work', 'Wall Construction',
    ],
  };

  final List<String> _locations = [
    'Gasabo, Kigali',
    'Kicukiro, Kigali',
    'Nyarugenge, Kigali',
  ];

  @override
  void initState() {
    super.initState();
    final artisan = UserSession.currentArtisan;
    _nameController = TextEditingController(text: artisan?.name ?? '');
    _phoneController = TextEditingController(text: artisan?.phoneNumber ?? '');
    _aboutController = TextEditingController(text: artisan?.about ?? '');
    _priceController = TextEditingController(
        text: artisan != null && artisan.startingPrice > 0
            ? artisan.startingPrice.toString()
            : '');
    _experienceController = TextEditingController(
        text: artisan != null && artisan.yearsOfExperience > 0
            ? artisan.yearsOfExperience.toString()
            : '');
    _selectedTrade = _normalizedTrade(artisan?.trade);
    _selectedSkills = Set<String>.from(artisan?.skills ?? []);
    _selectedLocation = _normalizeLocation(artisan?.location);
    _currentAvatarUrl = artisan?.profileImageUrl;
  }

  String _normalizedTrade(String? trade) {
    if (trade == null || trade == 'Not set' || trade.isEmpty) return 'Plumber';
    return _tradeSkills.containsKey(trade) ? trade : 'Plumber';
  }

  String _districtFromLocation(String location) {
    if (location.toLowerCase().contains('gasabo')) return 'gasabo';
    if (location.toLowerCase().contains('kicukiro')) return 'kicukiro';
    if (location.toLowerCase().contains('nyarugenge')) return 'nyarugenge';
    return 'gasabo';
  }

  String _normalizeLocation(String? location) {
    if (location == null || location.isEmpty) return _locations.first;
    return _locations.firstWhere(
      (l) => l.toLowerCase().contains(location.toLowerCase().split(',').first),
      orElse: () => _locations.first,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (e) {
      debugPrint('[EditProfile] pickImage failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: AppTheme.primary),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppTheme.secondary),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_currentAvatarUrl != null || _imageBytes != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppTheme.error),
                  ),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: AppTheme.error)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageBytes = null;
                      _currentAvatarUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one skill'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentArtisan = UserSession.currentArtisan as VerifiedArtisan?;
      final userId = currentArtisan?.id ?? SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not logged in.');

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final district = _districtFromLocation(_selectedLocation);
      final yearsOfExperience =
          int.tryParse(_experienceController.text.trim()) ?? 0;
      final startingPrice =
          int.tryParse(_priceController.text.trim()) ?? 0;

      // Upload image if a new one was picked
      String? newAvatarUrl = _currentAvatarUrl;
      if (_imageBytes != null) {
        setState(() => _isUploadingImage = true);
        try {
          newAvatarUrl = await SupabaseService.uploadArtisanAvatar(
              userId, _imageBytes!);
        } catch (e) {
          debugPrint('[EditProfile] Avatar upload failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Photo upload failed: $e'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
          newAvatarUrl = _currentAvatarUrl; // keep old URL on failure
        } finally {
          if (mounted) setState(() => _isUploadingImage = false);
        }
      }

      await SupabaseService.updateArtisanProfile(
        id: userId,
        name: name,
        phoneNumber: phone,
        district: district,
        trade: _selectedTrade,
        skills: _selectedSkills.toList(),
        yearsOfExperience: yearsOfExperience,
        startingPrice: startingPrice,
        about: _aboutController.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      // Update local session immediately
      UserSession.loginAsArtisan(VerifiedArtisan(
        id: userId,
        name: name,
        phoneNumber: phone,
        location: _selectedLocation,
        rating: currentArtisan?.rating ?? 0.0,
        totalReviews: currentArtisan?.totalReviews ?? 0,
        trade: _selectedTrade,
        skills: _selectedSkills.toList(),
        yearsOfExperience: yearsOfExperience,
        completedJobs: currentArtisan?.completedJobs ?? 0,
        about: _aboutController.text.trim(),
        startingPrice: startingPrice,
        isAvailable: currentArtisan?.isAvailable ?? false,
        verificationId: currentArtisan?.verificationId ?? 'VRF-000',
        verifiedOn: currentArtisan?.verifiedOn ?? DateTime.now(),
        profileImageUrl: newAvatarUrl,
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
      debugPrint('[ArtisanEdit] Save failed: $e');
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: (_isLoading || _isUploadingImage) ? null : _saveProfile,
            child: const Text('Save',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ──────────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Stack(
                    children: [
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              width: 3),
                        ),
                        child: ClipOval(
                          child: _isUploadingImage
                              ? Container(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : _imageBytes != null
                                  ? Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.cover,
                                      width: 108,
                                      height: 108,
                                    )
                                  : _currentAvatarUrl != null
                                      ? Image.network(
                                          _currentAvatarUrl!,
                                          fit: BoxFit.cover,
                                          width: 108,
                                          height: 108,
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  _avatarInitial(),
                                        )
                                      : _avatarInitial(),
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
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Tap to change photo',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ),

              const SizedBox(height: 28),

              // ── Basic info ───────────────────────────────────────────────
              _buildSection('Basic Information', [
                _buildLabel('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Jean Pierre Habimana',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
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
                    return null;
                  },
                ),

                const SizedBox(height: 16),
                _buildLabel('Location'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: _locations
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedLocation = v!),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Trade & skills ───────────────────────────────────────────
              _buildSection('Trade & Skills', [
                _buildLabel('Your Trade'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTrade,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.construction_outlined),
                  ),
                  items: _tradeSkills.keys
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedTrade = v!;
                    _selectedSkills.clear();
                  }),
                ),

                const SizedBox(height: 16),
                _buildLabel('Skills'),
                const SizedBox(height: 8),
                Text(
                  'Select all that apply',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tradeSkills[_selectedTrade]!.map((skill) {
                    final selected = _selectedSkills.contains(skill);
                    return GestureDetector(
                      onTap: () => setState(() => selected
                          ? _selectedSkills.remove(skill)
                          : _selectedSkills.add(skill)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary
                                : Colors.grey.shade300,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected) ...[
                              const Icon(Icons.check,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              skill,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Experience & pricing ─────────────────────────────────────
              _buildSection('Experience & Pricing', [
                _buildLabel('Years of Experience'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 5',
                    prefixIcon: Icon(Icons.work_outline),
                    suffixText: 'years',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter years of experience';
                    }
                    if (int.tryParse(v.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),
                _buildLabel('Starting Price (RWF)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 5000',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    suffixText: 'RWF',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your starting price';
                    }
                    final p = int.tryParse(v.trim());
                    if (p == null) return 'Enter a valid amount';
                    if (p < 1000) return 'Minimum is 1,000 RWF';
                    return null;
                  },
                ),
              ]),

              const SizedBox(height: 20),

              // ── About ────────────────────────────────────────────────────
              _buildSection('About You', [
                TextFormField(
                  controller: _aboutController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Describe your experience, work style, and what makes you stand out...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please write something about yourself';
                    }
                    if (v.trim().length < 20) {
                      return 'Please write at least 20 characters';
                    }
                    return null;
                  },
                ),
              ]),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: (_isLoading || _isUploadingImage)
                    ? Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            _isUploadingImage
                                ? 'Uploading photo...'
                                : 'Saving profile...',
                            style: const TextStyle(
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarInitial() {
    final name = _nameController.text;
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'A',
          style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary),
      );
}
