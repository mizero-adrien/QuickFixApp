import 'package:flutter/material.dart';
import 'package:quickfix/data/dummy_data.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/theme/app_theme.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  List<Job> _jobs = [];
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
      : _jobs
          .where((j) => j.categoryLabel == _selectedFilter)
          .toList();

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  // Covers B5 — async/await
  Future<void> _loadJobs() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _jobs = dummyJobs;
      _isLoading = false;
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Jobs',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
                                        color:
                                            _selectedFilter == entry.key
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
                              return _JobCard(
                                job: job,
                                statusColor: _statusColor(job.status),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Reusable job card widget — covers C3
class _JobCard extends StatelessWidget {
  final Job job;
  final Color statusColor;

  const _JobCard({
    required this.job,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha:0.08),
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
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.1),
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

            const SizedBox(height: 10),

            // Job title
            Text(
              job.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            // Description
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

            // Location and date row
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

            // Budget and bid button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Budget
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

                // Send bid button
                ElevatedButton(
                  onPressed: () =>
                      _showBidDialog(context, job),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Send Bid',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBidDialog(BuildContext context, Job job) {
    final bidController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
              job.title,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Bid amount
            const Text(
              'Your Price (RWF)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 8000',
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

            // Note
            const Text(
              'Note to Homeowner',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
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

            // Submit bid button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '✅ Bid sent successfully!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
              child: const Text(
                'Submit Bid',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}