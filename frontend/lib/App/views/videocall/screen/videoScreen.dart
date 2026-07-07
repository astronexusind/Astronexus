// lib/App/views/videocall/screen/videoScreen.dart
//
// CHANGES from original:
//   - Replaces all hardcoded fake data with real API calls
//   - Uses AstrologerService to fetch from GET /api/astrologer/list
//   - Featured astrologer = first online astrologer from API
//   - Grid = all remaining astrologers from API
//   - Category strip counts are real (counted from API response)
//   - Loading state, error state, and empty state added
//   - Star field animation kept exactly as original
//   - All visual design kept exactly as original

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../services/api_services/astrologer_service.dart';
import '../../../../ui_componets/cosmic/cosmic_one.dart';

class AstrologerListVideoScreen extends StatefulWidget {
  const AstrologerListVideoScreen({super.key});

  @override
  State<AstrologerListVideoScreen> createState() =>
      _AstrologerListVideoScreenState();
}

class _AstrologerListVideoScreenState extends State<AstrologerListVideoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _starController;
  late StarField _starField;

  final AstrologerService _service = AstrologerService();

  // State
  List<Astrologer> _astrologers = [];
  bool _loading = true;
  String? _error;
  String? _selectedSpecialty; // null = all

  // Derived
  Astrologer? get _featured =>
      _astrologers.where((a) => a.isOnline).firstOrNull ??
      _astrologers.firstOrNull;

  List<Astrologer> get _gridAstrologers =>
      _featured == null
          ? _astrologers
          : _astrologers.where((a) => a.id != _featured!.id).toList();

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
    _starField = StarField.generate(count: 90);
    _loadAstrologers();
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  Future<void> _loadAstrologers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.getAstrologers(
        specialty: _selectedSpecialty,
      );
      setState(() {
        _astrologers = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load astrologers. Please try again.';
        _loading = false;
      });
    }
  }

  // Count astrologers per specialty from API data
  int _countBySpecialty(String specialty) =>
      _astrologers.where((a) => a.specialties.contains(specialty)).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff050B1E),
      body: Stack(
        children: [
          // 🌌 Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff050B1E),
                  Color(0xff1C4D8D),
                  Color(0xff0F2854),
                  Color(0xff050B1E),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Positioned.fill(child: SmoothShootingStars()),

          // ⭐ Falling stars
          AnimatedBuilder(
            animation: _starController,
            builder: (_, __) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: StarPainter(
                  progress: _starController.value,
                  field: _starField,
                ),
              );
            },
          ),

          // 🌟 Foreground UI
          SafeArea(
            child: Column(
              children: [
                _glassAppBar(),
                Expanded(
                  child: _loading
                      ? _buildLoading()
                      : _error != null
                          ? _buildError()
                          : _astrologers.isEmpty
                              ? _buildEmpty()
                              : _buildContent(),
                ),
              ],
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
            'Finding astrologers...',
            style: TextStyle(color: Colors.white54, fontSize: 14),
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
          const Icon(LucideIcons.wifi_off, color: Colors.white38, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAstrologers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, color: Colors.white38, size: 48),
          SizedBox(height: 16),
          Text(
            'No astrologers available right now.\nCheck back soon!',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadAstrologers,
      color: Colors.white,
      backgroundColor: const Color(0xff0F2854),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _categoryStrip(),
            const SizedBox(height: 22),
            if (_featured != null) ...[
              _featuredAstrologer(_featured!),
              const SizedBox(height: 28),
            ],
            _sectionTitle(
              _selectedSpecialty != null
                  ? '$_selectedSpecialty Astrologers'
                  : 'Available Now',
            ),
            const SizedBox(height: 14),
            _astrologerGrid(),
          ],
        ),
      ),
    );
  }

  // 🔮 GLASS APP BAR — kept exactly as original
  Widget _glassAppBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        color: Colors.white.withOpacity(0.08),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                ),
                Text(
                  'Video Astrologers',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                // Online count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${_astrologers.where((a) => a.isOnline).length} online',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📊 CATEGORY STRIP — now uses real counts from API
  Widget _categoryStrip() {
    final categories = [
      {'title': 'All',       'count': _astrologers.length.toString()},
      {'title': 'Video',     'count': _astrologers.length.toString()},
      {'title': 'Tarot',     'count': _countBySpecialty('Tarot').toString()},
      {'title': 'Numerology','count': _countBySpecialty('Numerology').toString()},
      {'title': 'Marriage',  'count': _countBySpecialty('Marriage').toString()},
      {'title': 'Vedic',     'count': _countBySpecialty('Vedic').toString()},
    ];

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedSpecialty == cat['title'] ||
              (cat['title'] == 'All' && _selectedSpecialty == null);
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSpecialty =
                    (cat['title'] == 'All' || cat['title'] == 'Video')
                        ? null
                        : cat['title'];
              });
              _loadAstrologers();
            },
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [const Color(0xff1C4D8D), const Color(0xff0F2854)]
                      : [const Color(0xff0E1A2B), const Color(0xff020617)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white30 : Colors.white12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat['title']!,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${cat['count']} experts',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ⭐ FEATURED ASTROLOGER — now uses real data
  Widget _featuredAstrologer(Astrologer astrologer) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff0F2854),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: astrologer.profileImage.isNotEmpty
                ? Image.network(
                    astrologer.profileImage,
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarPlaceholder(90),
                  )
                : _avatarPlaceholder(90),
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
                        astrologer.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (astrologer.isOnline) _liveTag(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  astrologer.specialties.join(' • '),
                  style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '${astrologer.experience} years experience • ${astrologer.languages.first}',
                  style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white38),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _badge('⭐ ${astrologer.ratingDisplay}'),
                    const SizedBox(width: 8),
                    _badge(astrologer.videoRateDisplay),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _onBookTap(astrologer, 'video'),
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(LucideIcons.video, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 🧩 GRID — now uses real data
  Widget _astrologerGrid() {
    final grid = _gridAstrologers;
    if (grid.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Center(
          child: Text(
            'No other astrologers available',
            style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 14),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grid.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (_, i) => _gridCard(grid[i]),
    );
  }

  Widget _gridCard(Astrologer astrologer) {
    return GestureDetector(
      onTap: () => _onBookTap(astrologer, 'video'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xff002455).withOpacity(.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black54.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: astrologer.isOnline ? _liveTag() : _offlineTag(),
            ),
            const SizedBox(height: 6),
            astrologer.profileImage.isNotEmpty
                ? CircleAvatar(
                    radius: 38,
                    backgroundImage: NetworkImage(astrologer.profileImage),
                    onBackgroundImageError: (_, __) {},
                  )
                : _avatarPlaceholder(76, radius: 38),
            const SizedBox(height: 10),
            Text(
              astrologer.name,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              astrologer.primarySpecialty,
              style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white60),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  astrologer.videoRateDisplay,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.greenAccent,
                  ),
                ),
                const Icon(LucideIcons.video, color: Colors.white70, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Book session dialog ─────────────────────────────────────────────────────
  void _onBookTap(Astrologer astrologer, String sessionType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff0F2854),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _bookingSheet(astrologer, sessionType),
    );
  }

  Widget _bookingSheet(Astrologer astrologer, String sessionType) {
    int selectedDuration = 30;
    return StatefulBuilder(
      builder: (context, setSheetState) {
        final rate = sessionType == 'chat'
            ? astrologer.pricing.chat
            : sessionType == 'call'
                ? astrologer.pricing.call
                : astrologer.pricing.video;
        final total = rate * selectedDuration;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book session with ${astrologer.name}',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹$rate/min • ${astrologer.primarySpecialty}',
                style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white60),
              ),
              const SizedBox(height: 20),
              Text(
                'Select duration',
                style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Row(
                children: [15, 30, 45, 60].map((d) {
                  final isSelected = selectedDuration == d;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setSheetState(() => selectedDuration = d),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          '${d}m',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xff0F2854)
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ₹$total',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.greenAccent,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _confirmBooking(
                        astrologer,
                        sessionType,
                        selectedDuration,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmBooking(
    Astrologer astrologer,
    String sessionType,
    int duration,
  ) async {
    try {
      await _service.bookSession(
        astrologerId:    astrologer.id,
        sessionType:     sessionType,
        durationMinutes: duration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session booked with ${astrologer.name}!',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('subscription')
                  ? 'This feature requires a premium subscription'
                  : 'Booking failed. Please try again.',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Helper widgets ──────────────────────────────────────────────────────────
  Widget _liveTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _offlineTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'OFFLINE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white38,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white70),
      ),
    );
  }

  Widget _avatarPlaceholder(double size, {double? radius}) {
    return CircleAvatar(
      radius: radius ?? size / 2,
      backgroundColor: Colors.white12,
      child: Icon(
        LucideIcons.user,
        color: Colors.white38,
        size: size * 0.4,
      ),
    );
  }
}

/* ======================= */
/* ⭐ STAR SYSTEM — unchanged from original */
/* ======================= */

class StarField {
  final List<Offset> positions;
  final List<double> sizes;
  final List<double> speeds;

  StarField(this.positions, this.sizes, this.speeds);

  static StarField generate({int count = 80}) {
    final r = Random();
    return StarField(
      List.generate(count, (_) => Offset(r.nextDouble(), r.nextDouble())),
      List.generate(count, (_) => r.nextDouble() * 1.5 + 0.5),
      List.generate(count, (_) => r.nextDouble() * 400 + 60),
    );
  }
}

class StarPainter extends CustomPainter {
  final double progress;
  final StarField field;

  StarPainter({required this.progress, required this.field});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white24;
    for (int i = 0; i < field.positions.length; i++) {
      final x = field.positions[i].dx * size.width;
      final y = (field.positions[i].dy * size.height +
              progress * field.speeds[i]) %
          size.height;
      canvas.drawCircle(Offset(x, y), field.sizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarPainter oldDelegate) => true;
}