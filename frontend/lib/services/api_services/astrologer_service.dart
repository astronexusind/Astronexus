// lib/services/api_services/astrologer_service.dart
//
// Connects the Flutter astrologer screen to the real backend API.
// Matches the existing ApiClient pattern used throughout the app.

import 'package:astro_tale/services/api_services/api_client.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class AstrologerPricing {
  final int chat;
  final int call;
  final int video;

  AstrologerPricing({
    required this.chat,
    required this.call,
    required this.video,
  });

  factory AstrologerPricing.fromJson(Map<String, dynamic> json) {
    return AstrologerPricing(
      chat:  (json['chat']  as num?)?.toInt() ?? 30,
      call:  (json['call']  as num?)?.toInt() ?? 50,
      video: (json['video'] as num?)?.toInt() ?? 80,
    );
  }
}

class Astrologer {
  final String id;
  final String name;
  final String profileImage;
  final List<String> specialties;
  final List<String> languages;
  final int experience;
  final String bio;
  final AstrologerPricing pricing;
  final double rating;
  final int totalReviews;
  final int totalSessions;
  final bool isOnline;

  Astrologer({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.specialties,
    required this.languages,
    required this.experience,
    required this.bio,
    required this.pricing,
    required this.rating,
    required this.totalReviews,
    required this.totalSessions,
    required this.isOnline,
  });

  factory Astrologer.fromJson(Map<String, dynamic> json) {
    return Astrologer(
      id:            json['_id'] as String? ?? '',
      name:          json['name'] as String? ?? 'Unknown',
      profileImage:  json['profileImage'] as String? ?? '',
      specialties:   List<String>.from(json['specialties'] as List? ?? []),
      languages:     List<String>.from(json['languages'] as List? ?? []),
      experience:    (json['experience'] as num?)?.toInt() ?? 0,
      bio:           json['bio'] as String? ?? '',
      pricing:       AstrologerPricing.fromJson(
                       json['pricing'] as Map<String, dynamic>? ?? {},
                     ),
      rating:        (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews:  (json['totalReviews'] as num?)?.toInt() ?? 0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      isOnline:      json['isOnline'] as bool? ?? false,
    );
  }

  /// Display helper — first specialty or 'Astrologer'
  String get primarySpecialty =>
      specialties.isNotEmpty ? specialties.first : 'Astrologer';

  /// Display helper — formatted rating
  String get ratingDisplay => rating.toStringAsFixed(1);

  /// Display helper — video rate per min
  String get videoRateDisplay => '₹${pricing.video}/min';
}

// ─── Service ─────────────────────────────────────────────────────────────────

class AstrologerService {
  final ApiClient _client = ApiClient();

  /// Fetch all verified astrologers.
  /// Pass [onlineOnly] = true to show only available astrologers.
  /// Pass [specialty] to filter by specialty (e.g. "Tarot", "Vedic").
  Future<List<Astrologer>> getAstrologers({
    bool onlineOnly = false,
    String? specialty,
    int page = 1,
    int limit = 20,
  }) async {
    final params = StringBuffer('/api/astrologer/list?page=$page&limit=$limit');
    if (onlineOnly) params.write('&online=true');
    if (specialty != null && specialty.isNotEmpty) {
      params.write('&specialty=$specialty');
    }

    final response = await _client.get(params.toString());
    final List<dynamic> list = response['astrologers'] as List? ?? [];
    return list
        .map((e) => Astrologer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single astrologer's full profile.
  Future<Astrologer> getAstrologer(String id) async {
    final response = await _client.get('/api/astrologer/$id');
    return Astrologer.fromJson(response['astrologer'] as Map<String, dynamic>);
  }

  /// Book a session. Returns bookingId and payment info.
  Future<Map<String, dynamic>> bookSession({
    required String astrologerId,
    required String sessionType, // 'chat' | 'call' | 'video'
    int durationMinutes = 30,
    String? userNote,
  }) async {
    return await _client.post('/api/astrologer/book', {
      'astrologerId':    astrologerId,
      'sessionType':     sessionType,
      'durationMinutes': durationMinutes,
      if (userNote != null) 'userNote': userNote,
    });
  }

  /// Get current user's booking history.
  Future<List<dynamic>> getMyBookings({String? status}) async {
    final path = status != null
        ? '/api/astrologer/my-bookings?status=$status'
        : '/api/astrologer/my-bookings';
    final response = await _client.get(path);
    return response['bookings'] as List? ?? [];
  }
}