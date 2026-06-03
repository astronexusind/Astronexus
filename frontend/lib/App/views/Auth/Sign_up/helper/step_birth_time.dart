import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../sharedWidgets/step_image.dart';
import '../model/SignUp_Data_Model.dart';

class StepBirthTime extends StatelessWidget {
  final AstrologySignupModel model;
  final VoidCallback onChanged;

  const StepBirthTime({
    super.key,
    required this.model,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        const StepImage(path: "assets/images/time.png"),

        Text(
          "Exact birth time determines the Ascendant and house divisions.",
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            color: isDark ? Colors.white : colors.onSurface,
          ),
        ),

        const SizedBox(height: 30),

        Container(
          height: 160,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(
                        color: isDark ? Colors.white : colors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Hour picker
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 44,
                          backgroundColor: Colors.transparent,
                          selectionOverlay: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white24 : theme.colorScheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          onSelectedItemChanged: (i) {
                            model.hour = i + 1;
                            onChanged();
                          },
                          children: List.generate(
                            12,
                            (i) => Center(
                              child: Text((i + 1).toString().padLeft(2, '0')),
                            ),
                          ),
                        ),
                      ),

                      // Minute picker
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 44,
                          backgroundColor: Colors.transparent,
                          selectionOverlay: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white24 : theme.colorScheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          onSelectedItemChanged: (i) {
                            model.minute = i;
                            onChanged();
                          },
                          children: List.generate(
                            60,
                            (i) => Center(
                              child: Text(i.toString().padLeft(2, '0')),
                            ),
                          ),
                        ),
                      ),

                      // AM / PM picker
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 44,
                          backgroundColor: Colors.transparent,
                          selectionOverlay: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white24 : theme.colorScheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          onSelectedItemChanged: (i) {
                            model.isAM = i == 0;
                            onChanged();
                          },
                          children: const [
                            Center(child: Text("AM")),
                            Center(child: Text("PM")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
