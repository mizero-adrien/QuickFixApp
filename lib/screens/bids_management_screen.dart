import 'package:flutter/material.dart';
import 'package:quickfix/models/bid.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';

class BidsManagementScreen extends StatefulWidget {
  const BidsManagementScreen({super.key});

  @override
  State<BidsManagementScreen> createState() => _BidsManagementScreenState();
}

class _BidsManagementScreenState extends State<BidsManagementScreen> {
  List<Bid> _bids = [];
  bool _isLoading = true;
  String? _actingOnId;

  late Job _job;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _job = ModalRoute.of(context)!.settings.arguments as Job;
    _loadBids();
  }

  Future<void> _loadBids() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('[BidsMgmt] Loading bids for job ${_job.id}');
      final bids = await SupabaseService.getBidsForJob(_job.id);
      debugPrint('[BidsMgmt] Loaded ${bids.length} bids');
      if (mounted) setState(() => _bids = bids);
    } catch (e) {
      debugPrint('[BidsMgmt] Failed to load bids: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bids: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptBid(Bid bid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accept This Bid?'),
        content: Text(
          'Book ${bid.artisanName ?? 'this artisan'} for ${_fmt(bid.amountRwf)} RWF?\n\nAll other bids will be automatically declined.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Yes, Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actingOnId = bid.id);
    try {
      await SupabaseService.acceptBid(
        bidId: bid.id,
        jobId: _job.id,
        artisanId: bid.artisanId,
        jobTitle: _job.title,
        amountRwf: bid.amountRwf,
        homeownerId: UserSession.currentHomeowner?.id,
      );
      await _loadBids();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${bid.artisanName ?? 'Artisan'} has been booked! They will be notified.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('[BidsMgmt] acceptBid failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept bid: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _actingOnId = null);
    }
  }

  Future<void> _rejectBid(Bid bid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Decline This Bid?'),
        content: Text(
          '${bid.artisanName ?? 'This artisan'} will be notified that their bid was not selected.',
          style: const TextStyle(color: AppTheme.textSecondary),
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

    setState(() => _actingOnId = bid.id);
    try {
      await SupabaseService.rejectBid(
        bidId: bid.id,
        artisanId: bid.artisanId,
        jobTitle: _job.title,
      );
      if (mounted) {
        setState(() {
          final idx = _bids.indexWhere((b) => b.id == bid.id);
          if (idx != -1) {
            _bids[idx] = Bid(
              id: bid.id,
              jobId: bid.jobId,
              artisanId: bid.artisanId,
              amountRwf: bid.amountRwf,
              note: bid.note,
              status: BidStatus.rejected,
              createdAt: bid.createdAt,
              artisanName: bid.artisanName,
              artisanTrade: bid.artisanTrade,
              artisanRating: bid.artisanRating,
              artisanAvatarUrl: bid.artisanAvatarUrl,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${bid.artisanName ?? 'Artisan'} has been notified.'),
            backgroundColor: AppTheme.textSecondary,
          ),
        );
      }
    } catch (e) {
      debugPrint('[BidsMgmt] rejectBid failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline bid: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _actingOnId = null);
    }
  }

  String _fmt(int amount) => amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final pendingCount = _bids.where((b) => b.status == BidStatus.pending).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Bids Received',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            if (!_isLoading)
              Text(
                '$pendingCount pending · ${_bids.length} total',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBids,
          ),
        ],
      ),
      body: Column(
        children: [
          // Job summary card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.work_outline,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _job.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _job.location,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (_job.budgetRwf != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Budget',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.textSecondary)),
                      Text(
                        '${_fmt(_job.budgetRwf!)} RWF',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Bids list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bids.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadBids,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _bids.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildBidCard(_bids[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text('No bids yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          Text('Artisans will bid on your job soon.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBidCard(Bid bid) {
    final isActing = _actingOnId == bid.id;
    final isPending = bid.status == BidStatus.pending;
    final isAccepted = bid.status == BidStatus.accepted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAccepted
            ? AppTheme.success.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAccepted
              ? AppTheme.success.withValues(alpha: 0.4)
              : isPending
                  ? AppTheme.primary.withValues(alpha: 0.2)
                  : Colors.grey.shade200,
        ),
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
          // Artisan row
          Row(
            children: [
              _buildAvatar(bid),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bid.artisanName ?? 'Artisan',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (bid.artisanTrade != null)
                      Text(bid.artisanTrade!,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              if (bid.artisanRating != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star,
                          size: 13, color: AppTheme.secondary),
                      const SizedBox(width: 3),
                      Text(
                        bid.artisanRating!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Amount
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${_fmt(bid.amountRwf)} RWF',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),

          // Note
          if (bid.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bid.note,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
          ],

          const SizedBox(height: 14),

          // Action area
          if (isAccepted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                  SizedBox(width: 6),
                  Text('Accepted — Artisan Booked',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success)),
                ],
              ),
            )
          else if (!isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('Not Selected',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ),
            )
          else if (isActing)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectBid(bid),
                    icon: const Icon(Icons.close, size: 16,
                        color: AppTheme.error),
                    label: const Text('Decline',
                        style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptBid(bid),
                    icon: const Icon(Icons.check, size: 16,
                        color: Colors.white),
                    label: const Text('Accept',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Bid bid) {
    final url = bid.artisanAvatarUrl;
    final name = bid.artisanName ?? 'A';
    final fallback = CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
      child: Text(
        name[0],
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );

    if (url == null || url.isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
