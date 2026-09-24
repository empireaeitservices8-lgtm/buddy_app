import 'package:flutter/material.dart';

/// Fresh, Modern Cartoon UI Color Palette
class CartoonColors {
  CartoonColors._();

  // 1. Warm Cream Canvas
  static const Color canvas = Color(0xFFFFFDF7);

  // 2. Primary Cartoon Purple
  static const Color primary = Color(0xFF8B7CFF);
  static const Color purpleSoft = Color(0xFFE8E3FF);

  // 3. Cartoon Blue
  static const Color blue = Color(0xFF8DD8FF);
  static const Color blueSoft = Color(0xFFE0F5FF);

  // 4. Cartoon Yellow
  static const Color yellow = Color(0xFFFFD95A);
  static const Color yellowSoft = Color(0xFFFFF2B8);

  // 5. Cartoon Green
  static const Color green = Color(0xFF9BE58A);
  static const Color greenSoft = Color(0xFFE1F7D9);

  // 6. Cartoon Pink
  static const Color pink = Color(0xFFFF9FBC);
  static const Color pinkSoft = Color(0xFFFFE1EA);

  // 7. Peach
  static const Color peach = Color(0xFFFFBE8A);
  static const Color peachSoft = Color(0xFFFFE8D5);

  // 8. Main Ink (Borders, Outlines, Main Text)
  static const Color ink = Color(0xFF252329);

  // 9. White
  static const Color white = Color(0xFFFFFFFF);

  // 10. Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // --- Convenience & Compatibility Aliases ---
  static const Color baseCanvas = canvas;
  static const Color cardWhite = white;
  static const Color lavender = purpleSoft;
  static const Color lime = green;
  static const Color beige = peachSoft;
  static const Color sky = blue;
  static const Color mint = greenSoft;
  static const Color charcoal = ink;
  static const Color stroke = ink;
  static const Color strokeBlack = ink;
  static const Color textBlack = ink;
  static const Color textSecondary = Color(0xFF5A5863);
  static const Color textMuted = Color(0xFF7D7A87);
  static const Color textPlaceholder = Color(0xFFA09DA8);
  static const Color dutyGreen = success;
  static const Color alertRed = error;
  static const Color proBlue = primary;
  static const Color starOrange = warning;
}
