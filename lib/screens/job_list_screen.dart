import 'package:flutter/material.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';

class JobListScreen extends StatefulWidget {
  final VoidCallback? onBidPosted;

  const JobListScreen({super.key, this.onBidPosted});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  List<Job> _jobs = [];
  Set<String> _bidJobIds = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';

  // Covers A3 — Map
  final Map<String, String> _filters = {
    'All': '📋',
    'Plumbing': '🔧',
    'Electrical': '⚡',
    'Painting': '🎨',
    'Carpentry': '🪚',
    'Cleaning': '🧹',
    'Masonry': '🧱',
  };

  // Covers A2 — arrow function
  List<Job> get _filteredJobs => _selectedFilter == 'All'
      ? _jobs
      : _jobs.where((j) => j.categoryLabel == _selectedFilter).toList();

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  // Covers B5 — async/await
  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('[JobList] Loading open jobs from Supabase...');
      final jobs = await SupabaseService.getOpenJobs();
      debugPrint('[JobList] Loaded ${jobs.length} real jobs from Supabase');

      Set<String> bidIds = {};
      final artisanId = UserSession.currentArtisan?.id ??
          SupabaseService.currentUser?.id;
      if (artisanId != null) {
        bidIds = await SupabaseService.getArtisanBidJobIds(artisanId);
      }

      if (mounted) setState(() {
        _jobs = jobs;
        _bidJobIds = bidIds;
      });
    } catch (e) {
      debugPrint('[JobList] Supabase error: $e');
      if (mounted) setState(() => _jobs = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Covers A4 — switch for status color
  Color _statusColor(JobStatus status) {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              children: _filters.entries
                  .map(
                    (entry) => GestureDetector(
                      onTap: () => setState(
                          () => _selectedFilter = entry.key),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedFilter == entry.key
                              ? AppTheme.primary
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(24),
                          border: Border.all(
                            color: _selectedFilter == entry.key
                                ? AppTheme.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(entry.value,
                                style: const TextStyle(
                                    fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedFilter == entry.key
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Job count
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredJobs.length} jobs available',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Jobs list — covers C2 (ListView)
          Expanded(
            child: _filteredJobs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('📋',
                            style: TextStyle(fontSize: 48)),
                        SizedBox(height: 16),
                        Text(
                          'No jobs available\nin this category',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredJobs.length,
                    itemBuilder: (context, index) {
                      // Covers A1 — final variable
                      final job = _filteredJobs[index];
                      final hasBid = _bidJobIds.contains(job.id);
                      return _JobCard(
                        job: job,
                        hasBid: hasBid,
                        statusColor: _statusColor(job.status),
                        onTap: () async {
                          final bidPosted = await Navigator.pushNamed(
                            context,
                            '/job-detail',
                            arguments: {'job': job, 'hasBid': hasBid},
                          );
                          if (bidPosted == true) {
                            _loadJobs();
                            widget.onBidPosted?.call();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Reusable job card widget — covers C3
class _JobCard extends StatelessWidget {
  final Job job;
  final bool hasBid;
  final Color statusColor;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.hasBid,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.categoryLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (hasBid) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 11, color: AppTheme.success),
                            SizedBox(width: 4),
                            Text(
                              'Bid Sent',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        job.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              job.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${job.requestedAt.day}/${job.requestedAt.month}/${job.requestedAt.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      job.budgetRwf != null
                          ? '${job.budgetRwf} RWF'
                          : 'Negotiable',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onTap,
                  icon: Icon(
                    hasBid ? Icons.visibility_outlined : Icons.arrow_forward,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    hasBid ? 'View Bid' : 'View Details',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        hasBid ? AppTheme.success : AppTheme.primary,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),   // Card
    );   // GestureDetector
  }
}

