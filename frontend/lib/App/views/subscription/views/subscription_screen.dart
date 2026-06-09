import "package:astro_tale/core/localization/app_localizations.dart";
import "package:astro_tale/core/constants/app_colors.dart";
import "package:astro_tale/core/theme/app_gradients.dart";
import "package:astro_tale/core/widgets/animated_app_background.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class _PlanData {
  final String title;
  final String price;
  final String tagline;
  final List<String> features;
  final bool highlight;

  const _PlanData({
    required this.title,
    required this.price,
    required this.tagline,
    required this.features,
    this.highlight = false,
  });
}

const List<_PlanData> _plans = <_PlanData>[
  _PlanData(
    title: "Weekly",
    price: "₹199",
    tagline: "Gentle start for guidance",
    features: <String>[
      "Daily Horoscope",
      "Basic Insights",
      "Priority reminders",
    ],
  ),
  _PlanData(
    title: "Monthly",
    price: "₹699",
    tagline: "Complete astrological support",
    highlight: true,
    features: <String>[
      "Daily Horoscope",
      "Nutritional Astrology",
      "Exclusive Videos",
      "Chat Support",
    ],
  ),
  _PlanData(
    title: "Yearly",
    price: "₹6,999",
    tagline: "Deep long-term guidance",
    features: <String>[
      "All Monthly Features",
      "Priority Astrologer Support",
      "Premium Content",
    ],
  ),
];

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bool compact = screenWidth < 420;
    final bool wide = screenWidth >= 700;
    final double maxContentWidth = screenWidth < 980 ? 720 : 920;

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
              color: isDark ? Colors.black.withValues(alpha: 0.35) : AppColors.lightbox,
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 24,
                    vertical: 10,
                  ),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _header(context)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            l10n.tr("subscriptionHint"),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: isDark ? Colors.white70 : colors.onSurface.withValues(alpha: 0.72),
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
                            l10n.tr("subscriptionPlans"),
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
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: _plans.length,
                                itemBuilder: (context, index) {
                                  return ModernPlanCard(plan: _plans[index]);
                                },
                              )
                            : SliverList.separated(
                                itemCount: _plans.length,
                                itemBuilder: (context, index) {
                                  return ModernPlanCard(plan: _plans[index]);
                                },
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
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

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: "Close",
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
            context.l10n.tr("upgradeJourney"),
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

  Widget _promoBanner(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bannerHeight = screenWidth > 600 ? 180.0 : 150.0;

    return Container(
      height: bannerHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? const Color(0x7A1F2340) : colors.primary,
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        ),
        boxShadow: <BoxShadow>[
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
            right: -24,
            top: -24,
            child: Icon(
              Icons.auto_awesome,
              size: bannerHeight * 0.9,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -30,
            child: Icon(
              Icons.brightness_2,
              size: bannerHeight * 0.7,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Premium Cosmic Access",
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
                    "Unlock complete reports, daily insights, and priority astrologer support.",
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

class ModernPlanCard extends StatelessWidget {
  final _PlanData plan;

  const ModernPlanCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = isDark ? const Color(0x7A1F2340) : Colors.white;
    final borderColor = plan.highlight 
        ? (isDark ? const Color(0xFFF6C65A) : colors.primary.withValues(alpha: 0.8))
        : (isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0));
        
    final shadowColor = plan.highlight
        ? colors.primary.withValues(alpha: isDark ? 0.25 : 0.15)
        : Colors.black.withValues(alpha: isDark ? 0.3 : 0.05);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: cardColor,
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: shadowColor,
            blurRadius: plan.highlight ? 24 : 16,
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
                      plan.title,
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
                        color: isDark ? Colors.white.withValues(alpha: 0.72) : colors.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              if (plan.highlight)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFF6C65A) : colors.primary,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? const Color(0xFFF6C65A).withValues(alpha: 0.3)
                            : colors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Text(
                    context.l10n.tr("new"),
                    style: GoogleFonts.dmSans(
                      color: isDark ? const Color(0xFF1E1538) : colors.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              plan.price,
              style: GoogleFonts.dmSans(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : colors.primary,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...plan.features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isDark ? colors.primary.withValues(alpha: 0.2) : colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.check, size: 14, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: GoogleFonts.dmSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withValues(alpha: 0.88) : colors.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          )),
          const Spacer(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: plan.highlight ? 6 : 0,
                shadowColor: plan.highlight ? colors.primary.withValues(alpha: 0.5) : Colors.transparent,
                backgroundColor: plan.highlight 
                    ? (isDark ? const Color(0xFFF6C65A) : colors.primary) 
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : colors.primary.withValues(alpha: 0.08)),
                foregroundColor: plan.highlight 
                    ? (isDark ? const Color(0xFF1E1538) : colors.onPrimary) 
                    : (isDark ? Colors.white : colors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: plan.highlight 
                        ? Colors.transparent 
                        : (isDark ? Colors.white12 : colors.primary.withValues(alpha: 0.2)),
                  ),
                ),
              ),
              onPressed: () {},
              child: Text(
                context.l10n.tr("subscribe"),
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
}
