import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/services/groq_service.dart';
import 'package:quickfix/services/supabase_service.dart';
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
  Uint8List? _photoBytes;

  final Map<ServiceCategory, String> _categoryLabels = {
    ServiceCategory.plumbing: '🔧 Plumbing',
    ServiceCategory.electrical: '⚡ Electrical',
    ServiceCategory.painting: '🎨 Painting',
    ServiceCategory.carpentry: '🪚 Carpentry',
    ServiceCategory.cleaning: '🧹 Cleaning',
    ServiceCategory.masonry: '🧱 Masonry',
  };

  // Clean category values stored in DB (no emoji, lowercase)
  final Map<ServiceCategory, String> _categoryValues = {
    ServiceCategory.plumbing: 'plumbing',
    ServiceCategory.electrical: 'electrical',
    ServiceCategory.painting: 'painting',
    ServiceCategory.carpentry: 'carpentry',
    ServiceCategory.cleaning: 'cleaning',
    ServiceCategory.masonry: 'masonry',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 960,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _photoBytes = bytes);
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
    if (!_formKey.currentState!.validate()) return;

    final homeownerId = UserSession.currentHomeowner?.id;
    if (homeownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in as a homeowner to post a job.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      debugPrint('[JobPost] Posting job to Supabase...');

      String? photoUrl;
      if (_photoBytes != null) {
        final pathKey = '${homeownerId}_${DateTime.now().millisecondsSinceEpoch}';
        photoUrl = await SupabaseService.uploadJobPhoto(pathKey, _photoBytes!);
        debugPrint('[JobPost] Photo uploaded: $photoUrl');
      }

      await SupabaseService.postJob(
        homeownerId: homeownerId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        category: _categoryValues[_selectedCategory!]!,
        budgetRwf: int.tryParse(_budgetController.text.trim()),
        photoUrl: photoUrl,
      );
      debugPrint('[JobPost] Job posted successfully');
      if (mounted) _showSuccessDialog();
    } catch (e) {
      debugPrint('[JobPost] Failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post job: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              // Pop dialog then pop this screen back to home (home will reload jobs)
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  void _openAiHelper() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiDescriptionSheet(
        category: _selectedCategory != null
            ? _categoryLabels[_selectedCategory!]!
            : 'Not selected',
        title: _titleController.text.trim(),
        existingDescription: _descriptionController.text.trim(),
        onAccepted: (generated) {
          setState(() => _descriptionController.text = generated);
        },
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
                initialValue: _selectedCategory,
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
              Row(
                children: [
                  _buildLabel('Job Description'),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openAiHelper,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✨', style: TextStyle(fontSize: 13)),
                          SizedBox(width: 4),
                          Text(
                            'Write with AI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

              const SizedBox(height: 16),

              // Photo picker
              _buildLabel('Job Photo (optional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _photoBytes != null
                          ? AppTheme.primary
                          : Colors.grey.shade300,
                      width: _photoBytes != null ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _photoBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_photoBytes!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _photoBytes = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add a photo of the job site',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                ),
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

// ── AI Description Helper Bottom Sheet ───────────────────────────────────────

class _AiDescriptionSheet extends StatefulWidget {
  final String category;
  final String title;
  final String existingDescription;
  final ValueChanged<String> onAccepted;

  const _AiDescriptionSheet({
    required this.category,
    required this.title,
    required this.existingDescription,
    required this.onAccepted,
  });

  @override
  State<_AiDescriptionSheet> createState() => _AiDescriptionSheetState();
}

class _AiDescriptionSheetState extends State<_AiDescriptionSheet> {
  late final TextEditingController _notesController;
  String? _generated;
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill notes with whatever the homeowner typed so far
    _notesController =
        TextEditingController(text: widget.existingDescription);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      setState(() => _error = 'Please write a few rough notes first.');
      return;
    }
    setState(() {
      _isGenerating = true;
      _error = null;
      _generated = null;
    });
    try {
      final result = await GroqService.improveJobDescription(
        category: widget.category,
        title: widget.title.isNotEmpty ? widget.title : 'Home repair job',
        roughNotes: notes,
      );
      if (mounted) setState(() => _generated = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _accept() {
    if (_generated == null) return;
    widget.onAccepted(_generated!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('✨',
                      style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Job Description Helper',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Describe your problem in a few words — AI will write the rest.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Rough notes input
            const Text(
              'Your rough notes',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g. "pipe burst under sink, water everywhere, urgent"',
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 14),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: _isGenerating
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Generating...',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _generate,
                      icon: const Text('✨',
                          style: TextStyle(fontSize: 14)),
                      label: Text(
                        _generated == null ? 'Generate Description' : 'Regenerate',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Generated result
            if (_generated != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Generated Description',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _generated!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Discard',
                          style:
                              TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _accept,
                      icon: const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'Use This Description',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}