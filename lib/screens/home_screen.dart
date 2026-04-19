import 'package:flutter/material.dart';
import 'package:quickfix/data/dummy_data.dart';
import 'package:quickfix/models/artisan.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/l10n/app_localizations.dart';
import 'package:quickfix/theme/app_theme.dart';
import 'package:quickfix/widgets/artisan_card.dart';
import 'package:quickfix/widgets/category_chip.dart';
import 'package:quickfix/widgets/language_selector.dart';
import 'package:quickfix/screens/job_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  List<VerifiedArtisan> _artisans = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Covers A2 — arrow function
  List<VerifiedArtisan> get _filteredArtisans => _selectedCategory == 'All'
      ? _artisans
      : _artisans
          .where((a) => a.trade == _selectedCategory)
          .toList();

  @override
  void initState() {
    super.initState();
    _loadArtisans();
  }

  // Covers B5 — async/await Future
  Future<void> _loadArtisans() async {
    final artisans = await fetchArtisans();
    setState(() {
      _artisans = artisans;
      _isLoading = false;
    });
  }

  // Covers A4 — switch for bottom nav
  Widget _getBody() {
    // Covers A4 — if/else based on user type
    if (UserSession.userType == UserType.artisan) {
      switch (_currentIndex) {
        case 0:
          return const JobListScreen();
        case 1:
          return _buildArtisanBids();
        case 2:
          return _buildArtisanProfile();
        case 3:
          return _buildArtisanSettings();
        default:
          return const JobListScreen();
      }
    }

    switch (_currentIndex) {
      case 0:
        return _buildHomeownerHome(context);
      case 1:
        return _buildSearchScreen(context);
      case 2:
        return _buildMyJobsScreen(context);
      case 3:
        return _buildProfileScreen(context);
      default:
        // FIX 1: was _buildHomeownerHome() — missing required context argument
        return _buildHomeownerHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    // Covers A1 — final variable, null safety
    final isArtisan = UserSession.userType == UserType.artisan;
    final userName = isArtisan
        ? UserSession.currentArtisan?.name.split(' ').first ?? 'Artisan'
        : UserSession.currentHomeowner?.name.split(' ').first ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              localizations.appTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              isArtisan
                  ? localizations.artisanDashboard
                  : localizations.gasaboKigali,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          const LanguageSelector(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              UserSession.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _getBody(),

      // FAB for homeowner to post a job
      floatingActionButton: !isArtisan
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, '/post-job'),
              backgroundColor: AppTheme.secondary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Post a Job',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,

      bottomNavigationBar: isArtisan
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textSecondary,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.work_outline),
                  activeIcon: const Icon(Icons.work),
                  label: localizations.jobs,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.gavel_outlined),
                  activeIcon: const Icon(Icons.gavel),
                  label: 'My Bids',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: localizations.profile,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textSecondary,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: localizations.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.search),
                  label: localizations.search,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.work_outline),
                  activeIcon: const Icon(Icons.work),
                  label: localizations.jobs,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: localizations.profile,
                ),
              ],
            ),
    );
  }

  // Homeowner home view
  Widget _buildHomeownerHome(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final userName =
        UserSession.currentHomeowner?.name.split(' ').first ?? 'User';
    return RefreshIndicator(
      onRefresh: _loadArtisans,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.goodMorning(userName),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations.findTrustedArtisans,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                      'assets/images/generalworker.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text('🔧', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Category chips — covers C2 (Row)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = 'All'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedCategory == 'All'
                            ? AppTheme.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _selectedCategory == 'All'
                              ? AppTheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        localizations.all,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedCategory == 'All'
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  ...categoryIcons.entries.map(
                    (entry) => CategoryChip(
                      label: entry.key,
                      icon: entry.value,
                      isSelected: _selectedCategory == entry.key,
                      onTap: () => setState(
                          () => _selectedCategory = entry.key),
                    ),
                  ),
                ],
              ),
            ),

            // Featured artisan card
            if (_artisans.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          _artisans.first.name[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _artisans.first.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              _artisans.first.trade,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ...List.generate(
                                    5,
                                    (index) => Icon(
                                          index <
                                                  _artisans.first.rating
                                                      .floor()
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 14,
                                          color: AppTheme.secondary,
                                        )),
                                const SizedBox(width: 4),
                                Text(
                                  '${_artisans.first.rating} (${_artisans.first.completedJobs} jobs)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          localizations.availableNow,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Available Near You
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Verified Artisans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(localizations.seeAll),
                  ),
                ],
              ),
            ),

            // Artisan grid — covers C2 (GridView)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _filteredArtisans.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          // FIX 2: noArtisansFound getter added to AppLocalizations
                          localizations.noArtisansFound,
                          style: const TextStyle(
                              color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.75,
                      children: _filteredArtisans
                          .map(
                            (artisan) => ArtisanCard(
                              artisan: artisan,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/artisan-detail',
                                arguments: artisan,
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),

            // Top Rated
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                localizations.topRatedThisWeek,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),

            // Horizontal ListView — covers C2 (ListView)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _artisans.length,
                itemBuilder: (context, index) {
                  final artisan = _artisans[index];
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/artisan-detail',
                      arguments: artisan,
                    ),
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: artisan.profileImageUrl != null
                                ? Image.asset(
                                    artisan.profileImageUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppTheme.primary
                                          .withValues(alpha: 0.1),
                                      child: Text(
                                        artisan.name[0],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        AppTheme.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      artisan.name[0],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  artisan.name.split(' ').first,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  artisan.trade,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 12,
                                        color: AppTheme.secondary),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${artisan.rating} (${artisan.completedJobs} jobs)',
                                      style: const TextStyle(
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // Search screen placeholder
  Widget _buildSearchScreen(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔍', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            'Search Screen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // My Jobs screen placeholder
  Widget _buildMyJobsScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'My Jobs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your posted jobs will appear here',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/post-job'),
            icon: const Icon(Icons.add),
            label: const Text('Post a Job'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 48),
            ),
          ),
        ],
      ),
    );
  }

  // Homeowner profile screen
  Widget _buildProfileScreen(BuildContext context) {
    final homeowner = UserSession.currentHomeowner;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Text(
              homeowner?.name[0] ?? 'U',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            homeowner?.name ?? 'User',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            homeowner?.email ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              homeowner?.districtLabel ?? 'Kigali',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/homeowner-edit-profile',
            ),
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.primary),
            label: const Text(
              'Edit Profile',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              UserSession.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout, color: AppTheme.error),
            label: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.error),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(200, 48),
              side: const BorderSide(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  // Artisan placeholder screens
  Widget _buildArtisanBids() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎯', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            'My Bids',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your active bids will appear here',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisanProfile() {
    final artisan = UserSession.currentArtisan;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Text(
              artisan?.name[0] ?? 'A',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            artisan?.name ?? 'Artisan',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            artisan?.trade ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/artisan-edit-profile',
            ),
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.primary),
            label: const Text(
              'Edit Profile',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              UserSession.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout, color: AppTheme.error),
            label: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.error),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(200, 48),
              side: const BorderSide(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisanSettings() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('⚙️', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Settings coming soon',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
