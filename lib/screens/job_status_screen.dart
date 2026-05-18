import 'package:flutter/material.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';

// One entry in the visual stepper
class _StepDef {
  final JobStatus status;
  final String label;
  final String description;
  final IconData icon;
  const _StepDef(this.status, this.label, this.description, this.icon);
}

class JobStatusScreen extends StatefulWidget {
  const JobStatusScreen({super.key});

  @override
  State<JobStatusScreen> createState() => _JobStatusScreenState();
}

class _JobStatusScreenState extends State<JobStatusScreen>
    with SingleTickerProviderStateMixin {
  Job? _job;
  bool _isLoading = true;
  bool _isUpdating = false;
  late AnimationController _pulse;

  static const _steps = [
    _StepDef(JobStatus.requested,  'Requested',   'Job posted by homeowner',        Icons.post_add_outlined),
    _StepDef(JobStatus.quoted,     'Quoted',       'Artisan bids received',          Icons.request_quote_outlined),
    _StepDef(JobStatus.booked,     'Booked',       'Bid accepted, artisan confirmed', Icons.handshake_outlined),
    _StepDef(JobStatus.onTheWay,   'On The Way',   'Artisan heading to location',    Icons.directions_run_outlined),
    _StepDef(JobStatus.inProgress, 'In Progress',  'Work has started',               Icons.construction_outlined),
    _StepDef(JobStatus.completed,  'Completed',    'Job finished successfully',      Icons.check_circle_outline),
  ];

  // DB order index for each status (cancelled excluded from stepper)
  static const _order = {
    JobStatus.requested:  0,
    JobStatus.quoted:     1,
    JobStatus.booked:     2,
    JobStatus.onTheWay:   3,
    JobStatus.inProgress: 4,
    JobStatus.completed:  5,
  };

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final jobId = ModalRoute.of(context)!.settings.arguments as String;
    _load(jobId);
  }

  Future<void> _load(String jobId) async {
    try {
      final job = await SupabaseService.getJobById(jobId);
      if (mounted) setState(() => _job = job);
    } catch (e) {
      debugPrint('[JobStatus] Load failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _advance(JobStatus next) async {
    if (_job == null) return;
    setState(() => _isUpdating = true);
    try {
      await SupabaseService.updateJobStatus(_job!.id, next);
      await _load(_job!.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _markComplete() async {
    if (_job == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark Job Complete?'),
        content: const Text(
          'Confirm the work has been finished successfully.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not Yet')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SupabaseService.markJobComplete(
        jobId: _job!.id,
        artisanId: _job!.assignedArtisanId,
        jobTitle: _job!.title,
      );
      await SupabaseService.refreshArtisanSession();
      await _load(_job!.id);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArtisan = UserSession.userType == UserType.artisan;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Job Status',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_job != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _load(_job!.id),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _job == null
              ? _buildError()
              : _buildContent(isArtisan),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Could not load job status.',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isArtisan) {
    final job = _job!;
    final currentIdx = _order[job.status] ?? 0;

    return Column(
      children: [
        // ── Job summary card ───────────────────────────────────────────
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  _StatusBadge(status: job.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.category_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(job.categoryLabel,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(job.location,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              if (job.budgetRwf != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 14, color: AppTheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${job.budgetRwf!.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} RWF',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // ── Visual stepper ─────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: List.generate(_steps.length, (i) {
                final step = _steps[i];
                final isDone = currentIdx > i;
                final isCurrent = currentIdx == i;
                final isLast = i == _steps.length - 1;
                return _buildStep(
                  step: step,
                  isDone: isDone,
                  isCurrent: isCurrent,
                  isLast: isLast,
                );
              }),
            ),
          ),
        ),

        // ── Action buttons ─────────────────────────────────────────────
        if (job.status != JobStatus.completed &&
            job.status != JobStatus.cancelled)
          _buildActions(isArtisan, job),
      ],
    );
  }

  Widget _buildStep({
    required _StepDef step,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
  }) {
    final Color circleColor;
    final Color lineColor;
    final Widget circleChild;

    if (isDone) {
      circleColor = AppTheme.success;
      lineColor = AppTheme.success;
      circleChild = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (isCurrent) {
      circleColor = AppTheme.primary;
      lineColor = Colors.grey.shade200;
      circleChild = AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white
                .withValues(alpha: 0.6 + _pulse.value * 0.4),
            shape: BoxShape.circle,
          ),
        ),
      );
    } else {
      circleColor = Colors.grey.shade300;
      lineColor = Colors.grey.shade200;
      circleChild = Icon(step.icon, color: Colors.grey.shade400, size: 16);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Center(child: circleChild),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),

          // Step info
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                bottom: isLast ? 0 : 20,
                top: 6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: isDone || isCurrent
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDone || isCurrent
                          ? AppTheme.textSecondary
                          : Colors.grey.shade400,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Current status',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isArtisan, Job job) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _isUpdating
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isArtisan) ..._artisanActions(job)
                else ..._homeownerActions(job),
              ],
            ),
    );
  }

  List<Widget> _artisanActions(Job job) {
    if (job.status == JobStatus.booked) {
      return [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _advance(JobStatus.onTheWay),
            icon: const Icon(Icons.directions_run),
            label: const Text("I'm On My Way",
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ];
    }
    if (job.status == JobStatus.onTheWay) {
      return [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _advance(JobStatus.inProgress),
            icon: const Icon(Icons.construction),
            label: const Text('Work Started',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ];
    }
    if (job.status == JobStatus.inProgress) {
      return [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _markComplete,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark Complete',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ];
    }
    return [];
  }

  List<Widget> _homeownerActions(Job job) {
    if (job.status == JobStatus.booked ||
        job.status == JobStatus.onTheWay ||
        job.status == JobStatus.inProgress) {
      return [
        const Text(
          'Waiting for artisan to update progress...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _markComplete,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark Complete',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ];
    }
    return [];
  }
}

String _labelFor(JobStatus s) {
  switch (s) {
    case JobStatus.requested:  return 'Requested';
    case JobStatus.quoted:     return 'Quoted';
    case JobStatus.booked:     return 'Booked';
    case JobStatus.onTheWay:   return 'On The Way';
    case JobStatus.inProgress: return 'In Progress';
    case JobStatus.completed:  return 'Completed';
    case JobStatus.cancelled:  return 'Cancelled';
  }
}

class _StatusBadge extends StatelessWidget {
  final JobStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case JobStatus.requested:
        color = Colors.blue;
      case JobStatus.quoted:
        color = Colors.orange;
      case JobStatus.booked:
        color = AppTheme.primary;
      case JobStatus.onTheWay:
        color = Colors.indigo;
      case JobStatus.inProgress:
        color = Colors.orange;
      case JobStatus.completed:
        color = AppTheme.success;
      case JobStatus.cancelled:
        color = AppTheme.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Text(
            _labelFor(status),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
