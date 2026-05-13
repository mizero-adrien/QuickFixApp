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

  // Covers A2 — arrow function
  List<VerifiedArtisan> get _filteredArtisans => _selectedCategory == 'All'
      ? _artisans
      : _artisans
          .where((a) => a.trade == _selectedCategory)
          .toList();

  List<VerifiedArtisan> get _searchResults {
    final hasQuery = _searchQuery.isNotEmpty;
    final hasFilter = _searchCategory != 'All';
    if (!hasQuery && !hasFilter) return [];
    final q = _searchQuery.toLowerCase();
    return _artisans.where((a) {
      final matchesQuery = !hasQuery ||
          a.name.toLowerCase().contains(q) ||
          a.trade.toLowerCase().contains(q) ||
          a.skills.any((s) => s.toLowerCase().contains(q));
      final matchesCategory =
          !hasFilter || a.trade.toLowerCase() == _searchCategory.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadArtisans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Covers B5 — async/await Future
  Future<void> _loadArtisans() async {
    final artisans = await fetchArtisans();
    setState(() {
      _artisans = artisans;
      _isLoading = false;
    });
  }

  Future<void> _loadMyBids() async {
    final artisanId = UserSession.currentArtisan?.id;
    if (artisanId == null) return;
    setState(() => _isLoadingBids = true);
    try {
      final bids = await SupabaseService.getBidsByArtisan(artisanId);
      setState(() => _myBids = bids);
    } catch (_) {
      // show empty state on error
    } finally {
      if (mounted) setState(() => _isLoadingBids = false);
    }
  }

  Future<void> _loadMyJobs() async {
    final homeownerId = UserSession.currentHomeowner?.id;
    if (homeownerId == null) return;
    setState(() => _isLoadingJobs = true);
    try {
      final jobs = await SupabaseService.getJobsByHomeowner(homeownerId);
      setState(() => _myJobs = jobs);
    } catch (_) {
      // show empty state on error
    } finally {
      if (mounted) setState(() => _isLoadingJobs = false);
    }
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
                  Navigator.pushNamed(context, '/post-job').then((_) => _loadMyJobs()),
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
                if (index == 1) _loadMyBids();
              },
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
              'Tap "Post a Job" to get started',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyJobs,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _myJobs.length,
        itemBuilder: (context, index) => _buildJobCard(_myJobs[index]),
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    final statusColor = _jobStatusColor(job.status);
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
                    job.title,
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
                    job.statusLabel,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.categoryLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    job.location,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (job.budgetRwf != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Budget: ${job.budgetRwf!.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} RWF',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Posted ${_timeAgo(job.requestedAt)}',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
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
    if (_isLoadingBids) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myBids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No bids yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse available jobs and send your first bid',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyBids,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _myBids.length,
        itemBuilder: (context, index) => _buildBidCard(_myBids[index]),
      ),
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
