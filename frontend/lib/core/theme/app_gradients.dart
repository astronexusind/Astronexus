import "package:flutter/material.dart";
import "package:astro_tale/core/constants/app_colors.dart";

class AppGradients {
  const AppGradients._();

  static List<Color> screen(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return const <Color>[
        AppColors.appBarDark,
        Color(0xFF393053),
        AppColors.appBarDark,
      ];
    }
    return const <Color>[
      AppColors.lightBackground,
      AppColors.lightBackgroundSoft,
      AppColors.lightBackground,
    ];
  }

  static BoxDecoration screenDecoration(ThemeData theme) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: screen(theme),
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static Color screenOverlay(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.36)
        : Colors.white.withOpacity(0.14);
  }

  static Color glassFill(ThemeData theme) {
    // Use translucent white/primary for a premium glass look in dark mode
    // In light mode, use a beautifully frosted translucent white
    return theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06) // subtle translucent glass
        : Colors.white.withValues(alpha: 0.65); // premium frosted white
  }

  static Color navBarFill(ThemeData theme) {
    // Use a solid dark color for the bottom navigation bar to prevent interference
    return theme.brightness == Brightness.dark
        ? const Color(0xFF23243A) // deep solid dark
        : AppColors.lightContainer;
  }

  static Color glassBorder(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.9); // crisp white edge for light glass
  }

  static Color panelOn(ThemeData theme) => Colors.white;
}
