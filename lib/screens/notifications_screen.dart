import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quickfix/models/app_notification.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _actingOnId;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  void _subscribe() {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    _channel = SupabaseService.subscribeToNotifications(userId, _load);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final notifications = await SupabaseService.getNotifications(userId);
      if (mounted) setState(() => _notifications = notifications);
    } catch (e) {
      debugPrint('[Notifications] Load failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    await SupabaseService.markAllRead(userId);
    setState(() {
      _notifications = _notifications
          .map((n) => AppNotification(
                id: n.id,
                userId: n.userId,
                type: n.type,
                title: n.title,
                body: n.body,
                data: n.data,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
    });
  }

  Future<void> _onTapNotification(AppNotification n) async {
    if (!n.isRead) {
      await SupabaseService.markNotificationRead(n.id);
      setState(() {
        final idx = _notifications.indexWhere((x) => x.id == n.id);
        if (idx != -1) {
          _notifications[idx] = AppNotification(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            body: n.body,
            data: n.data,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
      });
    }
  }

  Future<void> _confirmBooking(AppNotification n) async {
    setState(() => _actingOnId = n.id);
    try {
      await SupabaseService.markNotificationRead(n.id);
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((x) => x.id == n.id);
          if (idx != -1) {
            _notifications[idx] = AppNotification(
              id: n.id, userId: n.userId, type: n.type, title: n.title,
              body: n.body, data: n.data, isRead: true, createdAt: n.createdAt,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed! The homeowner will be notified.'),
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

  Future<void> _declineBooking(AppNotification n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Decline Booking?'),
        content: const Text(
          'The job will be reopened and the homeowner will be notified to choose another bid.',
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

    setState(() => _actingOnId = n.id);
    try {
      final artisanName = UserSession.currentArtisan?.name ?? 'The artisan';
      await SupabaseService.declineBooking(
        jobId: n.data['job_id'] as String,
        bidId: n.data['bid_id'] as String,
        homeownerId: n.data['homeowner_id'] as String,
        artisanName: artisanName,
        jobTitle: n.data['job_title'] as String?,
      );
      await SupabaseService.markNotificationRead(n.id);
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((x) => x.id == n.id);
          if (idx != -1) {
            _notifications[idx] = AppNotification(
              id: n.id, userId: n.userId, type: 'booking_declined_by_me',
              title: 'Booking Declined', body: 'You declined this booking.',
              data: n.data, isRead: true, createdAt: n.createdAt,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking declined. The homeowner has been notified.'),
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
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Notifications',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (unread > 0)
              Text('$unread unread',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _buildCard(_notifications[index]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text('No notifications yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          Text('You\'ll be notified about bids and bookings here.',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCard(AppNotification n) {
    final isActing = _actingOnId == n.id;
    final color = _colorFor(n.type);
    final icon = _iconFor(n.type);

    return GestureDetector(
      onTap: () => _onTapNotification(n),
      child: Container(
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead
                ? Colors.grey.shade200
                : color.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: n.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.body,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeAgo(n.createdAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Accept / Decline buttons for artisan booking notifications
            if (n.type == 'bid_accepted' && !n.isRead) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              isActing
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _declineBooking(n),
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
                            onPressed: () => _confirmBooking(n),
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
      ),
    );
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'new_bid':
        return AppTheme.primary;
      case 'bid_accepted':
        return AppTheme.success;
      case 'bid_rejected':
        return AppTheme.error;
      case 'booking_declined':
        return Colors.orange;
      case 'job_invitation':
        return AppTheme.primary;
      case 'invitation_accepted':
        return AppTheme.success;
      case 'invitation_declined':
        return AppTheme.error;
      case 'job_completed':
        return AppTheme.success;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'new_bid':
        return Icons.gavel;
      case 'bid_accepted':
        return Icons.verified_outlined;
      case 'bid_rejected':
        return Icons.cancel_outlined;
      case 'booking_declined':
        return Icons.person_off_outlined;
      case 'job_invitation':
        return Icons.mail_outline_rounded;
      case 'invitation_accepted':
        return Icons.check_circle_outline;
      case 'invitation_declined':
        return Icons.cancel_outlined;
      case 'job_completed':
        return Icons.task_alt;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
