import 'package:flutter/material.dart';
import 'package:astro_tale/ui_componets/glass/glass_card.dart';

class SignupCard extends StatelessWidget {
  final Widget child;
  final bool compact;

  const SignupCard({super.key, required this.child, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(24, compact ? 6 : 0, 24, compact ? 8 : 0),
      child: glassCard(
        padding: EdgeInsets.all(compact ? 18 : 22),
        radius: compact ? 22 : 26,
        child: child,
      ),
    );
  }
}
