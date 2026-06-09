import 'dart:async';
import 'dart:convert';
import 'package:astro_tale/App/Model/place/place_suggestion.dart';
import 'package:astro_tale/App/views/Auth/Sign_up/services/city_services.dart';
import 'package:astro_tale/App/views/Home/others/output/birthchart/birthchart_result.dart';
import 'package:astro_tale/core/constants/api_constants.dart';
import 'package:astro_tale/core/constants/app_colors.dart';
import 'package:astro_tale/core/localization/app_localizations.dart';
import 'package:astro_tale/core/theme/app_gradients.dart';
import 'package:astro_tale/core/widgets/animated_app_background.dart';
import 'package:astro_tale/helper/chart_cache_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirthChartScreen extends StatefulWidget {
  const BirthChartScreen({super.key});

  @override
  State<BirthChartScreen> createState() => _BirthChartScreenState();
}

class _BirthChartScreenState extends State<BirthChartScreen> {
  final nameController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final placeController = TextEditingController();

  String gender = 'male';
  String astrologyType = 'vedic';
  String ayanamsa = 'lahiri';
  bool isLoading = false;
  Timer? _debounce;
  Iterable<PlaceSuggestion> _lastOptions = const Iterable<PlaceSuggestion>.empty();

  @override
  void dispose() {
    _debounce?.cancel();
    nameController.dispose();
    dateController.dispose();
    timeController.dispose();
    placeController.dispose();
    super.dispose();
  }

  /// ================= PICKER THEME =================
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

