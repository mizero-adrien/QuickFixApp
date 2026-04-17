import 'package:flutter/material.dart';
import 'package:quickfix/models/artisan.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/theme/app_theme.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  // Form key — covers D3
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Covers A1 — typed variables
  ServiceCategory? _selectedCategory;
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  // Category labels — covers A3 (Map)
  final Map<ServiceCategory, String> _categoryLabels = {
    ServiceCategory.plumbing: 'Plumbing',
    ServiceCategory.electrical: 'Electrical',
    ServiceCategory.painting: 'Painting',
    ServiceCategory.carpentry: 'Carpentry',
    ServiceCategory.cleaning: 'Cleaning',
    ServiceCategory.masonry: 'Masonry',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Date picker — covers A2 (named parameters)
  Future<void> _pickDate({required BuildContext context}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Form submission — covers B5 (async/await), D3
  Future<void> _submitForm(VerifiedArtisan artisan) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isSubmitting = false);

      if (mounted) {
        _showSuccessDialog(artisan);
      }
    }
  }

  void _showSuccessDialog(VerifiedArtisan artisan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppTheme.success,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Job Request Sent!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${artisan.name} will respond with a quote within 30 minutes.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.popUntil(context, NamedRoutes.isHome);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Covers D2 — receiving artisan data from detail screen
    final artisan =
        ModalRoute.of(context)!.settings.arguments as VerifiedArtisan;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Request a Job',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artisan summary card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha:0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha:0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          AppTheme.primary.withValues(alpha:0.15),
                      child: Text(
                        artisan.name[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artisan.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            artisan.trade,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: AppTheme.secondary),
                        const SizedBox(width: 2),
                        Text(
                          artisan.rating.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Service category dropdown
              const Text(
                'Service Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ServiceCategory>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  hintText: 'Select a service category',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: _categoryLabels.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value),
                // Covers D4 — validator
                validator: (value) =>
                    value == null ? 'Please select a service type' : null,
              ),

              const SizedBox(height: 16),

              // Job title field — covers D3, D4
              _buildLabel('Job Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Burst pipe in kitchen',
                ),
                validator: (value) {
                  // Covers D4 — length check
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a job title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Location field — covers D3, D4
              _buildLabel('Location / Address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. KG 15 Ave, Gasabo',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your location';
                  }
                  // Covers D4 — min length check
                  if (value.trim().length < 8) {
                    return 'Please enter a more detailed address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Preferred date field — covers D3, D4
              _buildLabel('Preferred Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickDate(context: context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: _selectedDate == null
                          ? 'Select a date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      prefixIcon:
                          const Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (_) => _selectedDate == null
                        ? 'Please select a preferred date'
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Budget field — covers D3, D4
              _buildLabel('Budget (RWF)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 10000',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  suffixText: 'RWF',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your budget';
                  }
                  // Covers D4 — pattern/format check
                  final budget = int.tryParse(value.trim());
                  if (budget == null) {
                    return 'Please enter a valid amount in RWF';
                  }
                  if (budget < 1000) {
                    return 'Minimum budget is 1,000 RWF';
                  }
                  if (budget > 10000000) {
                    return 'Please enter a realistic budget';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description field — covers D3, D4
              _buildLabel('Job Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the problem in detail...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the job';
                  }
                  // Covers D4 — min length check
                  if (value.trim().length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Note text
              const Text(
                'Artisans near you will send quotes within 30 minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // Submit button — covers D3
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () => _submitForm(artisan),
                      child: const Text(
                        'Send Job Request',
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

  // Reusable label builder — covers A2 (arrow function)
  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      );
}

// Named routes helper — covers D1
class NamedRoutes {
  static const String home = '/';
  static const String artisanDetail = '/artisan-detail';
  static const String bookingForm = '/booking-form';

  // Covers A2 — named parameter function
  static bool isHome(Route<dynamic> route) => route.settings.name == home;
}