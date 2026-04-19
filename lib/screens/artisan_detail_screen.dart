import 'package:flutter/material.dart';
import 'package:quickfix/data/dummy_data.dart';
import 'package:quickfix/models/artisan.dart';
import 'package:quickfix/models/review.dart';
import 'package:quickfix/theme/app_theme.dart';
import 'package:quickfix/widgets/review_card.dart';

class ArtisanDetailScreen extends StatefulWidget {
  const ArtisanDetailScreen({super.key});

  @override
  State<ArtisanDetailScreen> createState() => _ArtisanDetailScreenState();
}

class _ArtisanDetailScreenState extends State<ArtisanDetailScreen> {
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  bool _showFullAbout = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Covers D2 — receiving data passed from home screen
    final artisan =
        ModalRoute.of(context)!.settings.arguments as VerifiedArtisan;
    _loadReviews(artisan.id);
  }

  // Covers B5 — async/await
  Future<void> _loadReviews(String artisanId) async {
    final reviews = await fetchReviewsForArtisan(artisanId);
    setState(() {
      _reviews = reviews;
      _isLoadingReviews = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Covers D2 — data received via route arguments
    final artisan =
        ModalRoute.of(context)!.settings.arguments as VerifiedArtisan;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image with back button — covers C2 (Stack)
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: AppTheme.primary),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite_border,
                      color: AppTheme.secondary),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  artisan.profileImageUrl != null
                      ? Image.asset(
                          artisan.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            child: Center(
                              child: CircleAvatar(
                                radius: 64,
                                backgroundColor:
                                    AppTheme.primary.withValues(alpha: 0.2),
                                child: Text(
                                  artisan.name[0],
                                  style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          child: Center(
                            child: CircleAvatar(
                              radius: 64,
                              backgroundColor:
                                  AppTheme.primary.withValues(alpha: 0.2),
                              child: Text(
                                artisan.name[0],
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                  // Dark gradient overlay at bottom
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
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artisan identity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artisan.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              artisan.trade,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 2),
                                Text(
                                  artisan.location,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Availability badge — covers A4 (ternary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: artisan.isAvailable
                              ? AppTheme.success.withValues(alpha:0.1)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          artisan.isAvailable
                              ? '● Available Now'
                              : '● Unavailable',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: artisan.isAvailable
                                ? AppTheme.success
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Stats row — covers C2 (Row)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          value: '${artisan.rating}★',
                          label: 'Rating',
                          color: AppTheme.secondary,
                        ),
                        _StatItem(
                          value: '${artisan.completedJobs}',
                          label: 'Jobs Done',
                          color: AppTheme.primary,
                        ),
                        _StatItem(
                          value: '${artisan.yearsOfExperience} yrs',
                          label: 'Experience',
                          color: AppTheme.success,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Skills chips
                  const Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: artisan.skills
                        .map(
                          (skill) => Chip(
                            label: Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                              ),
                            ),
                            backgroundColor:
                                AppTheme.primary.withValues(alpha:0.08),
                            side: BorderSide(
                                color: AppTheme.primary.withValues(alpha:0.3)),
                            padding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  // About section
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artisan.about,
                    maxLines: _showFullAbout ? null : 3,
                    overflow: _showFullAbout
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showFullAbout = !_showFullAbout),
                    child: Text(
                      _showFullAbout ? 'Show less' : 'Read more',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Verification badge
                  if (artisan.isRecentlyVerified)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha:0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.success.withValues(alpha:0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified,
                              color: AppTheme.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Verified artisan — ID: ${artisan.verificationId}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Reviews section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${artisan.totalReviews} total',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Reviews list — covers C2 (ListView)
                  _isLoadingReviews
                      ? const Center(child: CircularProgressIndicator())
                      : _reviews.isEmpty
                          ? const Text(
                              'No reviews yet.',
                              style:
                                  TextStyle(color: AppTheme.textSecondary),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _reviews.length,
                              itemBuilder: (context, index) =>
                                  ReviewCard(review: _reviews[index]),
                            ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky bottom bar — Book Now button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Starting from',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${artisan.startingPrice} RWF',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/booking-form',
                  arguments: artisan,
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Private stat item widget
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}