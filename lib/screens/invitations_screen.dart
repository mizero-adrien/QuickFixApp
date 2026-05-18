import 'package:flutter/material.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';

class InvitationsScreen extends StatefulWidget {
  final VoidCallback? onStatusChanged;

  const InvitationsScreen({super.key, this.onStatusChanged});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  List<Job> _invitations = [];
  bool _isLoading = true;
  String? _actingOnId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final artisanId = UserSession.currentArtisan?.id
        ?? SupabaseService.currentUser?.id;
    if (artisanId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final invitations = await SupabaseService.getInvitationsForArtisan(artisanId);
      if (mounted) setState(() => _invitations = invitations);
    } catch (e) {
      debugPrint('[Invitations] Load failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _accept(Job job) async {
    setState(() => _actingOnId = job.id);
    try {
      final artisanName = UserSession.currentArtisan?.name ?? 'The artisan';
      await SupabaseService.acceptInvitation(
        jobId: job.id,
        homeownerId: job.homeownerId,
        artisanName: artisanName,
        jobTitle: job.title,
      );
      if (mounted) {
        setState(() {
          final idx = _invitations.indexWhere((j) => j.id == job.id);
          if (idx != -1) {
            _invitations[idx] = Job(
              id: job.id,
              homeownerId: job.homeownerId,
              title: job.title,
              description: job.description,
              location: job.location,
              category: job.category,
              status: JobStatus.booked,
              budgetRwf: job.budgetRwf,
              requestedAt: job.requestedAt,
              assignedArtisanId: job.assignedArtisanId,
            );
          }
        });
        widget.onStatusChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation accepted! The homeowner has been notified.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _actingOnId = null);
    }
  }

  Future<void> _decline(Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Decline Invitation?'),
        content: const Text(
          'The homeowner will be notified that you declined this job.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Yes, Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actingOnId = job.id);
    try {
      final artisanName = UserSession.currentArtisan?.name ?? 'The artisan';
      await SupabaseService.declineInvitation(
        jobId: job.id,
        homeownerId: job.homeownerId,
        artisanName: artisanName,
        jobTitle: job.title,
      );
      if (mounted) {
        setState(() {
          final idx = _invitations.indexWhere((j) => j.id == job.id);
          if (idx != -1) {
            _invitations[idx] = Job(
              id: job.id,
              homeownerId: job.homeownerId,
              title: job.title,
              description: job.description,
              location: job.location,
              category: job.category,
              status: JobStatus.cancelled,
              budgetRwf: job.budgetRwf,
              requestedAt: job.requestedAt,
              assignedArtisanId: job.assignedArtisanId,
            );
          }
        });
        widget.onStatusChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined. The homeowner has been notified.'),
            backgroundColor: AppTheme.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _actingOnId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_invitations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline_rounded, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No invitations yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'When a homeowner books you directly,\nyou\'ll see it here.',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _invitations.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildCard(_invitations[index]),
      ),
    );
  }

  Widget _buildCard(Job job) {
    final isActing = _actingOnId == job.id;
    final isPending = job.status == JobStatus.requested;
    final isAccepted = job.status == JobStatus.booked;
    final isDeclined = job.status == JobStatus.cancelled;

    Color statusColor;
    String statusLabel;
    if (isAccepted) {
      statusColor = AppTheme.success;
      statusLabel = 'Accepted';
    } else if (isDeclined) {
      statusColor = AppTheme.error;
      statusLabel = 'Declined';
    } else {
      statusColor = AppTheme.secondary;
      statusLabel = 'Pending';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppTheme.primary.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_outline_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      job.categoryLabel,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          if (job.description.isNotEmpty) ...[
            Text(
              job.description,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],

          // Details row
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _detail(Icons.location_on_outlined, job.location),
              if (job.budgetRwf != null)
                _detail(Icons.account_balance_wallet_outlined,
                    '${job.budgetRwf} RWF'),
              _detail(Icons.access_time_outlined, _timeAgo(job.requestedAt)),
            ],
          ),

          // Action buttons — only for pending invitations
          if (isPending) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            isActing
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _decline(job),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Decline',
                              style: TextStyle(
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _accept(job),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Accept',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      );

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