  /// ================= DATE PICKER =================
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: "SELECT BIRTH DATE",
      cancelText: "CANCEL",
      confirmText: "OK",
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(data: _buildPickerTheme(theme), child: child!);
      },
    );

    if (picked != null) {
      dateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  /// ================= TIME PICKER =================
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: "SELECT BIRTH TIME",
      cancelText: "CANCEL",
      confirmText: "OK",
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(data: _buildPickerTheme(theme), child: child!);
      },
    );

    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? "AM" : "PM";

      timeController.text = "$hour:$minute $period";
    }
  }



  /// ================= PARSE DATE & TIME =================
  Map<String, dynamic> _parseBirthDate() {
    final parts = dateController.text.split('-');
    return {
      "year": int.parse(parts[0]),
      "month": int.parse(parts[1]),
      "day": int.parse(parts[2]),
    };
  }

  Map<String, dynamic> _parseBirthTime() {
    final parts = timeController.text.split(' ');
    final hm = parts[0].split(':');
    return {
      "hour": int.parse(hm[0]),
      "minute": int.parse(hm[1]),
      "ampm": parts[1],
    };
  }

  /// ================= GENERATE CHART =================
  Future<void> _generateChart() async {
    if (nameController.text.isEmpty ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        placeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all birth details")),
      );
      return;
    }

    setState(() => isLoading = true);

    final payload = <String, dynamic>{
      "name": nameController.text.trim(),
      "gender": gender,
      "birth_date": _parseBirthDate(),
      "birth_time": _parseBirthTime(),
      "place_of_birth": placeController.text.trim(),
      "astrology_type": astrologyType,
      "ayanamsa": ayanamsa,
    };

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.birthChartGenerateApi),
        headers: const <String, String>{"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Birth chart failed: ${response.body}");
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body["data"] as Map<String, dynamic>? ?? <String, dynamic>{};

      final chartImagePath = data["chartImage"]?.toString() ?? "";
      final chartImageCandidates = ChartCacheHelper.resolveChartImageCandidates(
        chartImagePath,
      );
      final chartImageUrl = chartImageCandidates.isEmpty
          ? ""
          : chartImageCandidates.first;

      final chartData =
          data["chartData"] as Map<String, dynamic>? ?? <String, dynamic>{};
      if (chartImageUrl.isNotEmpty) {
        chartData["chartImageUrl"] = chartImageUrl;
        chartData["chartImageCandidates"] = chartImageCandidates;
      }

      await ChartCacheHelper.cacheChart(
        chartData: chartData,
        chartImage: chartImagePath,
        fallbackRashi: data["rashi"]?.toString(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("birthDate", dateController.text.trim());
      await prefs.setString("birthTime", timeController.text.trim());
      await prefs.setString("birthPlace", placeController.text.trim());
      await prefs.setString("userName", nameController.text.trim());

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BirthChartResult(chartData: chartData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _birthchartTopBar(context),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedAppBackground(
        showStarsInDark: true,
        showStarsInLight: true,
        child: Stack(
          children: [
            if (!isDark) Positioned.fill(child: _lightAuraOverlay()),
            SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 380;
                  final double cardMaxWidth = constraints.maxWidth < 560
                      ? constraints.maxWidth
                      : 520;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 14 : 20,
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
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : const Color(0xFFD6E3F6),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.55)
                                    : const Color(
                                        0xFF7B91B8,
                                      ).withValues(alpha: 0.22),
                                blurRadius: 26,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? <Color>[
                                        const Color(0xFF2D2E49),
                                        const Color(0xFF23243A),
                                      ]
                                    : <Color>[
                                        Colors.white.withValues(alpha: 0.98),
                                        const Color(
                                          0xFFF3F7FF,
                                        ).withValues(alpha: 0.98),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                16,
                                18,
                                20,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 10),
                                  Center(
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: GoogleFonts.dmSans(
                                          fontSize: compact ? 22 : 24,
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF64748B),
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: "Generate Your ",
                                          ),
                                          TextSpan(
                                            text: context.l10n.tr("birthChart"),
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFFF6C65A)
                                                  : const Color(0xFF2563EB),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(text: " Astrology"),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 26),
                                  _glassInput(
                                    "Full Name",
                                    Icons.person,
                                    nameController,
                                  ),
                                  _glassInput(
                                    "Date of Birth",
                                    Icons.calendar_today,
                                    dateController,
                                    readOnly: true,
                                    onTap: _pickDate,
                                  ),
                                  _glassInput(
                                    "Time of Birth",
                                    Icons.access_time,
                                    timeController,
                                    readOnly: true,
                                    onTap: _pickTime,
                                  ),
                                  _buildPlaceAutocomplete(),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _glassDropdown(
                                          "Gender",
                                          gender,
                                          ["male", "female"],
                                          (v) => setState(() => gender = v),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _glassDropdown(
                                          "Astrology",
                                          astrologyType,
                                          ["vedic", "western"],
                                          (v) =>
                                              setState(() => astrologyType = v),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 26),
                                  SizedBox(
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : _generateChart,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark
                                            ? const Color(0xFFF6C65A)
                                            : colors.primary,
                                        foregroundColor: isDark
                                            ? const Color(0xFF1B1535)
                                            : colors.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                                              context.l10n.tr("generateChart"),
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
          ],
        ),
      ),
    );
  }

  Widget _lightAuraOverlay() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0x66A5B4FC), Color(0x00A5B4FC)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0x66FDE68A), Color(0x00FDE68A)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceAutocomplete() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = Colors.white; // ALWAYS solid white
    final borderColor = isDark ? Colors.transparent : const Color(0xFFD4E2F7);
    final textColor = const Color(0xFF0F172A); // ALWAYS dark
    final hintColor = const Color(0xFF64748B); // ALWAYS dark
    final iconBg = const Color(0xFFEAF2FF); // ALWAYS light blue
    final iconColor = const Color(0xFF2563EB); // ALWAYS dark blue

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, minWidth: 300),
          child: Autocomplete<PlaceSuggestion>(
            initialValue: TextEditingValue(text: placeController.text),
            displayStringForOption: (option) => option.name.isNotEmpty ? option.name : option.country,
            optionsBuilder: (TextEditingValue textEditingValue) async {
              final query = textEditingValue.text.trim();
              if (query.length < 2) {
                return const Iterable<PlaceSuggestion>.empty();
              }
              
              final completer = Completer<Iterable<PlaceSuggestion>>();
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () async {
                try {
                  final results = await PlaceApiService.searchPlaces(query);
                  completer.complete(results);
                } catch (_) {
                  completer.complete(const Iterable<PlaceSuggestion>.empty());
                }
              });
              
              _lastOptions = await completer.future;
              return _lastOptions;
            },
            onSelected: (PlaceSuggestion selection) {
              final label = selection.name.isNotEmpty ? selection.name : selection.country;
              placeController.text = label;
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              return Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  cursorColor: iconColor,
                  onChanged: (val) {
                    placeController.text = val;
                  },
                  style: GoogleFonts.dmSans(color: textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent, // Let Container's white background show through, or just set to Colors.white
                    prefixIconConstraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 52,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.location_on, color: iconColor, size: 18),
                      ),
                    ),
                    hintText: "Place of Birth",
                    hintStyle: GoogleFonts.dmSans(color: hintColor),
                    suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: hintColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  color: Colors.white, // Always white
                  borderRadius: BorderRadius.circular(14),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250, maxWidth: 350),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        final label = option.name.isNotEmpty ? option.name : option.country;
                        return ListTile(
                          leading: Icon(Icons.location_on_rounded, color: iconColor, size: 20),
                          title: Text(
                            label,
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: option.country.isNotEmpty && option.name.isNotEmpty
                              ? Text(
                                  option.country,
                                  style: GoogleFonts.dmSans(
                                    color: const Color(0xFF64748B),
                                  ),
                                )
                              : null,
                          onTap: () => onSelected(option),
                        );
                      },
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

  /// ================= GLASS INPUT =================
  Widget _glassInput(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool readOnly = false,
    VoidCallback? onTap,
    bool showDropdownIndicator = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = Colors.white; // Field is ALWAYS solid white
    final borderColor = isDark
        ? Colors.transparent
        : const Color(0xFFD4E2F7);
    final textColor = const Color(0xFF0F172A); // Text is ALWAYS dark
    final hintColor = const Color(0xFF64748B); // Hint is ALWAYS dark
    final iconBg = const Color(0xFFEAF2FF); // Icon bg is ALWAYS light blue
    final iconColor = const Color(0xFF2563EB); // Icon is ALWAYS dark blue

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, minWidth: 300),
          child: Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              cursorColor: isDark
                  ? const Color(0xFFF6C65A)
                  : const Color(0xFF2563EB),
              style: GoogleFonts.dmSans(color: textColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent, // Fix: Override global theme so Container's white background is visible
                prefixIconConstraints: const BoxConstraints(
                  minHeight: 48,
                  minWidth: 52,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                ),
                hintText: label,
                hintStyle: GoogleFonts.dmSans(color: hintColor),
                suffixIcon: showDropdownIndicator
                    ? Icon(Icons.keyboard_arrow_down_rounded, color: hintColor)
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= GLASS DROPDOWN =================
  Widget _glassDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = Colors.white; // Field is ALWAYS solid white
    final borderColor = isDark
        ? Colors.transparent
        : const Color(0xFFD4E2F7);
    final textColor = const Color(0xFF0F172A); // Text is ALWAYS dark
    final labelColor = const Color(0xFF64748B); // Label is ALWAYS dark

    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: Colors.white, // Always white so the dark text is readable!
      iconEnabledColor: textColor,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e.toUpperCase(),
                style: GoogleFonts.dmSans(color: textColor),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => onChanged(v!),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(color: labelColor),
        filled: true,
        fillColor: fillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFFF6C65A) : const Color(0xFF60A5FA),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: GoogleFonts.dmSans(color: textColor),
    );
  }
}

/// ================= TOP BAR =================
PreferredSizeWidget _birthchartTopBar(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return AppBar(
    backgroundColor: isDark
        ? AppColors.appBarDark
        : AppColors.lightContainer,
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
