import 'package:flutter/material.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Job _job;
  bool _hasBid = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Map<String, dynamic>) {
        _job = args['job'] as Job;
        _hasBid = args['hasBid'] as bool? ?? false;
      } else {
        // Fallback: plain Job (e.g. navigated from elsewhere)
        _job = args as Job;
      }
      _initialized = true;
    }
  }

  // ── Category helpers ──────────────────────────────────────────────────────

  Color get _categoryColor {
    switch (_job.category) {
      case ServiceCategory.plumbing:
        return const Color(0xFF0EA5E9);
      case ServiceCategory.electrical:
        return const Color(0xFFF59E0B);
      case ServiceCategory.painting:
        return const Color(0xFF8B5CF6);
      case ServiceCategory.carpentry:
        return const Color(0xFFF97316);
      case ServiceCategory.cleaning:
        return const Color(0xFF10B981);
      case ServiceCategory.masonry:
        return const Color(0xFF64748B);
    }
  }

  IconData get _categoryIcon {
    switch (_job.category) {
      case ServiceCategory.plumbing:
        return Icons.water_damage_outlined;
      case ServiceCategory.electrical:
        return Icons.electric_bolt_outlined;
      case ServiceCategory.painting:
        return Icons.format_paint_outlined;
      case ServiceCategory.carpentry:
        return Icons.handyman_outlined;
      case ServiceCategory.cleaning:
        return Icons.cleaning_services_outlined;
      case ServiceCategory.masonry:
        return Icons.construction_outlined;
    }
  }

  Color _statusColor(JobStatus s) {
    switch (s) {
      case JobStatus.requested:
        return AppTheme.secondary;
      case JobStatus.quoted:
        return Colors.purple;
      case JobStatus.booked:
        return AppTheme.primary;
      case JobStatus.onTheWay:
        return Colors.blue;
      case JobStatus.inProgress:
        return Colors.orange;
      case JobStatus.completed:
        return AppTheme.success;
      case JobStatus.cancelled:
        return AppTheme.error;
    }
  }

  // ── Formatting ────────────────────────────────────────────────────────────

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _fmt(int amount) => amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  // ── Actions ───────────────────────────────────────────────────────────────

  void _openBidSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BidSheet(
        job: _job,
        onBidSubmitted: () {
          if (mounted) Navigator.pop(context, true);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildHero(),
          SliverToBoxAdapter(child: _buildBody()),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Hero / Image ──────────────────────────────────────────────────────────

  Widget _buildHero() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: _categoryColor,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _job.photoUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _job.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _categoryPlaceholder(),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : _categoryPlaceholder(),
                  ),
                  // Gradient overlay so the title area is readable
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _categoryPlaceholder(),
      ),
    );
  }

  Widget _categoryPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _categoryColor,
            _categoryColor.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(_categoryIcon, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            _job.categoryLabel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row
          Row(
            children: [
              _Badge(
                label: _job.categoryLabel,
                color: _categoryColor,
                icon: _categoryIcon,
              ),
              const SizedBox(width: 8),
              _Badge(
                label: _job.statusLabel,
                color: _statusColor(_job.status),
              ),
              const Spacer(),
              if (_job.bidCount > 0)
                _Badge(
                  label:
                      '${_job.bidCount} bid${_job.bidCount == 1 ? '' : 's'}',
                  color: AppTheme.primary,
                  icon: Icons.gavel,
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Title
          Text(
            _job.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Posted ${_timeAgo(_job.requestedAt)} · ${_formatDate(_job.requestedAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),

          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 18),

          // Info tiles
          _InfoTile(
            icon: Icons.location_on_outlined,
            label: 'Job Location',
            value: _job.location,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 14),
          _InfoTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Client Budget',
            value: _job.budgetRwf != null
                ? '${_fmt(_job.budgetRwf!)} RWF'
                : 'Negotiable',
            color: AppTheme.secondary,
          ),

          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 18),

          // Description
          const Text(
            'Job Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _job.description.isEmpty
                ? 'No additional description provided.'
                : _job.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.75,
            ),
          ),

          const SizedBox(height: 22),

          // Tip / status box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_hasBid ? AppTheme.success : AppTheme.primary)
                  .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_hasBid ? AppTheme.success : AppTheme.primary)
                    .withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _hasBid
                      ? Icons.check_circle_outline
                      : Icons.lightbulb_outline,
                  size: 18,
                  color: _hasBid ? AppTheme.success : AppTheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _hasBid
                        ? 'You have already submitted a bid for this job. '
                            'The homeowner will review all bids and notify you of their decision.'
                        : 'Tip: Write a personalised note explaining your experience '
                            'with this type of work. Homeowners prefer bids with clear, '
                            'confident messages.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _hasBid ? AppTheme.success : AppTheme.primary,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky bottom bar ────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_job.budgetRwf != null) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text(
                  '${_fmt(_job.budgetRwf!)} RWF',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: _hasBid
                ? ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_outline,
                        size: 18, color: Colors.white),
                    label: const Text(
                      'Already Applied',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      disabledBackgroundColor: AppTheme.success,
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _openBidSheet,
                    icon: const Icon(Icons.gavel, color: Colors.white, size: 18),
                    label: const Text(
                      'Send Bid',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bid sheet ─────────────────────────────────────────────────────────────

class _BidSheet extends StatefulWidget {
  final Job job;
  final VoidCallback onBidSubmitted;

  const _BidSheet({required this.job, required this.onBidSubmitted});

  @override
  State<_BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends State<_BidSheet> {
  final _bidController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _bidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _bidController.text.trim();
    if (amountText.isEmpty) {
      _snack('Please enter your bid amount', error: true);
      return;
    }
    final amount = int.tryParse(amountText);
    if (amount == null || amount < 1000) {
      _snack('Minimum bid is 1,000 RWF', error: true);
      return;
    }

    final artisanId =
        UserSession.currentArtisan?.id ?? SupabaseService.currentUser?.id;
    if (artisanId == null) {
      _snack('Not logged in — please log out and sign in again.', error: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await SupabaseService.postBid(
        jobId: widget.job.id,
        artisanId: artisanId,
        amountRwf: amount,
        note: _noteController.text.trim(),
        artisanName: UserSession.currentArtisan?.name,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onBidSubmitted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _snack('Failed to send bid: $e', error: true);
      }
    }
  }

  void _snack(String message, {required bool error}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppTheme.error : AppTheme.success,
    ));
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
          // Handle bar
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

          const Text(
            'Send Your Bid',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.job.title,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 22),

          const Text(
            'Your Price (RWF)',
            style:
                TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bidController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 8,000',
              suffixText: 'RWF',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Note to Homeowner',
            style:
                TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Explain why you are the right person for this job...',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Submit Bid',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
