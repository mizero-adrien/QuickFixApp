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
  }) async {
    debugPrint('[SupabaseService] Updating artisan profile for $id');
    await _db.from('profiles').update({
      'name': name,
      'phone_number': phoneNumber,
      'district': district,
    }).eq('id', id);
    await _db.from('artisans').update({
      'trade': trade,
      'skills': skills,
      'years_of_experience': yearsOfExperience,
      'starting_price': startingPrice,
      'about': about,
    }).eq('id', id);
    debugPrint('[SupabaseService] Artisan profile updated');
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
  }) async {
    await _db.from('jobs').insert({
      'homeowner_id': homeownerId,
      'title': title,
      'description': description,
      'location': location,
      'category': category,
      'budget_rwf': budgetRwf,
      'status': 'requested',
    });
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
        .order('requested_at', ascending: false);
    return data.map<Job>(_toJob).toList();
  }

  static Future<List<Job>> getJobsByHomeowner(String homeownerId) async {
    final data = await _db
        .from('jobs')
        .select()
        .eq('homeowner_id', homeownerId)
        .order('requested_at', ascending: false);
    return data.map<Job>(_toJob).toList();
  }

  // ── Bids ──────────────────────────────────────────────────────────────────

  static Future<void> postBid({
    required String jobId,
    required String artisanId,
    required int amountRwf,
    required String note,
  }) async {
    await _db.from('bids').insert({
      'job_id': jobId,
      'artisan_id': artisanId,
      'amount_rwf': amountRwf,
      'note': note,
    });
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
        // RLS or missing row — still mark as artisan so they see the job list
        UserSession.userType = UserType.artisan;
        return;
      }

      if (artisanData != null) {
        UserSession.loginAsArtisan(_toArtisan(artisanData));
        debugPrint('[Session] Logged in as artisan: ${artisanData['trade']}');
      } else {
        debugPrint('[Session] Artisan row missing for ${user.id} — setting userType only');
        UserSession.userType = UserType.artisan;
      }
    } else {
      debugPrint('[Session] Unknown role: $role');
    }
  }

  // ── JSON parsers ──────────────────────────────────────────────────────────

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
    );
  }

  static Job _toJob(Map<String, dynamic> json) {
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
