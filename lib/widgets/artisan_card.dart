import 'package:flutter/material.dart';
import 'package:quickfix/models/artisan.dart';
import 'package:quickfix/theme/app_theme.dart';

// Custom reusable widget — covers C3
class ArtisanCard extends StatelessWidget {
  final Artisan artisan;
  final VoidCallback onTap;

  const ArtisanCard({
    super.key,
    required this.artisan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artisan photo and availability badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: artisan.profileImageUrl != null
                        ? Image.asset(
                            artisan.profileImageUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                CircleAvatar(
                              radius: 36,
                              backgroundColor:
                                  AppTheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                artisan.name[0],
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 36,
                            backgroundColor:
                                AppTheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              artisan.name[0],
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                  ),
                  if (artisan.isAvailable)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Artisan name
              Text(
                artisan.name.split(' ').first,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Trade
              Text(
                artisan.trade,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              // Rating row
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 14,
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    artisan.rating.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Price
              Text(
                'From ${artisan.startingPrice.toString()} RWF',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Availability badge
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: artisan.isAvailable
                      ? AppTheme.success.withValues(alpha:0.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  artisan.isAvailable ? 'Available Now' : 'Unavailable',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: artisan.isAvailable
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}