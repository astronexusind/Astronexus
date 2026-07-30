import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:astro_tale/core/theme/app_gradients.dart';
import 'package:astro_tale/services/api_services/subscription_service.dart';
import 'package:astro_tale/App/views/subscription/views/subscription_screen.dart';
/// Pending #7 (continuity doc, Section 8): wires the profile screen to
/// GET /api/subscription/status, which was previously not called from
/// anywhere in the app.
class SubscriptionStatusCard extends StatefulWidget {
  const SubscriptionStatusCard({super.key});

  @override
  State<SubscriptionStatusCard> createState() =>
      _SubscriptionStatusCardState();
}

class _SubscriptionStatusCardState extends State<SubscriptionStatusCard> {
  final SubscriptionService _service = SubscriptionService();

  bool _isLoading = true;
  bool _hasError = false;
  SubscriptionStatus? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final status = await _service.getStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Subscription status fetch error: $e");
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _openSubscriptionScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionPage()),
    );
    // Refresh in case the user just subscribed/cancelled.
    if (mounted) _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = AppGradients.glassFill(theme);
    final borderColor = AppGradients.glassBorder(theme);
    final titleColor = isDark ? Colors.white : theme.colorScheme.onSurface;
    final mutedColor = isDark
        ? Colors.white70
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: _openSubscriptionScreen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cardColor,
          border: Border.all(color: borderColor),
        ),
        child: _buildContent(titleColor, mutedColor, isDark),
      ),
    );
  }

  Widget _buildContent(Color titleColor, Color mutedColor, bool isDark) {
    if (_isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? Colors.white70 : titleColor,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            "Checking subscription…",
            style: GoogleFonts.dmSans(color: mutedColor, fontSize: 14),
          ),
        ],
      );
    }

    if (_hasError) {
      return Row(
        children: [
          Icon(LucideIcons.circle_alert, color: mutedColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Couldn't load subscription status. Tap to retry.",
              style: GoogleFonts.dmSans(color: mutedColor, fontSize: 14),
            ),
          ),
          Icon(LucideIcons.chevron_right, color: mutedColor, size: 20),
        ],
      );
    }

    final status = _status;
    final isActive = status?.isActive ?? false;

    if (isActive) {
      final planLabel = _planLabel(status?.plan);
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
            ),
            child: const Icon(
              LucideIcons.badge_check,
              color: Color(0xFF8B5CF6),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$planLabel Plan — Active",
                  style: GoogleFonts.dmSans(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (status?.expiryDisplay.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Text(
                    status!.expiryDisplay,
                    style: GoogleFonts.dmSans(color: mutedColor, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          Icon(LucideIcons.chevron_right, color: mutedColor, size: 20),
        ],
      );
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mutedColor.withValues(alpha: 0.14),
          ),
          child: Icon(LucideIcons.sparkles, color: mutedColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            "No active subscription — tap to explore plans",
            style: GoogleFonts.dmSans(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Icon(LucideIcons.chevron_right, color: mutedColor, size: 20),
      ],
    );
  }

  String _planLabel(String? planKey) {
    switch (planKey) {
      case "weekly":
        return "Weekly";
      case "monthly":
        return "Monthly";
      case "yearly":
        return "Yearly";
      default:
        return "";
    }
  }
}