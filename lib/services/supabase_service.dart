// SupabaseService — all available methods:
//
// Auth:
//   signIn(email, password)            → String userId
//   signUp(email, password, {name, phoneNumber, district, role}) → String userId
//   logout()
//   sendPasswordReset(email)
//   loadUserSession()                  → sets UserSession from profiles table
//
// Profiles:
//   createProfile({id, name, phoneNumber, district, role})
//   getProfile(userId)                 → Map<String, dynamic>?
//   updateProfile({id, name, phoneNumber, district})
//   updateArtisanProfile({id, name, phoneNumber, district, trade, skills, yearsOfExperience, startingPrice, about})
//
// Artisans:
//   createArtisanProfile({id, trade, skills, yearsOfExperience, startingPrice, about})
//   getArtisans()                      → List<VerifiedArtisan>
//
// Jobs:
//   postJob({homeownerId, title, description, location, category, budgetRwf})
//   getOpenJobs()                      → List<Job>
//   getJobsByHomeowner(homeownerId)    → List<Job>
//
// Bids:
//   postBid({jobId, artisanId, amountRwf, note})
//   getBidsByArtisan(artisanId)        → List<Bid>
//
// Reviews:
//   getReviewsForArtisan(artisanId)   → List<Review>

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quickfix/models/app_notification.dart';
import 'package:quickfix/models/artisan.dart';
import 'package:quickfix/models/bid.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/models/review.dart';

class SupabaseService {
  static SupabaseClient get _db => Supabase.instance.client;
  static User? get currentUser => _db.auth.currentUser;

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<String> signIn(String email, String password) async {
    final res = await _db.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user!.id;
  }

