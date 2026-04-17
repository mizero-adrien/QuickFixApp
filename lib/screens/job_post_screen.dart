import 'package:flutter/material.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/theme/app_theme.dart';

class JobPostScreen extends StatefulWidget {
  const JobPostScreen({super.key});

  @override
  State<JobPostScreen> createState() => _JobPostScreenState();
}

class _JobPostScreenState extends State<JobPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();

  ServiceCategory? _selectedCategory;
  DateTime? _selectedDate;
  bool _isLoading = false;

  final Map<ServiceCategory, String> _categoryLabels = {
    ServiceCategory.plumbing: '🔧 Plumbing',
    ServiceCategory.electrical: '⚡ Electrical',
    ServiceCategory.painting: '🎨 Painting',
    ServiceCategory.carpentry: '🪚 Carpentry',
    ServiceCategory.cleaning: '🧹 Cleaning',
    ServiceCategory.masonry: '🧱 Masonry',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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

  Future<void> _submitJob() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isLoading = false);

      if (mounted) {
        // Add job to dummy list
        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
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
              'Job Posted!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Artisans near you will start sending bids shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
              Navigator.pop(context);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post a Job',
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
              // Header banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha:0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha:0.2)),
                ),
                child: const Row(
                  children: [
                    Text('📋', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Describe your job and artisans will send you their best quotes.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Service category
              _buildLabel('Service Type'),
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
                validator: (value) =>
                    value == null ? 'Please select a service type' : null,
              ),

              const SizedBox(height: 16),

              // Job title
              _buildLabel('Job Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Burst pipe in kitchen',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
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

              // Location
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
                  if (value.trim().length < 8) {
                    return 'Please enter a more detailed address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Preferred date
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

              // Budget
              _buildLabel('Your Budget (RWF)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 10000',
                  prefixIcon:
                      Icon(Icons.account_balance_wallet_outlined),
                  suffixText: 'RWF',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your budget';
                  }
                  final budget = int.tryParse(value.trim());
                  if (budget == null) {
                    return 'Please enter a valid amount in RWF';
                  }
                  if (budget < 1000) {
                    return 'Minimum budget is 1,000 RWF';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
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
                  if (value.trim().length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Submit button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitJob,
                      child: const Text(
                        'Post Job Request',
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