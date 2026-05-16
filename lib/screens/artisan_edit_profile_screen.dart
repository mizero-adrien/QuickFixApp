import 'package:flutter/material.dart';
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

class _ArtisanEditProfileScreenState
    extends State<ArtisanEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers — pre-filled with current artisan data
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _aboutController;
  late TextEditingController _priceController;
  late TextEditingController _experienceController;

  // Covers A1 — typed variables
  late String _selectedTrade;
  late Set<String> _selectedSkills;
  late String _selectedLocation;
  bool _isLoading = false;

  // Covers A3 — Map
  final Map<String, List<String>> _tradeSkills = {
    'Plumber': [
      'Pipe Repair',
      'Leak Detection',
      'Water Heater',
      'Drain Cleaning',
      'Bathroom Fitting',
    ],
    'Electrician': [
      'Wiring',
      'Solar Installation',
      'Circuit Breaker',
      'Lighting',
      'Generator Repair',
    ],
    'Painter': [
      'Interior Painting',
      'Exterior Painting',
      'Wall Texturing',
      'Waterproofing',
      'Colour Consultation',
    ],
    'Carpenter': [
      'Furniture Repair',
      'Door Fitting',
      'Cabinets',
      'Roofing',
      'Custom Woodwork',
    ],
    'Cleaner': [
      'Deep Cleaning',
      'Post-Construction',
      'Office Cleaning',
      'Carpet Cleaning',
      'Window Cleaning',
    ],
    'Mason': [
      'Bricklaying',
      'Plastering',
      'Tiling',
      'Foundation Work',
      'Wall Construction',
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
    // Pre-fill with current artisan data
    final artisan = UserSession.currentArtisan;
    _nameController =
        TextEditingController(text: artisan?.name ?? '');
    _phoneController =
        TextEditingController(text: artisan?.phoneNumber ?? '');
    _aboutController =
        TextEditingController(text: artisan?.about ?? '');
    _priceController = TextEditingController(
        text: artisan?.startingPrice.toString() ?? '');
    _experienceController = TextEditingController(
        text: artisan?.yearsOfExperience.toString() ?? '');
    _selectedTrade = artisan?.trade ?? 'Plumber';
    _selectedSkills = Set<String>.from(artisan?.skills ?? []);
    _selectedLocation = _normalizeLocation(artisan?.location);
  }

  String _districtFromLocation(String location) {
    if (location.toLowerCase().contains('gasabo')) return 'gasabo';
    if (location.toLowerCase().contains('kicukiro')) return 'kicukiro';
    if (location.toLowerCase().contains('nyarugenge')) return 'nyarugenge';
    return 'gasabo';
  }

  String _normalizeLocation(String? location) {
    if (location == null || location.isEmpty) {
      return _locations.first;
    }

    final existing = _locations.firstWhere(
      (loc) => loc.toLowerCase() == location.toLowerCase(),
      orElse: () => '',
    );

    if (existing.isNotEmpty) {
      return existing;
    }

    final partialMatch = _locations.firstWhere(
      (loc) => loc.toLowerCase().contains(location.toLowerCase()),
      orElse: () => '',
    );

    if (partialMatch.isNotEmpty) {
      return partialMatch;
    }

    _locations.insert(0, location);
    return location;
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

  // Covers B5 — async/await
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
      if (currentArtisan == null) {
        throw Exception('Session expired — please log in again.');
      }

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final district = _districtFromLocation(_selectedLocation);
      final yearsOfExperience =
          int.tryParse(_experienceController.text.trim()) ??
              currentArtisan.yearsOfExperience;
      final startingPrice =
          int.tryParse(_priceController.text.trim()) ??
              currentArtisan.startingPrice;

      await SupabaseService.updateArtisanProfile(
        id: currentArtisan.id,
        name: name,
        phoneNumber: phone,
        district: district,
        trade: _selectedTrade,
        skills: _selectedSkills.toList(),
        yearsOfExperience: yearsOfExperience,
        startingPrice: startingPrice,
        about: _aboutController.text.trim(),
      );

      // Update local session so UI reflects changes immediately
      UserSession.loginAsArtisan(VerifiedArtisan(
        id: currentArtisan.id,
        name: name,
        phoneNumber: phone,
        location: _selectedLocation,
        rating: currentArtisan.rating,
        totalReviews: currentArtisan.totalReviews,
        trade: _selectedTrade,
        skills: _selectedSkills.toList(),
        yearsOfExperience: yearsOfExperience,
        completedJobs: currentArtisan.completedJobs,
        about: _aboutController.text.trim(),
        startingPrice: startingPrice,
        isAvailable: currentArtisan.isAvailable,
        verificationId: currentArtisan.verificationId,
        verifiedOn: currentArtisan.verifiedOn,
        profileImageUrl: currentArtisan.profileImageUrl,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
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
              // Profile photo section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor:
                          AppTheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0]
                            : 'A',
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
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
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
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Full name
              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Jean Pierre Habimana',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                onChanged: (value) => setState(() {}),
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

              // Phone number
              _buildLabel('Phone Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+250 781234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Location
              _buildLabel('Location'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: _locations
                    .map(
                      (loc) => DropdownMenuItem(
                        value: loc,
                        child: Text(loc),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedLocation = value!),
              ),

              const SizedBox(height: 16),

              // Trade
              _buildLabel('Your Trade'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTrade,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: _tradeSkills.keys
                    .map(
                      (trade) => DropdownMenuItem(
                        value: trade,
                        child: Text(trade),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedTrade = value!;
                  _selectedSkills.clear();
                }),
              ),

              const SizedBox(height: 16),

              // Skills
              _buildLabel('Skills'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tradeSkills[_selectedTrade]!
                    .map(
                      (skill) => GestureDetector(
                        onTap: () => setState(() {
                          if (_selectedSkills.contains(skill)) {
                            _selectedSkills.remove(skill);
                          } else {
                            _selectedSkills.add(skill);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedSkills.contains(skill)
                                ? AppTheme.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _selectedSkills.contains(skill)
                                  ? AppTheme.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedSkills.contains(skill)
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Years of experience
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter years of experience';
                  }
                  final years = int.tryParse(value.trim());
                  if (years == null || years < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Starting price
              _buildLabel('Starting Price (RWF)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 5000',
                  prefixIcon:
                      Icon(Icons.account_balance_wallet_outlined),
                  suffixText: 'RWF',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your starting price';
                  }
                  final price = int.tryParse(value.trim());
                  if (price == null) {
                    return 'Please enter a valid amount';
                  }
                  if (price < 1000) {
                    return 'Minimum starting price is 1,000 RWF';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // About
              _buildLabel('About You'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aboutController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Describe your experience and work style...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write something about yourself';
                  }
                  if (value.trim().length < 30) {
                    return 'Please write at least 30 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Save button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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