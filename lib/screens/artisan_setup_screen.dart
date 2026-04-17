import 'package:flutter/material.dart';
import 'package:quickfix/models/artisan.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/theme/app_theme.dart';

class ArtisanSetupScreen extends StatefulWidget {
  const ArtisanSetupScreen({super.key});

  @override
  State<ArtisanSetupScreen> createState() => _ArtisanSetupScreenState();
}

class _ArtisanSetupScreenState extends State<ArtisanSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aboutController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();

  // Covers A1 — typed variables
  String? _selectedTrade;
  final Set<String> _selectedSkills = {};
  bool _isLoading = false;

  // Covers A3 — Map of trades to skills
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

  @override
  void dispose() {
    _aboutController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // Covers B5 — async/await
  Future<void> _completeSetup(Map<String, dynamic> args) async {
    if (_formKey.currentState!.validate()) {
      // Covers A4 — validation check
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
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isLoading = false);

      if (mounted) {
        // Create artisan and login
        final artisan = VerifiedArtisan(
          id: 'a${DateTime.now().millisecondsSinceEpoch}',
          name: args['name'] as String,
          phoneNumber: args['phone'] as String,
          location: args['district'] as String,
          rating: 0.0,
          totalReviews: 0,
          trade: _selectedTrade!,
          skills: _selectedSkills.toList(),
          yearsOfExperience:
              int.tryParse(_experienceController.text.trim()) ?? 1,
          completedJobs: 0,
          about: _aboutController.text.trim(),
          startingPrice:
              int.tryParse(_priceController.text.trim()) ?? 5000,
          isAvailable: true,
          verificationId:
              'VRF-${DateTime.now().millisecondsSinceEpoch}',
          verifiedOn: DateTime.now(),
        );

        UserSession.loginAsArtisan(artisan);
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Covers D2 — receiving data from signup screen
    final args = ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Set Up Your Profile',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text('👋', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${(args['name'] as String).split(' ').first}!',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Text(
                            'Complete your profile to start receiving job requests.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Trade selection
              _buildLabel('Your Trade / Profession'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTrade,
                decoration: InputDecoration(
                  hintText: 'Select your trade',
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
                  _selectedTrade = value;
                  _selectedSkills.clear();
                }),
                validator: (value) =>
                    value == null ? 'Please select your trade' : null,
              ),

              const SizedBox(height: 16),

              // Skills selection
              _buildLabel('Select Your Skills'),
              const SizedBox(height: 8),
              // Covers A4 — if/else for showing skills
              _selectedTrade == null
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Select your trade first to see available skills',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tradeSkills[_selectedTrade]!
                          .map(
                            (skill) => GestureDetector(
                              onTap: () => setState(() {
                                // Covers A3 — Set operations
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
                                  borderRadius:
                                      BorderRadius.circular(24),
                                  border: Border.all(
                                    color:
                                        _selectedSkills.contains(skill)
                                            ? AppTheme.primary
                                            : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  skill,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _selectedSkills.contains(skill)
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
                    return 'Please enter your years of experience';
                  }
                  final years = int.tryParse(value.trim());
                  if (years == null || years < 0) {
                    return 'Please enter a valid number';
                  }
                  if (years > 50) {
                    return 'Please enter a realistic value';
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
                      'Describe your experience, work style, and what makes you stand out...',
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

              // Submit button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () => _completeSetup(args),
                      child: const Text(
                        'Complete Profile & Continue',
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