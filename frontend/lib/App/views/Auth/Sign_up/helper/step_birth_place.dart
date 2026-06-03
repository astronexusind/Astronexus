import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "../../sharedWidgets/place_suggestion_sheet.dart";
import "../../sharedWidgets/step_image.dart";

import "dart:async";
import "package:astro_tale/App/Model/place/place_suggestion.dart";
import "package:astro_tale/App/views/Auth/Sign_up/services/city_services.dart";

class StepBirthPlace extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const StepBirthPlace({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<StepBirthPlace> createState() => _StepBirthPlaceState();
}

class _StepBirthPlaceState extends State<StepBirthPlace> {
  Timer? _debounce;
  Iterable<PlaceSuggestion> _lastOptions = const Iterable<PlaceSuggestion>.empty();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    
    // Match the new CommonInput styling
    final textColor = const Color(0xFF0F172A);
    final hintColor = const Color(0xFF64748B);
    final iconColor = isDark ? const Color(0xFFD4AF37) : const Color(0xFF1D4ED8);
    final mutedColor = isDark ? Colors.white54 : theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepImage(path: "assets/images/place.png"),
        Text(
          "Your birthplace anchors planetary angles to Earth coordinates.",
          style: GoogleFonts.dmSans(color: mutedColor),
        ),
        const SizedBox(height: 20),
        Autocomplete<PlaceSuggestion>(
          initialValue: TextEditingValue(text: widget.controller.text),
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
            widget.controller.text = label;
            widget.onChanged(label);
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              scrollPadding: const EdgeInsets.only(bottom: 180),
              cursorColor: iconColor,
              onChanged: (val) {
                widget.controller.text = val;
                widget.onChanged(val);
              },
              style: GoogleFonts.dmSans(color: textColor, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Place of Birth",
                hintStyle: GoogleFonts.dmSans(color: hintColor, fontWeight: FontWeight.w500),
                prefixIcon: Icon(Icons.location_on_outlined, color: iconColor),
                suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : colors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : colors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFFD4AF37) : colors.primary,
                    width: 1.8,
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
                color: Colors.white, // Always white as requested
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
                            color: const Color(0xFF0F172A), // Always dark text
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: option.country.isNotEmpty && option.name.isNotEmpty
                            ? Text(
                                option.country,
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFF64748B), // Always dark hint text
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
      ],
    );
  }
}
