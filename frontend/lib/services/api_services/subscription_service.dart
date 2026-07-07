// lib/services/api_services/subscription_service.dart
//
// Connects subscription screen to real backend API.
// Endpoints: GET /api/subscription/plans, GET /api/subscription/status,
//            POST /api/subscription/activate, POST /api/subscription/cancel

import 'package:astro_tale/core/constants/api_constants.dart';
import 'package:astro_tale/services/api_services/api_client.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class SubscriptionPlan {
  final String key;           // "weekly" | "monthly" | "yearly"
  final String name;          // "Weekly" | "Monthly" | "Yearly"
  final String displayPrice;  // "₹199"
  final int durationDays;     // 7 | 30 | 365
  final List<String> features;

  const SubscriptionPlan({
    required this.key,
    required this.name,
    required this.displayPrice,
    required this.durationDays,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      key:          json['key']          as String? ?? '',
      name:         json['name']         as String? ?? '',
      displayPrice: json['displayPrice'] as String? ?? '',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      features:     List<String>.from(json['features'] as List? ?? []),
    );
  }

  bool get isHighlighted => key == 'monthly';

  String get tagline {
    switch (key) {
      case 'weekly':  return 'Gentle start for guidance';
      case 'monthly': return 'Complete astrological support';
      case 'yearly':  return 'Deep long-term guidance';
      default:        return '';
    }
  }

  String get durationLabel {
    switch (key) {
      case 'weekly':  return '/ week';
      case 'monthly': return '/ month';
      case 'yearly':  return '/ year';
      default:        return '';
    }
  }
}

class SubscriptionStatus {
  final bool isActive;
  final String? plan;       // "weekly" | "monthly" | "yearly" | null
  final DateTime? expiresAt;

  const SubscriptionStatus({
    required this.isActive,
    this.plan,
    this.expiresAt,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>? ?? {};
    return SubscriptionStatus(
      isActive:  sub['isActive']  as bool? ?? false,
      plan:      sub['plan']      as String?,
      expiresAt: sub['expiresAt'] != null
          ? DateTime.tryParse(sub['expiresAt'].toString())
          : null,
    );
  }

  /// Human-readable expiry — e.g. "Active until Jul 26, 2026"
  String get expiryDisplay {
    if (!isActive || expiresAt == null) return '';
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return 'Active until ${months[expiresAt!.month - 1]} '
        '${expiresAt!.day}, ${expiresAt!.year}';
  }
}

// ─── Service ─────────────────────────────────────────────────────────────────

class SubscriptionService {
  final ApiClient _client = ApiClient();

  /// Fetch all active subscription plans from the backend.
  Future<List<SubscriptionPlan>> getPlans() async {
    // FIXED: Using /../ to step out of the /user base URL
    final data = await _client.get('/../api/subscription/plans');
    final list = data['plans'] as List? ?? [];
    return list
        .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get the current user's subscription status.
  Future<SubscriptionStatus> getStatus() async {
    // FIXED: Using /../ to step out of the /user base URL
    final data = await _client.get('/../api/subscription/status');
    return SubscriptionStatus.fromJson(data);
  }

  /// Activate a subscription after successful payment.
  /// In production this is called by the Razorpay webhook automatically.
  /// For now we call it directly after payment verification.
  Future<void> activate({
    required String planKey,
    required String paymentId,
    required String orderId,
    required int amountPaid,
  }) async {
    // FIXED: Using /../ to step out of the /user base URL
    await _client.post('/../api/subscription/activate', {
      'planKey':    planKey,
      'paymentId':  paymentId,
      'orderId':    orderId,
      'amountPaid': amountPaid,
    });
  }

  /// Cancel the current subscription.
  Future<void> cancel() async {
    // FIXED: Using /../ to step out of the /user base URL
    await _client.post('/../api/subscription/cancel', {});
  }
}