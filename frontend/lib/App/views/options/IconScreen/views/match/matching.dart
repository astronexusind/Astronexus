import 'dart:convert';
import 'package:astro_tale/App/views/Auth/sharedWidgets/place_suggestion_sheet.dart';
import 'package:astro_tale/core/theme/app_gradients.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:astro_tale/App/views/options/IconScreen/views/match/result/matchingScore.dart';
import '../../../../../../core/widgets/animated_app_background.dart';
import '../../../../../../services/API/APIservice.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with TickerProviderStateMixin {
  // ───────── Controllers ─────────
  final mName = TextEditingController();
  final mDob = TextEditingController();
  final mTime = TextEditingController();
  final mPlace = TextEditingController();

  final fName = TextEditingController();
  final fDob = TextEditingController();
  final fTime = TextEditingController();
  final fPlace = TextEditingController();

  final mYear = TextEditingController();
  final mMonth = TextEditingController();
  final mDate = TextEditingController();
  final mHour = TextEditingController();
  final mMinute = TextEditingController();
  final mSecond = TextEditingController();
  final mLat = TextEditingController();
  final mLng = TextEditingController();
  final mTz = TextEditingController();

  final fYear = TextEditingController();
  final fMonth = TextEditingController();
  final fDate = TextEditingController();
  final fHour = TextEditingController();
  final fMinute = TextEditingController();
  final fSecond = TextEditingController();
  final fLat = TextEditingController();
  final fLng = TextEditingController();
  final fTz = TextEditingController();

  bool isLoading = false;
  bool showMale = true; // true = Male form, false = Female form

  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (final controller in [
      mName,
      mDob,
      mTime,
      mPlace,
      fName,
      fDob,
      fTime,
      fPlace,
      mYear,
      mMonth,
      mDate,
      mHour,
      mMinute,
      mSecond,
      mLat,
      mLng,
      mTz,
      fYear,
      fMonth,
      fDate,
      fHour,
      fMinute,
      fSecond,
      fLat,
      fLng,
      fTz,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  // ───────── Date & Time Pickers ─────────
  ThemeData _buildPickerTheme(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final pickerSurface = isDark
        ? const Color(0xFF171B33)
        : theme.colorScheme.surface;
    final headerBackground = isDark ? const Color(0xFF23264A) : colors.primary;
    final headerForeground = isDark ? Colors.white : colors.onPrimary;
    final selectedFill = isDark ? const Color(0xFFF6C65A) : colors.primary;
    final selectedForeground = isDark
        ? const Color(0xFF1B1535)
        : colors.onPrimary;
    final dayTextColor = isDark ? Colors.white : colors.onSurface;
    final mutedTextColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final outlineColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFFD6E3F6);

    return theme.copyWith(
      colorScheme: colors.copyWith(
        primary: selectedFill,
        onPrimary: selectedForeground,
        surface: pickerSurface,
        onSurface: dayTextColor,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: pickerSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: pickerSurface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: headerBackground,
        headerForegroundColor: headerForeground,
        weekdayStyle: GoogleFonts.dmSans(
          color: mutedTextColor,
          fontWeight: FontWeight.w700,
        ),
        dayStyle: GoogleFonts.dmSans(
          color: dayTextColor,
          fontWeight: FontWeight.w500,
        ),
        yearStyle: GoogleFonts.dmSans(
          color: dayTextColor,
          fontWeight: FontWeight.w600,
        ),
        dividerColor: outlineColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedForeground;
          }
          if (states.contains(WidgetState.disabled)) {
            return mutedTextColor.withValues(alpha: 0.45);
          }
          return dayTextColor;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedFill;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedForeground;
          }
          return dayTextColor;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedFill;
          }
          return isDark
              ? const Color(0xFFF6C65A).withValues(alpha: 0.18)
              : colors.primary.withValues(alpha: 0.12);
        }),
        todayBorder: BorderSide(
          color: isDark ? const Color(0xFFF6C65A) : colors.primary,
        ),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedForeground;
          }
          return dayTextColor;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedFill;
          }
          return Colors.transparent;
        }),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: mutedTextColor,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFFF6C65A) : colors.primary,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: pickerSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        hourMinuteColor: isDark
            ? const Color(0xFF23264A)
            : colors.surfaceContainerHighest,
        hourMinuteTextColor: dayTextColor,
        dayPeriodColor: isDark
            ? const Color(0xFF23264A)
            : colors.surfaceContainerHighest,
        dayPeriodTextColor: dayTextColor,
        dialBackgroundColor: isDark
            ? const Color(0xFF23264A)
            : colors.surfaceContainerHighest,
        dialHandColor: selectedFill,
        dialTextColor: dayTextColor,
        entryModeIconColor: selectedFill,
        helpTextStyle: GoogleFonts.dmSans(
          color: mutedTextColor,
          fontWeight: FontWeight.w700,
        ),
        hourMinuteTextStyle: GoogleFonts.dmSans(
          color: dayTextColor,
          fontWeight: FontWeight.w700,
        ),
        dayPeriodTextStyle: GoogleFonts.dmSans(
          color: dayTextColor,
          fontWeight: FontWeight.w700,
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: mutedTextColor,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFFF6C65A) : colors.primary,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFFF6C65A) : colors.primary,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _pickDate(
    TextEditingController display,
    TextEditingController year,
    TextEditingController month,
    TextEditingController date,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(data: _buildPickerTheme(theme), child: child!);
      },
    );

    if (picked != null) {
      display.text =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      year.text = picked.year.toString();
      month.text = picked.month.toString();
      date.text = picked.day.toString();
      setState(() {});
    }
  }

  Future<void> _pickTime(
    TextEditingController display,
    TextEditingController hour,
    TextEditingController minute,
    TextEditingController second,
  ) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(data: _buildPickerTheme(theme), child: child!);
      },
    );

    if (picked != null) {
      display.text =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      hour.text = picked.hour.toString();
      minute.text = picked.minute.toString();
      second.text = "0";
      setState(() {});
    }
  }

  // ───────── API Logic ─────────
  Future<void> _checkCompatibility() async {
    FocusScope.of(context).unfocus();

    final maleMissing = _missingVisibleFields(
      name: mName,
      dob: mDob,
      time: mTime,
      place: mPlace,
    );
    if (maleMissing.isNotEmpty) {
      if (!showMale) {
        setState(() => showMale = true);
      }
      _showError("Please fill male ${maleMissing.first}.");
      return;
    }

    final femaleMissing = _missingVisibleFields(
      name: fName,
      dob: fDob,
      time: fTime,
      place: fPlace,
    );
    if (femaleMissing.isNotEmpty) {
      if (showMale) {
        setState(() => showMale = false);
      }
      _showError("Please fill female ${femaleMissing.first}.");
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await _resolvePlace(mPlace.text, mLat, mLng, mTz, 19.0760, 72.8777);
      await _resolvePlace(fPlace.text, fLat, fLng, fTz, 28.6139, 77.2090);

      final generatedFields = [
        mYear,
        mMonth,
        mDate,
        mHour,
        mMinute,
        mSecond,
        mLat,
        mLng,
        mTz,
        fYear,
        fMonth,
        fDate,
        fHour,
        fMinute,
        fSecond,
        fLat,
        fLng,
        fTz,
      ];

      final hasEmptyGeneratedField = generatedFields.any(
        (controller) => controller.text.trim().isEmpty,
      );
      if (hasEmptyGeneratedField) {
        _showError("Please reselect the birth details and try again.");
        return;
      }

      final hasInvalidNumber = generatedFields.any(
        (controller) => double.tryParse(controller.text.trim()) == null,
      );
      if (hasInvalidNumber) {
        _showError(
          "Some birth details are invalid. Please check and try again.",
        );
        return;
      }

      final body = {
        "male": _buildPerson(
          mName,
          mYear,
          mMonth,
          mDate,
          mHour,
          mMinute,
          mSecond,
          mLat,
          mLng,
          mTz,
        ),
        "female": _buildPerson(
          fName,
          fYear,
          fMonth,
          fDate,
          fHour,
          fMinute,
          fSecond,
          fLat,
          fLng,
          fTz,
        ),
        "config": {
          "observation_point": "topocentric",
          "language": "en",
          "ayanamsha": "lahiri",
        },
      };

      final res = await http.post(
        Uri.parse("$baseurl/api/v1/compatibility/match-making/ashtakoot-score"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MatchingScoreScreen(output: data["data"]["output"]),
          ),
        );
      } else {
        _showError(data["message"] ?? "Compatibility failed");
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<String> _missingVisibleFields({
    required TextEditingController name,
    required TextEditingController dob,
    required TextEditingController time,
    required TextEditingController place,
  }) {
    final missing = <String>[];
    if (name.text.trim().isEmpty) missing.add("name");
    if (dob.text.trim().isEmpty) missing.add("date of birth");
    if (time.text.trim().isEmpty) missing.add("time of birth");
    if (place.text.trim().isEmpty) missing.add("place of birth");
    return missing;
  }

  Map<String, dynamic> _buildPerson(
    TextEditingController name,
    TextEditingController year,
    TextEditingController month,
    TextEditingController date,
    TextEditingController hour,
    TextEditingController minute,
    TextEditingController second,
    TextEditingController lat,
    TextEditingController lng,
    TextEditingController tz,
  ) => {
    "name": name.text,
    "year": int.tryParse(year.text) ?? 0,
    "month": int.tryParse(month.text) ?? 0,
    "date": int.tryParse(date.text) ?? 0,
    "hours": int.tryParse(hour.text) ?? 0,
    "minutes": int.tryParse(minute.text) ?? 0,
    "seconds": int.tryParse(second.text) ?? 0,
    "latitude": double.tryParse(lat.text) ?? 0.0,
    "longitude": double.tryParse(lng.text) ?? 0.0,
    "timezone": double.tryParse(tz.text) ?? 0.0,
  };

  Future<void> _resolvePlace(
    String place,
    TextEditingController lat,
    TextEditingController lng,
    TextEditingController tz,
    double fallbackLat,
    double fallbackLng,
  ) async {
    try {
      final locations = await locationFromAddress(place);
      if (locations.isNotEmpty) {
        lat.text = locations.first.latitude.toString();
        lng.text = locations.first.longitude.toString();
        tz.text = "5.5";
      } else {
        lat.text = fallbackLat.toString();
        lng.text = fallbackLng.toString();
        tz.text = "5.5";
      }
    } catch (_) {
      lat.text = fallbackLat.toString();
      lng.text = fallbackLng.toString();
      tz.text = "5.5";
    }
  }

  Future<void> _pickBirthPlace(
    TextEditingController place,
    TextEditingController lat,
    TextEditingController lng,
    TextEditingController tz,
    double fallbackLat,
    double fallbackLng,
  ) async {
    final selected = await showPlaceSuggestionSheet(
      context: context,
      title: "Select Place of Birth",
      initialValue: place.text,
    );
    if (selected == null || selected.trim().isEmpty) {
      return;
    }

    place.text = selected.trim();
    await _resolvePlace(place.text, lat, lng, tz, fallbackLat, fallbackLng);
    if (mounted) {
      setState(() {});
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.blueGrey.shade900, content: Text(msg)),
    );
  }

  // ───────── Glass Input Field ─────────
  Widget _glassInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppGradients.glassFill(theme),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppGradients.glassBorder(theme)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        validator: (value) =>
            value == null || value.trim().isEmpty ? "Required" : null,
        style: GoogleFonts.dmSans(
          color: isDark ? Colors.white : colors.onSurface,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppGradients.glassFill(theme),
          prefixIcon: Icon(icon, color: colors.primary),
          hintText: label,
          hintStyle: GoogleFonts.dmSans(
            color: isDark ? Colors.white70 : colors.onSurface.withOpacity(0.6),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _modernMatchAppBar(context),
      body: AnimatedAppBackground(
        showStarsInDark: true,
        showStarsInLight: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 380;
              final double cardMaxWidth = constraints.maxWidth < 560
                  ? constraints.maxWidth
                  : 520;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 20,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardMaxWidth),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.18)
                              : const Color(0xFFD6E3F6),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.55)
                                : const Color(0xFF7B91B8).withOpacity(0.9),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF3A4570).withOpacity(0.95),
                                  const Color(0xFF2D365E).withOpacity(0.95),
                                ]
                              : [
                                  Colors.white.withOpacity(0.98),
                                  const Color(0xFFF3F7FF).withOpacity(0.98),
                                ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  "Matching",
                                  style: GoogleFonts.dmSans(
                                    fontSize: compact ? 22 : 24,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Evaluate cosmic harmony & compatibility",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  color: isDark
                                      ? Colors.white70
                                      : colors.onSurface.withOpacity(0.72),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _genderToggle(),
                              const SizedBox(height: 18),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                                child: showMale ? _maleForm() : _femaleForm(),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : _checkCompatibility,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? const Color(0xFFF6C65A)
                                        : colors.primary,
                                    foregroundColor: isDark
                                        ? const Color(0xFF1B1535)
                                        : colors.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                    ),
                                  ),
                                  child: isLoading
                                      ? LoadingAnimationWidget.fourRotatingDots(
                                          color: isDark
                                              ? const Color(0xFF1B1535)
                                              : colors.onPrimary,
                                          size: 32,
                                        )
                                      : Text(
                                          "Check Compatibility",
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Modern glassy app bar for MatchingScreen
  PreferredSizeWidget _modernMatchAppBar(BuildContext context) {
    // Always use a dark app bar with white text/icons for consistency
    return AppBar(
      backgroundColor: const Color(0xFF23264A),
      elevation: 0,
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
              color: Colors.white,
            ),
          ),
        ),
      ),
      title: Text(
        "Matching",
        style: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _maleForm() {
    final cardColor = const Color(0xFF23264A);
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Male Details",
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _glassInputField(
            label: "Full Name",
            icon: Icons.person_outline,
            controller: mName,
            onChanged: (v) {},
          ),
          const SizedBox(height: 12),
          _glassInputField(
            label: "Date of Birth",
            icon: Icons.calendar_today_outlined,
            controller: mDob,
            readOnly: true,
            onTap: () => _pickDate(mDob, mYear, mMonth, mDate),
            onChanged: (v) {
              // If user clears DOB, clear hidden fields
              if (v.isEmpty) {
                mYear.text = '';
                mMonth.text = '';
                mDate.text = '';
              }
            },
          ),
          const SizedBox(height: 12),
          _glassInputField(
            label: "Time of Birth",
            icon: Icons.access_time_outlined,
            controller: mTime,
            readOnly: true,
            onTap: () => _pickTime(mTime, mHour, mMinute, mSecond),
            onChanged: (v) {
              if (v.isEmpty) {
                mHour.text = '';
                mMinute.text = '';
                mSecond.text = '';
              }
            },
          ),
          const SizedBox(height: 12),
          _glassInputField(
            label: "Place of Birth",
            icon: Icons.location_on,
            controller: mPlace,
            readOnly: true,
            onTap: () =>
                _pickBirthPlace(mPlace, mLat, mLng, mTz, 19.0760, 72.8777),
          ),
        ],
      ),
    );
  }

  Widget _femaleForm() {
    final cardColor = const Color(0xFF23264A);
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Female Details",
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _glassInputField(
            label: "Full Name",
            icon: Icons.person_outline,
            controller: fName,
            onChanged: (v) {},
          ),
          const SizedBox(height: 12),
          _glassInputField(
            label: "Date of Birth",
            icon: Icons.calendar_today_outlined,
            controller: fDob,
            readOnly: true,
            onTap: () => _pickDate(fDob, fYear, fMonth, fDate),
            onChanged: (v) {
              if (v.isEmpty) {
                fYear.text = '';
                fMonth.text = '';
                fDate.text = '';
              }
            },
          ),
          const SizedBox(height: 12),
          _glassInputField(
            label: "Time of Birth",
            icon: Icons.access_time_outlined,
            controller: fTime,
            readOnly: true,
            onTap: () => _pickTime(fTime, fHour, fMinute, fSecond),
            onChanged: (v) {
              if (v.isEmpty) {
                fHour.text = '';
                fMinute.text = '';
                fSecond.text = '';
              }
            },
          ),
          const SizedBox(height: 12),
          _glassInputField(
            label: "Place of Birth",
            icon: Icons.location_on,
            controller: fPlace,
            readOnly: true,
            onTap: () =>
                _pickBirthPlace(fPlace, fLat, fLng, fTz, 28.6139, 77.2090),
          ),
        ],
      ),
    );
  }

  Widget _genderToggle() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppGradients.glassFill(theme),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppGradients.glassBorder(theme)),
      ),
      child: Row(
        children: [_toggleButton("Male", true), _toggleButton("Female", false)],
      ),
    );
  }

  Widget _toggleButton(String label, bool value) {
    final isSelected = showMale == value;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => showMale = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? colors.onPrimary
                  : colors.onSurface.withOpacity(0.72),
            ),
          ),
        ),
      ),
    );
  }
}
