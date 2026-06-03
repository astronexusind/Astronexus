import 'package:astro_tale/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int step;
  final VoidCallback onBack;
  final bool compact;

  const SignupAppBar({
    super.key,
    required this.step,
    required this.onBack,
    this.compact = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(compact ? 84 : 110);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.appBarDark : AppColors.lightContainer,
          ),
        ),
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,

          // Always show back button so user can exit signup
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.onDark),
            onPressed: onBack,
          ),

          title: Column(
            children: [
              SizedBox(height: compact ? 8 : 20),
              Text(
                _title(step),
                style: GoogleFonts.dmSans(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onDark,
                ),
              ),
              if (!compact)
                Text(
                  "Cosmic Step ${step + 1} / 7",
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _title(int step) {
    const titles = [
      "Enter Your Name",
      "Enter Your Email",
      "Enter Your Phone",
      "Set Password",
      "Enter Birth Date",
      "Select Time of Birth",
      "Enter Place of Birth",
    ];

    if (step < 0 || step >= titles.length) return "";
    return titles[step];
  }
}
