import "package:astro_tale/core/constants/app_colors.dart";
import "package:astro_tale/core/localization/app_localizations.dart";
import "package:astro_tale/core/widgets/animated_app_background.dart";
import "package:astro_tale/helper/chart_cache_helper.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:shimmer/shimmer.dart";
import "package:google_fonts/google_fonts.dart";

import "../../../../../../helper/Widgets/Pdf_downloader.dart";

// ─── Colour helpers ───────────────────────────────────────────────────────────

Color _planetColor(int idx) {
  const colors = [
    Color(0xFFF59E0B), // amber  – Sun
    Color(0xFF60A5FA), // blue   – Moon
    Color(0xFFEF4444), // red    – Mars
    Color(0xFF34D399), // green  – Mercury
    Color(0xFFA78BFA), // violet – Jupiter
    Color(0xFF94A3B8), // slate  – Saturn
    Color(0xFF38BDF8), // sky    – Rahu/Ketu
    Color(0xFFF472B6), // pink   – Venus
  ];
  return colors[idx % colors.length];
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class BirthChartResult extends StatefulWidget {
  const BirthChartResult({super.key, required this.chartData});

  final Map<String, dynamic> chartData;

  @override
  State<BirthChartResult> createState() => _BirthChartResultState();
}

class _BirthChartResultState extends State<BirthChartResult> {
  int _activeChartIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final chartImageCandidates = _chartImageCandidates();
    final chartImageUrl = chartImageCandidates.isEmpty
        ? ""
        : chartImageCandidates[_activeChartIndex.clamp(
            0,
            chartImageCandidates.length - 1,
          )];

    final houses      = _asMap(widget.chartData["houses"]);
    final planetsInfo = _asMap(widget.chartData["planets"]);
    final rashi       = widget.chartData["rashi"]?.toString()     ?? "";
    final nakshatra   = widget.chartData["nakshatra"]?.toString() ?? "";
    final ascendant   = _asMap(widget.chartData["ascendant"]);
    final ascSign     = ascendant["sign"]?.toString()             ?? "";
    final ascLongitude = (ascendant["longitude"] is num)
        ? (ascendant["longitude"] as num).toDouble()
        : 0.0;

    // ── shared colours ────────────────────────────────────────────────────────
    final cardBg = isDark ? const Color(0x7A1F2340) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor   = isDark ? Colors.white54 : const Color(0xFF64748B);
    final accentA    = isDark ? const Color(0xFFF6C65A) : colors.primary;
    final accentB    = isDark ? const Color(0xFF93C5FD) : colors.secondary;
    final accentC    = isDark ? const Color(0xFF6EE7B7) : colors.tertiary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _topBar(context, isDark),
      body: AnimatedAppBackground(
        showStarsInDark: true,
        showStarsInLight: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
            children: [

              // ── 1. Summary card ─────────────────────────────────────────────
              _Card(
                isDark: isDark,
                cardBg: cardBg,
                cardBorder: cardBorder,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 16, color: accentA),
                        const SizedBox(width: 8),
                        Text(
                          "Astro Profile",
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accentA,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _divider(isDark),
                    const SizedBox(height: 14),

                    // Rashi
                    _infoRow(
                      icon: Icons.circle,
                      iconColor: accentA,
                      label: context.l10n.tr("rashi"),
                      value: rashi,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 10),

                    // Nakshatra
                    _infoRow(
                      icon: Icons.star_rounded,
                      iconColor: accentB,
                      label: context.l10n.tr("nakshatra"),
                      value: nakshatra,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 10),

                    // Ascendant
                    _infoRow(
                      icon: Icons.arrow_upward_rounded,
                      iconColor: accentC,
                      label: context.l10n.tr("ascendant"),
                      value: "$ascSign (${ascLongitude.toStringAsFixed(2)} deg)",
                      titleColor: titleColor,
                      subColor: subColor,
                    ),

                    const SizedBox(height: 18),

                    // Download PDF button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF1E1538) : Colors.white,
                        ),
                        label: Text(
                          context.l10n.tr("downloadPdf"),
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF1E1538) : Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFFF6C65A) // vibrant yellow
                              : colors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: chartImageUrl.isEmpty
                            ? null
                            : () {
                                BirthChartPdfService.generateAndDownloadPdf(
                                  chartImageUrl: chartImageUrl,
                                  rashi: rashi,
                                  nakshatra: nakshatra,
                                  ascSign: ascSign,
                                  ascLongitude: ascLongitude,
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 2. Chart image card ──────────────────────────────────────────
              _Card(
                isDark: isDark,
                cardBg: cardBg,
                cardBorder: cardBorder,
                child: Column(
                  children: [
                    // Title row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grid_view_rounded, size: 15, color: accentA),
                        const SizedBox(width: 7),
                        Text(
                          context.l10n.tr("generatedBirthChart"),
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: accentA,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _divider(isDark),
                    const SizedBox(height: 14),

                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _chartImage(
                        isDark: isDark,
                        chartImageUrl: chartImageUrl,
                        chartImageCandidates: chartImageCandidates,
                        colors: colors,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 3. Houses section ────────────────────────────────────────────
              Text(
                "House Breakdown",
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: subColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              ...List.generate(houses.length, (index) {
                final houseNumber = (index + 1).toString();
                final data   = _asMap(houses[houseNumber]);
                final sign   = data["sign"]?.toString() ?? "";
                final planets = data["planets"] as List<dynamic>? ?? <dynamic>[];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _Card(
                    isDark: isDark,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // House title
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: accentA.withValues(alpha: isDark ? 0.18 : 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                houseNumber,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: accentA,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "House $houseNumber",
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            if (sign.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                "• $sign",
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: accentB,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),

                        if (planets.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: List.generate(planets.length, (pi) {
                              final planetKey = planets[pi].toString();
                              final planetSign = _asMap(planetsInfo[planetKey])["sign"]?.toString() ?? "";
                              final chipColor = _planetColor(pi);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: chipColor.withValues(alpha: isDark ? 0.15 : 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: chipColor.withValues(alpha: isDark ? 0.35 : 0.25),
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: planetKey,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: chipColor,
                                        ),
                                      ),
                                      if (planetSign.isNotEmpty)
                                        TextSpan(
                                          text: " ($planetSign)",
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: subColor,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              context.l10n.tr("noPlanets"),
                              style: GoogleFonts.dmSans(
                                fontSize: 12.5,
                                color: subColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _chartImage({
    required bool isDark,
    required String chartImageUrl,
    required List<String> chartImageCandidates,
    required ColorScheme colors,
  }) {
    if (chartImageUrl.isEmpty) {
      return _noChartWidget(isDark, colors);
    }
    if (chartImageUrl.endsWith(".svg")) {
      return SvgPicture.network(
        chartImageUrl,
        placeholderBuilder: (_) => _shimmer(isDark, 320),
      );
    }
    return CachedNetworkImage(
      imageUrl: chartImageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => _shimmer(isDark, 320),
      errorWidget: (_, __, ___) {
        if (_activeChartIndex < chartImageCandidates.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _activeChartIndex += 1);
          });
          return _retryingWidget(isDark);
        }
        return _noChartWidget(isDark, colors);
      },
    );
  }

  Widget _shimmer(bool isDark, double height) {
    return Shimmer.fromColors(
      baseColor:      isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(height: height, color: Colors.black12),
    );
  }

  Widget _retryingWidget(bool isDark) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Text(
          "Trying backup chart source…",
          style: GoogleFonts.dmSans(
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ),
    );
  }

  Widget _noChartWidget(bool isDark, ColorScheme colors) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset("assets/images/birthchart.png", fit: BoxFit.cover, height: 220),
        Container(
          color: Colors.black.withValues(alpha: 0.50),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            "Chart image unavailable",
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color titleColor,
    required Color subColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$label: ",
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider(bool isDark) => Container(
        height: 0.8,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2E8F0),
      );

  List<String> _chartImageCandidates() {
    final candidates = <String>[];
    final dynamic explicitCandidates = widget.chartData["chartImageCandidates"];
    if (explicitCandidates is List) {
      for (final item in explicitCandidates) {
        final url = item?.toString().trim() ?? "";
        if (url.isNotEmpty && !candidates.contains(url)) candidates.add(url);
      }
    }
    final explicitUrl = widget.chartData["chartImageUrl"]?.toString().trim() ?? "";
    if (explicitUrl.isNotEmpty && !candidates.contains(explicitUrl)) {
      candidates.add(explicitUrl);
    }
    final rawPath = widget.chartData["chartImage"]?.toString() ??
        widget.chartData["chart_image"]?.toString() ?? "";
    for (final url in ChartCacheHelper.resolveChartImageCandidates(rawPath)) {
      if (url.isNotEmpty && !candidates.contains(url)) candidates.add(url);
    }
    return candidates;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }
}

// ─── Reusable card ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.child,
  });

  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

PreferredSizeWidget _topBar(BuildContext context, bool isDark) {
  return AppBar(
    backgroundColor:
        isDark ? AppColors.appBarDark : AppColors.lightContainer,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0.8,
    centerTitle: true,
    leading: Padding(
      padding: const EdgeInsets.only(left: 12),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: SizedBox(
          height: 38,
          width: 38,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    ),
    title: Text(
      context.l10n.tr("birthChart"),
      style: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    ),
  );
}
