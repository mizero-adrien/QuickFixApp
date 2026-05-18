import 'package:flutter/material.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/models/artisan.dart';
import 'package:quickfix/models/bid.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/l10n/app_localizations.dart';
import 'package:quickfix/theme/app_theme.dart';
import 'package:quickfix/widgets/artisan_card.dart';
import 'package:quickfix/widgets/category_chip.dart';
import 'package:quickfix/widgets/language_selector.dart';
import 'package:quickfix/screens/job_list_screen.dart';
import 'package:quickfix/screens/invitations_screen.dart';

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
  List<Job> _myJobs = [];
  bool _isLoadingJobs = false;
  List<Bid> _myBids = [];
  bool _isLoadingBids = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchCategory = 'All';
  bool _isAvailable = true;
  String _selectedBidFilter = 'All';
  int _unreadCount = 0;
  int _pendingInvitations = 0;

  // Covers A2 — arrow function
  List<VerifiedArtisan> get _filteredArtisans {
    if (_selectedCategory == 'All') return _artisans;
    final trade = _categoryToTrade[_selectedCategory] ?? _selectedCategory;
    return _artisans
        .where((a) => a.trade.toLowerCase() == trade.toLowerCase())
        .toList();
  }

  List<VerifiedArtisan> get _searchResults {
    final hasQuery = _searchQuery.isNotEmpty;
    final hasFilter = _searchCategory != 'All';
    if (!hasQuery && !hasFilter) return [];
    final q = _searchQuery.toLowerCase();
    final trade = (_categoryToTrade[_searchCategory] ?? _searchCategory).toLowerCase();
    return _artisans.where((a) {
      final matchesQuery = !hasQuery ||
          a.name.toLowerCase().contains(q) ||
          a.trade.toLowerCase().contains(q) ||
          a.skills.any((s) => s.toLowerCase().contains(q));
      final matchesCategory = !hasFilter || a.trade.toLowerCase() == trade;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (UserSession.userType == UserType.artisan) {
      _isLoading = false;
      _isAvailable = UserSession.currentArtisan?.isAvailable ?? true;
      _loadMyBids();
      _loadPendingInvitations();
    } else {
      _loadArtisans();
      _loadMyJobs();
    }
    _loadUnreadCount();
  }

  Future<void> _loadPendingInvitations() async {
    final artisanId = UserSession.currentArtisan?.id
        ?? SupabaseService.currentUser?.id;
    if (artisanId == null) return;
    try {
      final invitations = await SupabaseService.getInvitationsForArtisan(artisanId);
      final pending = invitations.where((j) => j.status == JobStatus.requested).length;
      if (mounted) setState(() => _pendingInvitations = pending);
    } catch (_) {}
  }

  Future<void> _loadUnreadCount() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    try {
      final count = await SupabaseService.getUnreadCount(userId);
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const Map<String, String> categoryIcons = {
    'Plumbing': '🔧',
    'Electrical': '⚡',
    'Painting': '🎨',
    'Carpentry': '🪚',
    'Cleaning': '🧹',
    'Masonry': '🧱',
  };

  // Maps UI category labels → DB trade values stored by artisan setup/edit
  static const Map<String, String> _categoryToTrade = {
    'Plumbing': 'Plumber',
    'Electrical': 'Electrician',
    'Painting': 'Painter',
    'Carpentry': 'Carpenter',
    'Cleaning': 'Cleaner',
    'Masonry': 'Mason',
  };

  // Covers B5 — async/await Future
  Future<void> _loadArtisans() async {
    if (UserSession.userType == UserType.artisan) {
      debugPrint('[Home] Artisan user — skipping artisan list load');
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      debugPrint('[Home] Loading artisans from Supabase...');
      final artisans = await SupabaseService.getArtisans();
      debugPrint('[Home] Loaded ${artisans.length} artisans from Supabase');
      if (mounted) setState(() => _artisans = artisans);
    } catch (e) {
      debugPrint('[Home] Failed to load artisans: $e');
      if (mounted) setState(() => _artisans = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMyBids() async {
    final artisanId = UserSession.currentArtisan?.id
        ?? SupabaseService.currentUser?.id;
    if (artisanId == null) {
      debugPrint('[Home] _loadMyBids: artisan ID is null — skipping');
      return;
    }
    debugPrint('[Home] Loading bids for artisan $artisanId...');
    setState(() => _isLoadingBids = true);
    try {
      final bids = await SupabaseService.getBidsByArtisan(artisanId);
      debugPrint('[Home] Loaded ${bids.length} bids');
      if (mounted) setState(() => _myBids = bids);
    } catch (e) {
      debugPrint('[Home] _loadMyBids failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load bids: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingBids = false);
    }
  }

  Future<void> _loadMyJobs() async {
    final homeownerId = UserSession.currentHomeowner?.id;
    if (homeownerId == null) {
      debugPrint('[Home] _loadMyJobs: homeowner ID is null — skipping');
      return;
    }
    setState(() => _isLoadingJobs = true);
    try {
      debugPrint('[Home] Loading jobs for homeowner $homeownerId...');
      final jobs = await SupabaseService.getJobsByHomeowner(homeownerId);
      debugPrint('[Home] Loaded ${jobs.length} jobs for homeowner');
      if (mounted) setState(() => _myJobs = jobs);
    } catch (e) {
      debugPrint('[Home] _loadMyJobs failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load your jobs: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingJobs = false);
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _isAvailable = value);
    final artisan = UserSession.currentArtisan as VerifiedArtisan?;
    if (artisan == null) return;
    try {
      await SupabaseService.updateArtisanAvailability(artisan.id, value);
      UserSession.loginAsArtisan(VerifiedArtisan(
        id: artisan.id,
        name: artisan.name,
        phoneNumber: artisan.phoneNumber,
        location: artisan.location,
        rating: artisan.rating,
        totalReviews: artisan.totalReviews,
        trade: artisan.trade,
        skills: artisan.skills,
        yearsOfExperience: artisan.yearsOfExperience,
        completedJobs: artisan.completedJobs,
        about: artisan.about,
        startingPrice: artisan.startingPrice,
        isAvailable: value,
        verificationId: artisan.verificationId,
        verifiedOn: artisan.verifiedOn,
        profileImageUrl: artisan.profileImageUrl,
      ));
    } catch (e) {
      debugPrint('[Home] Failed to toggle availability: $e');
      if (mounted) setState(() => _isAvailable = !value);
    }
  }

  // Artisan tab 0 — available general jobs to bid on
  Widget _buildArtisanJobsTab() => JobListScreen(onBidPosted: _loadMyBids);

  // Artisan tab 1 — direct invitations from homeowners
  Widget _buildInvitationsTab() => InvitationsScreen(
        onStatusChanged: _loadPendingInvitations,
      );

  // Covers A4 — switch for bottom nav
  Widget _getBody() {
    debugPrint('[Home] _getBody: userType=${UserSession.userType}, index=$_currentIndex');
    // Covers A4 — if/else based on user type
    if (UserSession.userType == UserType.artisan) {
      switch (_currentIndex) {
        case 0:
          return _buildArtisanJobsTab();
        case 1:
          return _buildInvitationsTab();
        case 2:
          return _buildArtisanBidsTab();
        case 3:
          return _buildArtisanProfileTab();
        case 4:
          return _buildArtisanSettingsTab();
        default:
          return _buildArtisanJobsTab();
      }
    }

    // If userType is null the session load failed — offer retry before logout
    if (UserSession.userType == null) {
      debugPrint('[Home] userType is null — session not loaded');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'Could not load your profile',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your internet connection and tap Retry.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _isLoading = true);
                  await SupabaseService.loadUserSession();
                  debugPrint('[Home] After retry: userType=${UserSession.userType}');
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                      if (UserSession.userType == UserType.artisan) {
                        _isAvailable =
                            UserSession.currentArtisan?.isAvailable ?? true;
                        _loadMyBids();
                      } else if (UserSession.userType == UserType.homeowner) {
                        _loadArtisans();
                        _loadMyJobs();
                      }
                    });
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  await SupabaseService.logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                icon: const Icon(Icons.logout, color: AppTheme.error),
                label: const Text('Log Out',
                    style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ),
      );
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
        return _buildHomeownerHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    // Covers A1 — final variable, null safety
    final isArtisan = UserSession.userType == UserType.artisan;

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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/notifications')
                    .then((_) => _loadUnreadCount()),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _unreadCount > 9 ? '9+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
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
                  Navigator.pushNamed(context, '/post-job').then((posted) {
                    _loadMyJobs();
                    if (posted == true) {
                      // Switch to My Jobs tab so user sees their new job immediately
                      setState(() => _currentIndex = 2);
                    }
                  }),
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
              onTap: (index) {
                setState(() => _currentIndex = index);
                if (index == 1) _loadPendingInvitations();
                if (index == 2) _loadMyBids();
              },
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.work_outline),
                  activeIcon: const Icon(Icons.work),
                  label: localizations.jobs,
                ),
                BottomNavigationBarItem(
                  icon: _invitationIcon(),
                  activeIcon: _invitationIcon(active: true),
                  label: 'Invitations',
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
              onTap: (index) {
                setState(() => _currentIndex = index);
                if (index == 2) _loadMyJobs();
              },
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
<<<<<<< HEAD
                          _searchResultAvatar(artisan),
=======
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: artisan.profileImageUrl != null
                                ? (artisan.profileImageUrl!.startsWith('http')
                                    ? Image.network(
                                        artisan.profileImageUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              AppTheme.primary.withValues(
                                                  alpha: 0.1),
                                          child: Text(
                                            artisan.name[0],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        artisan.profileImageUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              AppTheme.primary.withValues(
                                                  alpha: 0.1),
                                          child: Text(
                                            artisan.name[0],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ))
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
>>>>>>> d477498 (password recovery)
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

  Widget _buildSearchScreen(BuildContext context) {
    final results = _searchResults;
    final hasQuery = _searchQuery.isNotEmpty;
    final hasFilter = _searchCategory != 'All';

    return Column(
      children: [
        // Search bar pinned at top
        Container(
          color: AppTheme.primary,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search by name, trade or skill...',
              prefixIcon:
                  const Icon(Icons.search, color: AppTheme.textSecondary),
              suffixIcon: hasQuery
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppTheme.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Category filter chips
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSearchChip('All', '🔍'),
              ...categoryIcons.entries
                  .map((e) => _buildSearchChip(e.key, e.value)),
            ],
          ),
        ),

        // Results area
        Expanded(
          child: !hasQuery && !hasFilter
              ? _buildSearchPrompt()
              : results.isEmpty
                  ? _buildSearchEmpty()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(
                            '${results.length} artisan${results.length == 1 ? '' : 's'} found',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: results.length,
                            itemBuilder: (context, index) =>
                                _buildSearchResultCard(
                                    context, results[index]),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchChip(String label, String icon) {
    final selected = _searchCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _searchCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                selected ? AppTheme.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(
      BuildContext context, VerifiedArtisan artisan) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/artisan-detail',
        arguments: artisan,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor:
                    AppTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  artisan.name[0],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            artisan.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (artisan.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.success
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Available',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artisan.trade,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 13, color: AppTheme.secondary),
                        const SizedBox(width: 2),
                        Text(
                          '${artisan.rating} · ${artisan.completedJobs} jobs',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            artisan.location,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From ${artisan.startingPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} RWF',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Find an artisan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search by name, trade or skill,\nor pick a category above',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No artisans found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different name or category',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMyJobsScreen(BuildContext context) {
    if (_isLoadingJobs) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeJobs = _myJobs.where((j) =>
        j.status != JobStatus.cancelled &&
        j.status != JobStatus.completed).toList();
    final pastJobs = _myJobs.where((j) =>
        j.status == JobStatus.cancelled ||
        j.status == JobStatus.completed).toList();

    if (_myJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No jobs posted yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button below to post your first job',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/post-job')
                  .then((posted) {
                _loadMyJobs();
                if (posted == true) setState(() => _currentIndex = 2);
              }),
              icon: const Icon(Icons.add),
              label: const Text('Post a Job'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyJobs,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (activeJobs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Active (${activeJobs.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...activeJobs.map(_buildJobCard),
          ],
          if (pastJobs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
              child: Text(
                'Past (${pastJobs.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...pastJobs.map(_buildJobCard),
          ],
        ],
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    final statusColor = _jobStatusColor(job.status);
    final canCancel = job.status == JobStatus.requested || job.status == JobStatus.quoted;
    final budget = job.budgetRwf?.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          // Header — status bar at top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    job.categoryLabel,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 7, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        job.statusLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),

                // Description
                if (job.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.5),
                  ),
                ],

                const SizedBox(height: 12),

                // Location + date row
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.location,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.access_time,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _timeAgo(job.requestedAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),

                // Budget
                if (budget != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 14, color: AppTheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'Budget: $budget RWF',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Action row
                Row(
                  children: [
                    if (job.status == JobStatus.requested ||
                        job.status == JobStatus.quoted)
                      Expanded(
                        child: job.bidCount > 0
                            ? ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/bids-management',
                                    arguments: job,
                                  ).then((_) => _loadMyJobs()),
                                icon: const Icon(Icons.gavel, size: 14),
                                label: Text(
                                    'View Bids (${job.bidCount})'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.orange.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.hourglass_empty,
                                        size: 14, color: Colors.orange),
                                    SizedBox(width: 6),
                                    Text(
                                      'Awaiting bids',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    if (job.status == JobStatus.booked)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_user_outlined,
                                  size: 14, color: AppTheme.primary),
                              SizedBox(width: 6),
                              Text(
                                'Artisan Booked',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (job.status == JobStatus.completed)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 14, color: AppTheme.success),
                              SizedBox(width: 6),
                              Text(
                                'Completed',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (canCancel) ...[
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => _confirmCancelJob(job),
                        icon: const Icon(Icons.cancel_outlined,
                            size: 14, color: AppTheme.error),
                        label: const Text('Cancel',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.error)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          side: const BorderSide(color: AppTheme.error),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBidsBottomSheet(BuildContext context, Job job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BidsBottomSheet(
        job: job,
        onBidAccepted: _loadMyJobs,
      ),
    );
  }

  void _confirmCancelJob(Job job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Job?'),
        content: Text(
          'Are you sure you want to cancel "${job.title}"? This cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Job'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _cancelJob(job.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelJob(String jobId) async {
    try {
      await SupabaseService.cancelJob(jobId);
      await _loadMyJobs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job cancelled.'),
            backgroundColor: AppTheme.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Color _jobStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.requested:
        return Colors.orange;
      case JobStatus.quoted:
        return Colors.blue;
      case JobStatus.booked:
        return AppTheme.primary;
      case JobStatus.onTheWay:
        return Colors.purple;
      case JobStatus.inProgress:
        return Colors.teal;
      case JobStatus.completed:
        return AppTheme.success;
      case JobStatus.cancelled:
        return AppTheme.error;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  // Homeowner profile screen — full view
  Widget _buildProfileScreen(BuildContext context) {
    final homeowner = UserSession.currentHomeowner;
    final email = SupabaseService.currentUser?.email ?? homeowner?.email ?? '—';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    homeowner?.name.isNotEmpty == true
                        ? homeowner!.name[0]
                        : 'U',
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  homeowner?.name ?? 'Homeowner',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        homeowner?.districtLabel ?? 'Kigali, Rwanda',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                  '${_myJobs.length}',
                  'Jobs Posted',
                  AppTheme.primary,
                ),
                _buildStatItem(
                  '${_myJobs.where((j) => j.status == JobStatus.completed).length}',
                  'Completed',
                  AppTheme.success,
                ),
                _buildStatItem(
                  homeowner?.district.isNotEmpty == true
                      ? homeowner!.district[0].toUpperCase() +
                          homeowner.district.substring(1)
                      : 'Kigali',
                  'District',
                  AppTheme.secondary,
                ),
              ],
            ),
          ),

          // Account section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: _buildSettingsSection(
              title: 'Account',
              children: [
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: homeowner?.name ?? 'User',
                  subtitle: 'Full name',
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.email_outlined,
                  title: email,
                  subtitle: 'Email address',
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.phone_outlined,
                  title: (homeowner?.phoneNumber ?? '').isNotEmpty
                      ? homeowner!.phoneNumber
                      : 'Not set',
                  subtitle: 'Phone number',
                ),
              ],
            ),
          ),

          // My Jobs quick link
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildSettingsSection(
              title: 'Activity',
              children: [
                _buildSettingsTile(
                  icon: Icons.work_outline,
                  title: 'My Jobs',
                  subtitle: 'View all jobs you have posted',
                  onTap: () => setState(() => _currentIndex = 2),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: 'Update your name and location',
                  onTap: () =>
                      Navigator.pushNamed(context, '/homeowner-edit-profile'),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Language preference
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildSettingsSection(
              title: 'Preferences',
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.language,
                            color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Language',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            Text('App display language',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const LanguageSelector(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Support
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildSettingsSection(
              title: 'Support',
              children: [
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'FAQs, contact us',
                  onTap: () {},
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'About QuickFix',
                  subtitle: 'Version 1.0.0',
                ),
              ],
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: ElevatedButton.icon(
              onPressed: () async {
                final nav = Navigator.of(context);
                await SupabaseService.logout();
                if (mounted) nav.pushReplacementNamed('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Center(
              child: Text(
                'QuickFix • Rwanda Artisan Platform',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invitationIcon({bool active = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(active ? Icons.mail_rounded : Icons.mail_outline_rounded),
        if (_pendingInvitations > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                _pendingInvitations > 9 ? '9+' : '$_pendingInvitations',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Artisan tab 2 — my bids with status filter
  Widget _buildArtisanBidsTab() {
    if (_isLoadingBids) {
      return const Center(child: CircularProgressIndicator());
    }

    final filters = ['All', 'Pending', 'Accepted', 'Rejected'];
    final filtered = _selectedBidFilter == 'All'
        ? _myBids
        : _myBids.where((b) => b.statusLabel == _selectedBidFilter).toList();

    return Column(
      children: [
        // Stats summary
        Container(
          color: AppTheme.primary,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              _buildMiniStat('${_myBids.length}', 'Total Bids', Colors.white),
              _buildMiniStat(
                '${_myBids.where((b) => b.status == BidStatus.accepted).length}',
                'Accepted',
                Colors.greenAccent,
              ),
              _buildMiniStat(
                '${_myBids.where((b) => b.status == BidStatus.pending).length}',
                'Pending',
                Colors.orangeAccent,
              ),
            ],
          ),
        ),

        // Filter chips
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: filters.map((f) {
              final selected = _selectedBidFilter == f;
              return GestureDetector(
                onTap: () => setState(() => _selectedBidFilter = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? AppTheme.primary : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        if (filtered.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _myBids.isEmpty ? 'No bids yet' : 'No $_selectedBidFilter bids',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse the Jobs tab and send your first bid',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMyBids,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildBidCard(filtered[index]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBidCard(Bid bid) {
    final statusColor = _bidStatusColor(bid.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bid.jobTitle ?? 'Job',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bid.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (bid.jobCategory != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bid.jobCategory!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (bid.jobLocation != null) ...[
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      bid.jobLocation!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Your bid: ${bid.amountRwf.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} RWF',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
            if (bid.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                bid.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Submitted ${_timeAgo(bid.createdAt)}',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchResultAvatar(VerifiedArtisan artisan) {
    final url = artisan.profileImageUrl;
    final fallback = CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
      child: Text(artisan.name[0],
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppTheme.primary)),
    );
    if (url == null || url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.network(url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : fallback,
          errorBuilder: (context, error, stackTrace) => fallback),
    );
  }

  Widget _artisanAvatar(VerifiedArtisan artisan) {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          artisan.name.isNotEmpty ? artisan.name[0].toUpperCase() : 'A',
          style: const TextStyle(
              fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Color _bidStatusColor(BidStatus status) {
    switch (status) {
      case BidStatus.pending:
        return Colors.orange;
      case BidStatus.accepted:
        return AppTheme.success;
      case BidStatus.rejected:
        return AppTheme.error;
    }
  }

  // Artisan tab 2 — full profile view
  Widget _buildArtisanProfileTab() {
    final artisan = UserSession.currentArtisan as VerifiedArtisan?;
    final email = SupabaseService.currentUser?.email ?? '';
    final isIncomplete = artisan == null || artisan.trade == 'Not set';

    // If artisan is completely null (not even a minimal build), show retry
    if (artisan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Profile not loaded',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(email.isNotEmpty ? email : 'Unknown account',
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await SupabaseService.loadUserSession();
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await SupabaseService.logout();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Log Out',
                  style: TextStyle(color: AppTheme.error)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 3),
                      ),
                      child: ClipOval(
                        child: artisan.profileImageUrl != null
                            ? Image.network(
                                artisan.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => _artisanAvatar(artisan),
                              )
                            : _artisanAvatar(artisan),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _isAvailable ? AppTheme.success : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(artisan.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(artisan.trade,
                    style: const TextStyle(fontSize: 15, color: Colors.white70)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(artisan.location,
                        style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isAvailable
                        ? AppTheme.success.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isAvailable ? AppTheme.success : Colors.white30,
                    ),
                  ),
                  child: Text(
                    _isAvailable ? '● Available for Jobs' : '● Currently Unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isAvailable ? AppTheme.success : Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Availability toggle
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (_isAvailable ? AppTheme.success : Colors.grey)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isAvailable ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                    color: _isAvailable ? AppTheme.success : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Availability',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                      Text(
                        _isAvailable
                            ? 'Visible to homeowners'
                            : 'Hidden from homeowners',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: _toggleAvailability,
                  activeThumbColor: AppTheme.success,
                ),
              ],
            ),
          ),

          // Incomplete profile banner
          if (isIncomplete)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/artisan-edit-profile')
                  .then((_) => setState(() {
                        _isAvailable =
                            UserSession.currentArtisan?.isAvailable ?? false;
                      })),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your artisan profile is incomplete. Tap to set up your trade, skills, and pricing.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.orange),
                  ],
                ),
              ),
            ),

          // Stats row
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                _buildStatItem('${artisan.rating}★', 'Rating', AppTheme.secondary),
                _buildStatItem('${artisan.completedJobs}', 'Jobs Done', AppTheme.primary),
                _buildStatItem('${artisan.yearsOfExperience}y', 'Experience', AppTheme.success),
                _buildStatItem('${artisan.totalReviews}', 'Reviews', Colors.purple),
              ],
            ),
          ),

          // Skills
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Skills',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: artisan.skills
                  .map(
                    (s) => Chip(
                      label: Text(s,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.primary)),
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                      side: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.3)),
                      padding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ),

          // About
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('About',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              artisan.about.isNotEmpty
                  ? artisan.about
                  : 'No description yet. Tap Edit Profile to add one.',
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
            ),
          ),

          // Verification badge
          if (artisan.isRecentlyVerified)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppTheme.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified artisan — ID: ${artisan.verificationId}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Starting price
          Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppTheme.secondary, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Starting Price',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      '${artisan.startingPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} RWF',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/artisan-edit-profile')
                      .then((_) => setState(() {
                            _isAvailable =
                                UserSession.currentArtisan?.isAvailable ?? true;
                          })),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: OutlinedButton.icon(
              onPressed: () async {
                await SupabaseService.logout();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text('Log Out',
                  style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppTheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Artisan tab 3 — settings and account info
  Widget _buildArtisanSettingsTab() {
    final artisan = UserSession.currentArtisan as VerifiedArtisan?;
    final email = SupabaseService.currentUser?.email ?? '—';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // Account section
        _buildSettingsSection(
          title: 'Account',
          children: [
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: artisan?.name ?? 'Artisan',
              subtitle: artisan?.trade ?? 'Trade not set',
            ),
            _buildSettingsDivider(),
            _buildSettingsTile(
              icon: Icons.email_outlined,
              title: email,
              subtitle: 'Email address',
            ),
            _buildSettingsDivider(),
            _buildSettingsTile(
              icon: Icons.phone_outlined,
              title: artisan?.phoneNumber ?? '—',
              subtitle: 'Phone number',
            ),
            _buildSettingsDivider(),
            _buildSettingsTile(
              icon: Icons.location_on_outlined,
              title: artisan?.location ?? '—',
              subtitle: 'Location',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Availability section
        _buildSettingsSection(
          title: 'Status',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_isAvailable ? AppTheme.success : Colors.grey)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isAvailable
                          ? Icons.wifi_tethering
                          : Icons.wifi_tethering_off,
                      color: _isAvailable ? AppTheme.success : Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available for Jobs',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                        Text(
                          _isAvailable
                              ? 'Homeowners can find you'
                              : 'You are hidden from search',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAvailable,
                    onChanged: _toggleAvailability,
                    activeThumbColor: AppTheme.success,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Profile actions
        _buildSettingsSection(
          title: 'Profile',
          children: [
            _buildSettingsTile(
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              subtitle: 'Update your name, trade, skills and pricing',
              onTap: () => Navigator.pushNamed(context, '/artisan-edit-profile')
                  .then((_) => setState(
                      () => _isAvailable =
                          UserSession.currentArtisan?.isAvailable ?? true)),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Language
        _buildSettingsSection(
          title: 'Preferences',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.language,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Language',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                        Text('App display language',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const LanguageSelector(),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Support
        _buildSettingsSection(
          title: 'Support',
          children: [
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'FAQs, contact us',
              onTap: () {},
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
            ),
            _buildSettingsDivider(),
            _buildSettingsTile(
              icon: Icons.star_outline,
              title: 'Rate QuickFix',
              subtitle: 'Share your experience',
              onTap: () {},
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
            ),
            _buildSettingsDivider(),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'About QuickFix',
              subtitle: 'Version 1.0.0',
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Logout
        ElevatedButton.icon(
          onPressed: () async {
            await SupabaseService.logout();
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            minimumSize: const Size(double.infinity, 52),
          ),
        ),

        const SizedBox(height: 12),
        const Center(
          child: Text(
            'QuickFix • Rwanda Artisan Platform',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  // Settings section card builder
  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary))
          : null,
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSettingsDivider() => const Divider(
        height: 1,
        indent: 56,
        endIndent: 0,
        color: Color(0xFFF0F0F0),
      );

  // Mini stat for bid summary bar
  Widget _buildMiniStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  // Shared stat item for profile tabs
  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ── Bids bottom sheet ──────────────────────────────────────────────────────

class _BidsBottomSheet extends StatefulWidget {
  final Job job;
  final VoidCallback onBidAccepted;

  const _BidsBottomSheet({
    required this.job,
    required this.onBidAccepted,
  });

  @override
  State<_BidsBottomSheet> createState() => _BidsBottomSheetState();
}

class _BidsBottomSheetState extends State<_BidsBottomSheet> {
  List<Bid> _bids = [];
  bool _isLoading = true;
  String? _acceptingBidId;

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  Future<void> _loadBids() async {
    try {
      final bids = await SupabaseService.getBidsForJob(widget.job.id);
      if (mounted) setState(() { _bids = bids; _isLoading = false; });
    } catch (e) {
      debugPrint('[BidsSheet] Failed to load bids: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptBid(Bid bid) async {
    setState(() => _acceptingBidId = bid.id);
    try {
      await SupabaseService.acceptBid(
        bidId: bid.id,
        jobId: widget.job.id,
        artisanId: bid.artisanId,
      );
      if (mounted) Navigator.pop(context);
      widget.onBidAccepted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Bid accepted! ${bid.artisanName ?? 'Artisan'} is booked.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('[BidsSheet] acceptBid failed: $e');
      if (mounted) {
        setState(() => _acceptingBidId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept bid: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bids Received',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        widget.job.title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          // Body
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _bids.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No bids yet',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        shrinkWrap: true,
                        itemCount: _bids.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final bid = _bids[index];
                          final isAccepting = _acceptingBidId == bid.id;
                          final fmt = bid.amountRwf
                              .toString()
                              .replaceAllMapped(
                                  RegExp(r'(\d)(?=(\d{3})+$)'),
                                  (m) => '${m[1]},');
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bid.status == BidStatus.accepted
                                  ? AppTheme.success.withValues(alpha: 0.05)
                                  : AppTheme.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: bid.status == BidStatus.accepted
                                    ? AppTheme.success.withValues(alpha: 0.4)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Artisan row
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppTheme.primary
                                          .withValues(alpha: 0.12),
                                      child: Text(
                                        (bid.artisanName?.isNotEmpty == true)
                                            ? bid.artisanName![0]
                                            : 'A',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            Text(
                                              bid.artisanTrade!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (bid.artisanRating != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              size: 14,
                                              color: AppTheme.secondary),
                                          const SizedBox(width: 2),
                                          Text(
                                            bid.artisanRating!
                                                .toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Amount
                                Row(
                                  children: [
                                    const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 16,
                                        color: AppTheme.secondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$fmt RWF',
                                      style: const TextStyle(
                                        fontSize: 18,
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
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),

                                // Accept button or status badge
                                bid.status == BidStatus.accepted
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle,
                                                size: 16,
                                                color: AppTheme.success),
                                            SizedBox(width: 6),
                                            Text(
                                              'Accepted',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : bid.status == BidStatus.rejected
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Not selected',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                          )
                                        : SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: isAccepting
                                                  ? null
                                                  : () => _acceptBid(bid),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppTheme.success,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: isAccepting
                                                  ? const SizedBox(
                                                      height: 18,
                                                      width: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Accept This Bid',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