  static Future<String> signUp(
    String email,
    String password, {
    required String name,
    required String phoneNumber,
    required String district,
    required String role,
  }) async {
    debugPrint('[SignUp] Attempting signup for $email as $role');
    final res = await _db.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'phone_number': phoneNumber,
        'district': district,
        'role': role,
      },
    );
    if (res.user == null) {
      throw Exception('Signup failed — no user returned');
    }
    debugPrint('[SignUp] Auth user created: ${res.user!.id}');
    return res.user!.id;
  }

  static Future<void> logout() async {
    await _db.auth.signOut();
    UserSession.logout();
  }

  static Future<void> sendPasswordReset(String email) async {
    await _db.auth.resetPasswordForEmail(email);
  }

  // ── Profiles ──────────────────────────────────────────────────────────────

  static Future<void> createProfile({
    required String id,
    required String name,
    required String phoneNumber,
    required String district,
    required String role,
  }) async {
    // Profile is created automatically via Supabase trigger.
    // This upsert is a fallback in case the trigger didn't fire.
    debugPrint('[Profile] Upserting profile for $id');
    try {
      await _db.from('profiles').upsert({
        'id': id,
        'name': name,
        'phone_number': phoneNumber,
        'district': district,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[Profile] Profile upserted successfully');
    } catch (e) {
      debugPrint('[Profile] Upsert skipped (trigger may have handled it): $e');
    }
  }

  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    return await _db
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  static Future<void> updateProfile({
    required String id,
    required String name,
    required String phoneNumber,
    required String district,
  }) async {
    await _db.from('profiles').update({
      'name': name,
      'phone_number': phoneNumber,
      'district': district,
    }).eq('id', id);
  }

  static Future<void> updateArtisanProfile({
    required String id,
    required String name,
    required String phoneNumber,
    required String district,
    required String trade,
    required List<String> skills,
    required int yearsOfExperience,
    required int startingPrice,
    required String about,
    String? avatarUrl,
  }) async {
    debugPrint('[SupabaseService] Updating artisan profile for $id');
    final profileUpdate = {
      'name': name,
      'phone_number': phoneNumber,
      'district': district,
    };
    if (avatarUrl != null) profileUpdate['avatar_url'] = avatarUrl;
    await _db.from('profiles').update(profileUpdate).eq('id', id);
    // upsert so new artisans (no row yet) also save correctly
    await _db.from('artisans').upsert({
      'id': id,
      'trade': trade,
      'skills': skills,
      'years_of_experience': yearsOfExperience,
      'starting_price': startingPrice,
      'about': about,
    });
    debugPrint('[SupabaseService] Artisan profile upserted');
  }

  // ── Storage ───────────────────────────────────────────────────────────────

  static Future<String> uploadArtisanAvatar(
      String userId, Uint8List bytes) async {
    final path = '$userId.jpg';
    debugPrint('[Storage] Uploading avatar for $userId...');
    await _db.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );
    final url = _db.storage.from('avatars').getPublicUrl(path);
    debugPrint('[Storage] Avatar uploaded: $url');
    return url;
  }

  // ── Artisans ──────────────────────────────────────────────────────────────

  static Future<void> updateArtisanAvailability(
      String id, bool isAvailable) async {
    await _db
        .from('artisans')
        .update({'is_available': isAvailable})
        .eq('id', id);
  }

  static Future<void> createArtisanProfile({
    required String id,
    required String trade,
    required List<String> skills,
    required int yearsOfExperience,
    required int startingPrice,
    required String about,
  }) async {
    await _db.from('artisans').insert({
      'id': id,
      'trade': trade,
      'skills': skills,
      'years_of_experience': yearsOfExperience,
      'starting_price': startingPrice,
      'about': about,
    });
  }

  static Future<List<VerifiedArtisan>> getArtisans() async {
    final data = await _db
        .from('artisans')
        .select('*, profiles(*)')
        .order('rating', ascending: false);
    return data.map<VerifiedArtisan>(_toArtisan).toList();
  }

  // ── Jobs ──────────────────────────────────────────────────────────────────

  static Future<void> postJob({
    required String homeownerId,
    required String title,
    required String description,
    required String location,
    required String category,
    int? budgetRwf,
    String? assignedArtisanId,
    String? assignedArtisanName,
  }) async {
    final isDirect = assignedArtisanId != null;
    final row = await _db.from('jobs').insert({
      'homeowner_id': homeownerId,
      'title': title,
      'description': description,
      'location': location,
      'category': category,
      'budget_rwf': budgetRwf,
      'status': 'requested',
      if (isDirect) 'assigned_artisan_id': assignedArtisanId,
    }).select().single();

    if (isDirect) {
      await createNotification(
        userId: assignedArtisanId!,
        type: 'job_invitation',
        title: 'New Job Invitation',
        body: 'You have been directly booked for: $title',
        data: {
          'job_id': row['id'] as String,
          'homeowner_id': homeownerId,
          'job_title': title,
        },
      );
    }
  }

  static Future<void> cancelJob(String jobId) async {
    await _db
        .from('jobs')
        .update({'status': 'cancelled'})
        .eq('id', jobId);
  }

  static Future<List<Job>> getOpenJobs() async {
    final data = await _db
        .from('jobs')
        .select()
        .eq('status', 'requested')
        .filter('assigned_artisan_id', 'is', null)
        .order('requested_at', ascending: false);
    return data.map<Job>(_toJob).toList();
  }

  static Future<List<Job>> getInvitationsForArtisan(String artisanId) async {
    final data = await _db
        .from('jobs')
        .select()
        .eq('assigned_artisan_id', artisanId)
        .order('requested_at', ascending: false);
    return data.map<Job>(_toJob).toList();
  }

  static Future<void> acceptInvitation({
    required String jobId,
    required String homeownerId,
    required String artisanName,
    required String jobTitle,
  }) async {
    await _db.from('jobs').update({'status': 'booked'}).eq('id', jobId);
    await createNotification(
      userId: homeownerId,
      type: 'invitation_accepted',
      title: 'Booking Confirmed!',
      body: '$artisanName accepted your booking for "$jobTitle".',
      data: {'job_id': jobId, 'artisan_name': artisanName, 'job_title': jobTitle},
    );
  }

  static Future<void> declineInvitation({
    required String jobId,
    required String homeownerId,
    required String artisanName,
    required String jobTitle,
  }) async {
    await _db.from('jobs').update({'status': 'cancelled'}).eq('id', jobId);
    await createNotification(
      userId: homeownerId,
      type: 'invitation_declined',
      title: 'Booking Declined',
      body: '$artisanName declined your booking for "$jobTitle".',
      data: {'job_id': jobId, 'artisan_name': artisanName, 'job_title': jobTitle},
    );
  }

  static Future<List<Job>> getJobsByHomeowner(String homeownerId) async {
    final data = await _db
        .from('jobs')
        .select('*, bids(count)')
        .eq('homeowner_id', homeownerId)
        .order('requested_at', ascending: false);
    return data.map<Job>(_toJob).toList();
  }

  // ── Bid management (homeowner) ────────────────────────────────────────────

  static Future<List<Bid>> getBidsForJob(String jobId) async {
    final data = await _db
        .from('bids')
        .select('*, artisans(trade, rating, profiles(name, phone_number, avatar_url))')
        .eq('job_id', jobId)
        .order('amount_rwf', ascending: true);
    return data.map<Bid>(_toBidWithArtisan).toList();
  }

  static Future<void> rejectBid({
    required String bidId,
    required String artisanId,
    String? jobTitle,
  }) async {
    await _db.from('bids').update({'status': 'rejected'}).eq('id', bidId);
    try {
      await createNotification(
        userId: artisanId,
        type: 'bid_rejected',
        title: 'Bid Not Selected',
        body: 'Your bid for "${jobTitle ?? 'a job'}" was not selected this time.',
        data: {'bid_id': bidId, 'job_title': jobTitle ?? ''},
      );
    } catch (e) {
      debugPrint('[rejectBid] Could not create notification: $e');
    }
  }

  static Future<void> acceptBid({
    required String bidId,
    required String jobId,
    required String artisanId,
    String? jobTitle,
    int? amountRwf,
    String? homeownerId,
  }) async {
    await _db.from('bids').update({'status': 'accepted'}).eq('id', bidId);
    await _db
        .from('bids')
        .update({'status': 'rejected'})
        .eq('job_id', jobId)
        .neq('id', bidId);
    await _db.from('jobs').update({
      'status': 'booked',
      'assigned_artisan_id': artisanId,
    }).eq('id', jobId);

    // Notify the accepted artisan
    try {
      final fmt = amountRwf != null
          ? amountRwf
              .toString()
              .replaceAllMapped(
                  RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')
          : '—';
      await createNotification(
        userId: artisanId,
        type: 'bid_accepted',
        title: 'Your Bid Was Accepted!',
        body: 'A homeowner accepted your bid of $fmt RWF for "${jobTitle ?? 'a job'}". Confirm or decline below.',
        data: {
          'job_id': jobId,
          'bid_id': bidId,
          'homeowner_id': homeownerId ?? '',
          'job_title': jobTitle ?? '',
          'amount_rwf': amountRwf ?? 0,
        },
      );
    } catch (e) {
      debugPrint('[acceptBid] Could not create artisan notification: $e');
    }
  }

  static Future<void> declineBooking({
    required String jobId,
    required String bidId,
    required String homeownerId,
    required String artisanName,
    String? jobTitle,
  }) async {
    // Reset job to open
    await _db.from('jobs').update({
      'status': 'requested',
      'assigned_artisan_id': null,
    }).eq('id', jobId);
    // Reset all bids on this job back to pending so homeowner can pick again
    await _db.from('bids').update({'status': 'pending'}).eq('job_id', jobId);
    // Notify homeowner
    await createNotification(
      userId: homeownerId,
      type: 'booking_declined',
      title: 'Artisan Declined Booking',
      body: '$artisanName declined the booking for "${jobTitle ?? 'your job'}". You can choose another bid.',
      data: {'job_id': jobId},
    );
  }

  // ── Bids ──────────────────────────────────────────────────────────────────

  static Future<void> postBid({
    required String jobId,
    required String artisanId,
    required int amountRwf,
    required String note,
    String? artisanName,
  }) async {
    final res = await _db.from('bids').insert({
      'job_id': jobId,
      'artisan_id': artisanId,
      'amount_rwf': amountRwf,
      'note': note,
    }).select('id').single();

    // Notify homeowner
    try {
      final job = await _db
          .from('jobs')
          .select('homeowner_id, title')
          .eq('id', jobId)
          .single();
      final fmt = amountRwf
          .toString()
          .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
      await createNotification(
        userId: job['homeowner_id'] as String,
        type: 'new_bid',
        title: 'New Bid Received',
        body: '${artisanName ?? 'An artisan'} placed a bid of $fmt RWF on "${job['title']}"',
        data: {
          'job_id': jobId,
          'bid_id': res['id'],
          'artisan_id': artisanId,
          'artisan_name': artisanName ?? '',
          'amount_rwf': amountRwf,
        },
      );
    } catch (e) {
      debugPrint('[postBid] Could not create notification: $e');
    }
  }

  static Future<List<Bid>> getBidsByArtisan(String artisanId) async {
    final data = await _db
        .from('bids')
        .select('*, jobs(title, category, location)')
        .eq('artisan_id', artisanId)
        .order('created_at', ascending: false);
    return data.map<Bid>(_toBid).toList();
  }

  // ── Reviews ───────────────────────────────────────────────────────────────

  static Future<List<Review>> getReviewsForArtisan(String artisanId) async {
    final data = await _db
        .from('reviews')
        .select()
        .eq('artisan_id', artisanId)
        .order('created_at', ascending: false);
    return data.map<Review>(_toReview).toList();
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  static Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    await _db.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
    });
  }

  static Future<List<AppNotification>> getNotifications(String userId) async {
    final data = await _db
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map<AppNotification>(_toNotification).toList();
  }

  static Future<int> getUnreadCount(String userId) async {
    final data = await _db
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false);
    return (data as List).length;
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  static Future<void> markAllRead(String userId) async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  static AppNotification _toNotification(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  // ── Session restore ───────────────────────────────────────────────────────

  static Future<void> loadUserSession() async {
    final user = currentUser;
    debugPrint('[Session] currentUser: ${user?.id ?? 'null (not logged in)'}');
    if (user == null) return;

    debugPrint('[Session] Fetching profile for ${user.id}...');
    Map<String, dynamic>? profile;
    try {
      profile = await getProfile(user.id);
    } catch (e) {
      debugPrint('[Session] getProfile threw: $e');
      return;
    }

    if (profile == null) {
      debugPrint('[Session] Profile row not found — RLS may be blocking SELECT on profiles, or row does not exist');
      return;
    }

    final role = profile['role'] as String? ?? '';
    debugPrint('[Session] Profile found: name=${profile['name']}, role=$role');

    if (role == 'homeowner') {
      UserSession.loginAsHomeowner(Homeowner(
        id: user.id,
        name: profile['name'] as String? ?? '',
        phoneNumber: profile['phone_number'] as String? ?? '',
        location: _districtLabel(profile['district'] as String? ?? 'gasabo'),
        email: user.email ?? '',
        district: profile['district'] as String? ?? 'gasabo',
        joinedAt: profile['created_at'] != null
            ? DateTime.parse(profile['created_at'] as String)
            : DateTime.now(),
      ));
      debugPrint('[Session] Logged in as homeowner: ${profile['name']}');
    } else if (role == 'artisan') {
      debugPrint('[Session] Fetching artisan row for ${user.id}...');
      Map<String, dynamic>? artisanData;
      try {
        artisanData = await _db
            .from('artisans')
            .select('*, profiles(*)')
            .eq('id', user.id)
            .maybeSingle();
      } catch (e) {
        debugPrint('[Session] artisans query threw: $e');
        UserSession.loginAsArtisan(_minimalArtisan(user.id, profile));
        return;
      }

      if (artisanData != null) {
        UserSession.loginAsArtisan(_toArtisan(artisanData));
        debugPrint('[Session] Logged in as artisan: ${artisanData['trade']}');
      } else {
        debugPrint('[Session] Artisan row missing — building minimal artisan from profile');
        UserSession.loginAsArtisan(_minimalArtisan(user.id, profile));
      }
    } else {
      debugPrint('[Session] Unknown role: $role');
    }
  }

  // ── JSON parsers ──────────────────────────────────────────────────────────

  // Builds a VerifiedArtisan from just the profiles row when the artisans
  // row doesn't exist yet. Gives the profile screen something real to show.
  static VerifiedArtisan _minimalArtisan(
      String id, Map<String, dynamic> profile) {
    return VerifiedArtisan(
      id: id,
      name: profile['name'] as String? ?? '',
      phoneNumber: profile['phone_number'] as String? ?? '',
      location: _districtLabel(profile['district'] as String? ?? 'gasabo'),
      rating: 0.0,
      totalReviews: 0,
      trade: 'Not set',
      skills: const [],
      yearsOfExperience: 0,
      completedJobs: 0,
      about: '',
      startingPrice: 0,
      isAvailable: false,
      verificationId: 'VRF-000',
      verifiedOn: DateTime.now(),
      profileImageUrl: profile['avatar_url'] as String?,
    );
  }

  static VerifiedArtisan _toArtisan(Map<String, dynamic> json) {
    final p = json['profiles'] as Map<String, dynamic>;
    return VerifiedArtisan(
      id: json['id'] as String,
      name: p['name'] as String,
      phoneNumber: p['phone_number'] as String? ?? '',
      location: _districtLabel(p['district'] as String? ?? 'gasabo'),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      trade: json['trade'] as String,
      skills: List<String>.from(json['skills'] as List? ?? []),
      yearsOfExperience: json['years_of_experience'] as int? ?? 0,
      completedJobs: json['completed_jobs'] as int? ?? 0,
      about: json['about'] as String? ?? '',
      startingPrice: json['starting_price'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      verificationId: json['verification_id'] as String? ?? 'VRF-000',
      verifiedOn: json['verified_on'] != null
          ? DateTime.parse(json['verified_on'] as String)
          : DateTime.now(),
      profileImageUrl: p['avatar_url'] as String?,
    );
  }

  static Job _toJob(Map<String, dynamic> json) {
    // bids(count) returns [{"count": N}] when joined
    final bidsData = json['bids'] as List?;
    final bidCount = (bidsData != null && bidsData.isNotEmpty)
        ? (bidsData[0]['count'] as int? ?? 0)
        : 0;

    return Job(
      id: json['id'] as String,
      homeownerId: json['homeowner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      category: _toCategory(json['category'] as String? ?? 'plumbing'),
      status: _toStatus(json['status'] as String? ?? 'requested'),
      budgetRwf: json['budget_rwf'] as int?,
      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'] as String)
          : DateTime.now(),
      assignedArtisanId: json['assigned_artisan_id'] as String?,
      bidCount: bidCount,
    );
  }

  static Bid _toBidWithArtisan(Map<String, dynamic> json) {
    final artisan = json['artisans'] as Map<String, dynamic>?;
    final profile = artisan?['profiles'] as Map<String, dynamic>?;
    return Bid(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      artisanId: json['artisan_id'] as String,
      amountRwf: json['amount_rwf'] as int,
      note: json['note'] as String? ?? '',
      status: _toBidStatus(json['status'] as String? ?? 'pending'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      artisanName: profile?['name'] as String?,
      artisanTrade: artisan?['trade'] as String?,
      artisanRating: (artisan?['rating'] as num?)?.toDouble(),
      artisanAvatarUrl: profile?['avatar_url'] as String?,
    );
  }

  static Bid _toBid(Map<String, dynamic> json) {
    final job = json['jobs'] as Map<String, dynamic>?;
    return Bid(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      artisanId: json['artisan_id'] as String,
      amountRwf: json['amount_rwf'] as int,
      note: json['note'] as String? ?? '',
      status: _toBidStatus(json['status'] as String? ?? 'pending'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      jobTitle: job?['title'] as String?,
      jobCategory: job?['category'] as String?,
      jobLocation: job?['location'] as String?,
    );
  }

  static BidStatus _toBidStatus(String s) {
    switch (s) {
      case 'accepted':
        return BidStatus.accepted;
      case 'rejected':
        return BidStatus.rejected;
      default:
        return BidStatus.pending;
    }
  }

  static Review _toReview(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      artisanId: json['artisan_id'] as String,
      reviewerName: json['reviewer_name'] as String? ?? 'Anonymous',
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  static String _districtLabel(String district) {
    switch (district) {
      case 'gasabo':
        return 'Gasabo, Kigali';
      case 'kicukiro':
        return 'Kicukiro, Kigali';
      case 'nyarugenge':
        return 'Nyarugenge, Kigali';
      default:
        return 'Kigali, Rwanda';
    }
  }

  static ServiceCategory _toCategory(String s) {
    switch (s.toLowerCase()) {
      case 'plumbing':
        return ServiceCategory.plumbing;
      case 'electrical':
        return ServiceCategory.electrical;
      case 'painting':
        return ServiceCategory.painting;
      case 'carpentry':
        return ServiceCategory.carpentry;
      case 'cleaning':
        return ServiceCategory.cleaning;
      case 'masonry':
        return ServiceCategory.masonry;
      default:
        return ServiceCategory.plumbing;
    }
  }

  static JobStatus _toStatus(String s) {
    switch (s) {
      case 'requested':
        return JobStatus.requested;
      case 'quoted':
        return JobStatus.quoted;
      case 'booked':
        return JobStatus.booked;
      case 'on_the_way':
        return JobStatus.onTheWay;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      case 'cancelled':
        return JobStatus.cancelled;
      default:
        return JobStatus.requested;
    }
  }
}
