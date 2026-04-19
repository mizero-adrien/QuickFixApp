import 'package:flutter/material.dart';
import 'package:quickfix/data/dummy_data.dart';
import 'package:quickfix/models/artisan.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/theme/app_theme.dart';
import 'package:quickfix/widgets/artisan_card.dart';
import 'package:quickfix/widgets/category_chip.dart';
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
        return _buildHomeownerHome();
      case 1:
        return _buildSearchScreen();
      case 2:
        return _buildMyJobsScreen();
      case 3:
        return _buildProfileScreen();
      default:
        return _buildHomeownerHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Covers A1 — final variable, null safety
    final isArtisan = UserSession.userType == UserType.artisan;
    final userName = isArtisan
        ? UserSession.currentArtisan?.name.split(' ').first ?? 'Artisan'
        : UserSession.currentHomeowner?.name.split(' ').first ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'QuickFix',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              isArtisan ? 'Artisan Dashboard' : 'Gasabo, Kigali',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
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
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline),
                  activeIcon: Icon(Icons.work),
                  label: 'Jobs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.gavel_outlined),
                  activeIcon: Icon(Icons.gavel),
                  label: 'My Bids',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
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
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline),
                  activeIcon: Icon(Icons.work),
                  label: 'My Jobs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }

  // Homeowner home view
  Widget _buildHomeownerHome() {
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
                          'Hello, $userName! 👋',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Find a trusted artisan\nnear you today.',
                          style: TextStyle(
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

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for a plumber, electrician...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.textSecondary,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
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
                        'All',
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

            // Available Near You
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Near You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),

            // Artisan grid — covers C2 (GridView)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _filteredArtisans.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No artisans found for this category.',
                          style:
                              TextStyle(color: AppTheme.textSecondary),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Top Rated This Week',
                style: TextStyle(
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
                                      style:
                                          const TextStyle(fontSize: 11),
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
  Widget _buildSearchScreen() {
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
  Widget _buildMyJobsScreen() {
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
  Widget _buildProfileScreen() {
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

  // Artisan bids screen
  Widget _buildArtisanBids() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🤝', style: TextStyle(fontSize: 48)),
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
            'Bids you have sent will appear here',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // Artisan profile screen
  Widget _buildArtisanProfile() {
    final artisan = UserSession.currentArtisan;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile photo with camera icon
          Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor:
                    AppTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  artisan?.name[0] ?? 'A',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
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
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // Verified badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: AppTheme.success, size: 16),
                SizedBox(width: 4),
                Text(
                  'Verified Artisan',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats row
          Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '${artisan?.rating ?? 0.0}★',
                  'Rating',
                  AppTheme.secondary,
                ),
                _buildStatItem(
                  '${artisan?.completedJobs ?? 0}',
                  'Jobs Done',
                  AppTheme.primary,
                ),
                _buildStatItem(
                  '${artisan?.yearsOfExperience ?? 0} yrs',
                  'Experience',
                  AppTheme.success,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Skills
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'Skills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (artisan?.skills ?? [])
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
                        AppTheme.primary.withValues(alpha: 0.08),
                    side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                    padding: EdgeInsets.zero,
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 24),

          // About
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            artisan?.about ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          // Starting price
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Starting Price',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${artisan?.startingPrice ?? 0} RWF',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Edit profile button
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.primary),
            label: const Text(
              'Edit Profile',
              style: TextStyle(color: AppTheme.primary),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Logout button
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
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppTheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Artisan settings screen
  Widget _buildArtisanSettings() {
    final artisan = UserSession.currentArtisan;
    bool isAvailable = artisan?.isAvailable ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Availability toggle
          Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available for Jobs',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      isAvailable
                          ? 'You are visible to homeowners'
                          : 'You are hidden from homeowners',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isAvailable,
                  activeColor: AppTheme.success,
                  onChanged: (value) =>
                      setState(() => isAvailable = value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Notifications setting
          Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Notifications',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Get notified when new jobs are posted',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: true,
                  activeColor: AppTheme.primary,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Account info
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                    Icons.person_outline, 'Name', artisan?.name ?? ''),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.phone_outlined, 'Phone',
                    artisan?.phoneNumber ?? ''),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on_outlined, 'Location',
                    artisan?.location ?? ''),
                const SizedBox(height: 12),
                _buildInfoRow(
                    Icons.work_outline, 'Trade', artisan?.trade ?? ''),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout
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
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppTheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildStatItem(String value, String label, Color color) {
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}