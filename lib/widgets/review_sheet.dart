import 'package:flutter/material.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';

class ReviewSheet extends StatefulWidget {
  final String artisanId;
  final String artisanName;
  final String jobTitle;

  const ReviewSheet({
    super.key,
    required this.artisanId,
    required this.artisanName,
    required this.jobTitle,
  });

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap a star to rate')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final reviewerName =
          UserSession.currentHomeowner?.name ?? 'Anonymous';
      await SupabaseService.addReview(
        artisanId: widget.artisanId,
        rating: _rating,
        comment: _commentController.text.trim(),
        reviewerName: reviewerName,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted — thank you!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded,
                    color: AppTheme.secondary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate the Artisan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      widget.artisanName,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'How was the work on "${widget.jobTitle}"?',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // Stars
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = (i + 1).toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 44,
                      color: i < _rating
                          ? AppTheme.secondary
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                _labels[_rating.toInt()],
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          const Text(
            'Comment (optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Tell others about your experience...',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterStyle: const TextStyle(fontSize: 11),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit Review',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows the [ReviewSheet] bottom sheet and returns true if a review was submitted.
/// Fetches the artisan's display name from their profile.
Future<bool> showReviewSheet(
  BuildContext context, {
  required String artisanId,
  required String jobTitle,
}) async {
  String artisanName = 'your artisan';
  try {
    final profile = await SupabaseService.getProfile(artisanId);
    artisanName = profile?['name'] as String? ?? artisanName;
  } catch (_) {}
  if (!context.mounted) return false;
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReviewSheet(
      artisanId: artisanId,
      artisanName: artisanName,
      jobTitle: jobTitle,
    ),
  );
  return result == true;
}
