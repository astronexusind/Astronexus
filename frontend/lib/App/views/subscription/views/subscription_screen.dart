// lib/App/views/subscription/views/subscription_screen.dart
//
// CHANGES from original:
//   - Plans fetched from GET /api/subscription/plans (not hardcoded)
//   - User's current subscription status fetched and displayed
//   - Subscribe button triggers payment flow (Razorpay ready)
//   - Loading state, error state, retry added
//   - Active plan shown with a green "Your Plan" badge
//   - Cancel subscription option shown if user is subscribed
//   - All visual design kept exactly as original

import 'package:astro_tale/core/localization/app_localizations.dart';
import 'package:astro_tale/core/constants/app_colors.dart';
import 'package:astro_tale/core/widgets/animated_app_background.dart';
import 'package:astro_tale/services/api_services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_web/razorpay_web.dart';
import 'package:astro_tale/services/api_services/api_client.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  // ── State Variables ────────────────────────────────────────────────────────
  final SubscriptionService _service = SubscriptionService();
  late Razorpay _razorpay;
  
  List<SubscriptionPlan> _plans = [];
  SubscriptionStatus? _status;
  SubscriptionPlan? _processingPlan; 
  int? _processingAmount; 
  
  bool _loading = true;
  bool _subscribing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize Razorpay
    _razorpay = Razorpay();

    // Attach Event Listeners
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    // Load subscription data
    _load();
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clean up when screen closes
    super.dispose();
  }

  // ─── Data Loading ────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getPlans(),
        _service.getStatus(),
      ]);
      setState(() {
        _plans   = results[0] as List<SubscriptionPlan>;
        _status  = results[1] as SubscriptionStatus;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error   = 'Could not load plans. Please try again.';
        _loading = false;
      });
    }
  }

  // ── EVENT HANDLERS ──────────────────────────────────────────────────────────
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("SUCCESS: ${response.paymentId} | Signature: ${response.signature}");
    
    if (_processingPlan == null || _processingAmount == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verifying payment... Please wait.")),
      );

      // Call the backend to activate the subscription
      await _service.activate(
        planKey: _processingPlan!.key,
        paymentId: response.paymentId!,
        orderId: response.orderId!, // Razorpay sends the orderId back on success
        amountPaid: _processingAmount!, 
      );

      // Refresh the UI to show the active plan
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment Successful! Your plan is now active."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Activation Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment successful, but activation failed. Contact support."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      _processingPlan = null;
      _processingAmount = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("ERROR: ${response.code} - ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment Failed: ${response.message ?? 'Unknown error'}"),
        backgroundColor: Colors.redAccent,
      ),
    );
    _processingPlan = null;
    _processingAmount = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("WALLET: ${response.walletName}");
  }

  // ── Subscribe button handler ──────────────────────────────────────────────
  Future<void> _onSubscribe(SubscriptionPlan plan) async {
    if (_subscribing) return;
    setState(() => _subscribing = true);

    try {
      // 1. Extract the number from the display price (e.g., "₹199" -> 199)
      final priceString = plan.displayPrice.replaceAll(RegExp(r'[^0-9]'), '');
      final amountInRupees = int.parse(priceString);

      // Save for the success handler
      _processingPlan = plan;
      _processingAmount = amountInRupees;

      // 2. Call POST /payment/create to get Razorpay orderId
      final response = await ApiClient().post('/payment/create', {
        'amount': amountInRupees,
        'purpose': 'subscription',
        'planKey': plan.key,
      });

      final orderId = response['order']['id'];
      final keyId = response['order']['keyId'];

      // 3. Open Razorpay checkout
      var options = {
        'key': keyId,
        'amount': amountInRupees * 100, // Razorpay UI requires paise
        'name': 'AstroNexus',
        'description': '${plan.name} Subscription',
        'order_id': orderId,
        'prefill': {
          'contact': '9876543210', // Can be dynamically filled later
          'email': 'user@astronexus.com'
        },
      };

      _razorpay.open(options, context: context);

    } catch (e) {
      print('Error launching Razorpay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to initialize payment. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  // ── Cancel subscription handler ───────────────────────────────────────────
  Future<void> _onCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff1F2340),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel subscription?',
          style: GoogleFonts.dmSans(
            color: Colors.white,

            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You will lose access to premium features. '
          'Your subscription will remain active until '
          '${_status?.expiryDisplay ?? 'the end of the billing period'}.',
          style: GoogleFonts.dmSans(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Keep plan',
              style: GoogleFonts.dmSans(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Cancel plan',
              style: GoogleFonts.dmSans(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _subscribing = true);
      await _service.cancel();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Subscription cancelled.',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to cancel. Please try again.',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme         = Theme.of(context);
    final colors        = theme.colorScheme;
    final isDark        = theme.brightness == Brightness.dark;
    final screenWidth   = MediaQuery.sizeOf(context).width;
    final bool compact  = screenWidth < 420;
    final bool wide     = screenWidth >= 700;
    final double maxW   = screenWidth < 980 ? 720 : 920;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AnimatedAppBackground(
              showStarsInDark: true,
              showGlow: true,
              child: SizedBox(),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : AppColors.lightbox,
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 24,
                    vertical: 10,
                  ),
                  child: _loading
                      ? _buildLoading()
                      : _error != null
                          ? _buildError()
                          : CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(child: _header(context)),
                                if (_status?.isActive == true)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: _activeSubscriptionBanner(),
                                    ),
                                  ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      context.l10n.tr('subscriptionHint'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.dmSans(
                                        color: isDark
                                            ? Colors.white70
                                            : colors.onSurface.withValues(alpha: 0.72),
                                        fontSize: compact ? 13 : 14,
                                        height: 1.55,
                                      ),
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 22),
                                    child: _promoBanner(context),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 32),
                                    child: Text(
                                      context.l10n.tr('subscriptionPlans'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.dmSans(
                                        color: isDark ? Colors.white : colors.onSurface,
                                        fontSize: compact ? 20 : 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.only(top: 18, bottom: 32),
                                  sliver: wide
                                      ? SliverGrid.builder(
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 16,
                                            crossAxisSpacing: 16,
                                            childAspectRatio: 0.78,
                                          ),
                                          itemCount: _plans.length,
                                          itemBuilder: (_, i) => ModernPlanCard(
                                            plan:          _plans[i],
                                            isCurrentPlan: _status?.plan == _plans[i].key,
                                            isSubscribed:  _status?.isActive == true,
                                            onSubscribe:   () => _onSubscribe(_plans[i]),
                                          ),
                                        )
                                      : SliverList.separated(
                                          itemCount: _plans.length,
                                          itemBuilder: (_, i) => ModernPlanCard(
                                            plan:          _plans[i],
                                            isCurrentPlan: _status?.plan == _plans[i].key,
                                            isSubscribed:  _status?.isActive == true,
                                            onSubscribe:   () => _onSubscribe(_plans[i]),
                                          ),
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 16),
                                        ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Active subscription banner ────────────────────────────────────────────
  Widget _activeSubscriptionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.greenAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have an active ${_status?.plan?.toUpperCase() ?? ''} plan',
                  style: GoogleFonts.dmSans(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (_status?.expiryDisplay.isNotEmpty == true)
                  Text(
                    _status!.expiryDisplay,
                    style: GoogleFonts.dmSans(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _onCancel,
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                color: Colors.redAccent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'Loading plans...',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── Header (unchanged from original) ─────────────────────────────────────
  Widget _header(BuildContext context) {
    final theme  = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.close,
                color: isDark ? Colors.white : colors.primary,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 52),
          child: Text(
            context.l10n.tr('upgradeJourney'),
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: isDark ? Colors.white : colors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ── Promo banner (unchanged from original) ────────────────────────────────
  Widget _promoBanner(BuildContext context) {
    final theme       = Theme.of(context);
    final isDark      = theme.brightness == Brightness.dark;
    final colors      = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final height      = screenWidth > 600 ? 180.0 : 150.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? const Color(0x7A1F2340) : colors.primary,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24, top: -24,
            child: Icon(Icons.auto_awesome,
                size: height * 0.9,
                color: Colors.white.withValues(alpha: 0.15)),
          ),
          Positioned(
            left: -10, bottom: -30,
            child: Icon(Icons.brightness_2,
                size: height * 0.7,
                color: Colors.white.withValues(alpha: 0.12)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Premium Cosmic Access',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: screenWidth < 380 ? 20 : 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock complete reports, daily insights, '
                    'and priority astrologer support.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: screenWidth < 380 ? 13 : 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plan card ───────────────────────────────────────────────────────────────

class ModernPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrentPlan;
  final bool isSubscribed;
  final VoidCallback onSubscribe;

  const ModernPlanCard({
    super.key,
    required this.plan,
    required this.isCurrentPlan,
    required this.isSubscribed,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colors      = theme.colorScheme;
    final isDark      = theme.brightness == Brightness.dark;
    final cardColor   = isDark ? const Color(0x7A1F2340) : Colors.white;
    final borderColor = isCurrentPlan
        ? Colors.greenAccent.withValues(alpha: 0.8)
        : plan.isHighlighted
            ? (isDark
                ? const Color(0xFFF6C65A)
                : colors.primary.withValues(alpha: 0.8))
            : (isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFE2E8F0));
    final shadowColor = plan.isHighlighted
        ? colors.primary.withValues(alpha: isDark ? 0.25 : 0.15)
        : Colors.black.withValues(alpha: isDark ? 0.3 : 0.05);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: cardColor,
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: plan.isHighlighted ? 24 : 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.tagline,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.72)
                            : colors.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge: "Your Plan" if active, "Popular" if highlighted
              if (isCurrentPlan)
                _badge('Your Plan', Colors.greenAccent, const Color(0xFF0D2015))
              else if (plan.isHighlighted)
                _badge(
                  context.l10n.tr('new'),
                  isDark ? const Color(0xFF1E1538) : colors.onPrimary,
                  isDark ? const Color(0xFFF6C65A) : colors.primary,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: plan.displayPrice,
                    style: GoogleFonts.dmSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : colors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                  TextSpan(
                    text: plan.durationLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white54
                          : colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...plan.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.primary.withValues(alpha: 0.2)
                        : colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.check, size: 14, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    f,
                    style: GoogleFonts.dmSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.88)
                          : colors.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: plan.isHighlighted ? 6 : 0,
                shadowColor: plan.isHighlighted
                    ? colors.primary.withValues(alpha: 0.5)
                    : Colors.transparent,
                backgroundColor: isCurrentPlan
                    ? Colors.green.withValues(alpha: 0.2)
                    : plan.isHighlighted
                        ? (isDark ? const Color(0xFFF6C65A) : colors.primary)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : colors.primary.withValues(alpha: 0.08)),
                foregroundColor: isCurrentPlan
                    ? Colors.greenAccent
                    : plan.isHighlighted
                        ? (isDark ? const Color(0xFF1E1538) : colors.onPrimary)
                        : (isDark ? Colors.white : colors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isCurrentPlan
                        ? Colors.greenAccent.withValues(alpha: 0.4)
                        : plan.isHighlighted
                            ? Colors.transparent
                            : (isDark
                                ? Colors.white12
                                : colors.primary.withValues(alpha: 0.2)),
                  ),
                ),
              ),
              // Disable button if this is already the active plan
              onPressed: isCurrentPlan ? null : onSubscribe,
              child: Text(
                isCurrentPlan
                    ? 'Current Plan ✓'
                    : context.l10n.tr('subscribe'),
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}