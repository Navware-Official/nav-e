import 'package:flutter/material.dart';

class AppColors {
  static const Color blueRibbonDark02 = Color(0xFF0121D1);
  static const Color blueRibbon = Color(0xFF375AF9);
  static const Color blueRibbonDark04 = Color(0xFF01216C);

  static const Color lightGray = Color(0xFFD0D2D3);
  static const Color capeCodLight02 = Color(0xFF6F7070);
  static const Color white = Color(0xFFFBFFFF);
  static const Color capeCodDark01 = Color(0xFF343535);

  // Extra colors
  static const Color capeCodDark02 = Color.fromARGB(255, 24, 24, 24);

  // Semantic colors (work in both light and dark)
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color error = Color(0xFFC62828);
  static const Color errorContainer = Color(0xFFFFCDD2);
  static const Color warning = Color(0xFFF9A825);
  static const Color warningContainer = Color(0xFFFFF8E1);

  // Muted / secondary text (replaces ad hoc grey)
  static const Color onSurfaceVariant = Color(0xFF6F7070);

  // Dark red (legacy; prefer semantic error for UI)
  static const Color redDark = Color.fromARGB(255, 155, 0, 0);
}
