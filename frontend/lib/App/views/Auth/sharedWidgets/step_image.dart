import 'package:flutter/material.dart';

class StepImage extends StatelessWidget {
  final String path;

  const StepImage({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final imageHeight = screenHeight < 760 ? 112.0 : 140.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: keyboardOpen
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(child: Image.asset(path, height: imageHeight)),
            ),
    );
  }
}
