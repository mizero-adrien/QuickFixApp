import 'package:flutter/material.dart';
import 'package:quickfix/models/artisan.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';
import 'package:quickfix/widgets/artisan_card.dart';

class FavoritesScreen extends StatefulWidget {
  final Set<String> favoriteIds;
  final void Function(String artisanId) onToggle;

  const FavoritesScreen({
    super.key,
    required this.favoriteIds,
    required this.onToggle,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<VerifiedArtisan> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final homeownerId = UserSession.currentHomeowner?.id;
    if (homeownerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final list = await SupabaseService.getFavoriteArtisans(homeownerId);
      if (mounted) setState(() => _favorites = list);
    } catch (e) {
      debugPrint('[Favorites] Failed to load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleToggle(VerifiedArtisan artisan) {
    widget.onToggle(artisan.id);
    setState(() => _favorites.removeWhere((a) => a.id == artisan.id));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the heart on an artisan card\nto save them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '${_favorites.length} saved artisan${_favorites.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              childAspectRatio: 0.75,
              children: _favorites.map((artisan) {
                return ArtisanCard(
                  artisan: artisan,
                  isFavorite: true,
                  onFavoriteToggle: () => _handleToggle(artisan),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/artisan-detail',
                    arguments: artisan,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
