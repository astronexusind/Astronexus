import "dart:ui";

import "package:astro_tale/core/localization/app_localizations.dart";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchField({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark
        ? colors.surface.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.85);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : colors.outline.withValues(alpha: 0.2);
    final hint = isDark
        ? Colors.white60
        : colors.onSurface.withValues(alpha: 0.5);
    final textColor = isDark
        ? Colors.white
        : colors.onSurface;
    final iconColor = isDark
        ? Colors.white70
        : colors.primary;
    final iconBgColor = isDark
        ? Colors.white10
        : colors.primary.withValues(alpha: 0.1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 1.2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.dmSans(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: false,
                hintText: context.l10n.tr("searchProducts"),
                hintStyle: GoogleFonts.dmSans(
                  color: hint,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.search_rounded, color: iconColor, size: 20),
                ),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: iconColor,
                          size: 20,
                        ),
                        onPressed: onClear,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
