import 'package:flutter/material.dart';

class AppColors {
  // ── Brand (from Pops) ────────────────────────
  static const Color accent = Color(0xFFC85A0A);
  static const Color accentLight = Color(0xFFFEF0E6);
  static const Color accentDark = Color(0xFF9E4508);

  // Zynk colors
  static const Color brandSecondary = Color(0xFFD4FC45); // Zynk Neon Lime
  static const Color brandSecondaryLight = Color(0xFF65A30D); // Zynk Dark Lime
  static const Color brandTertiary = Color.fromARGB(
    255,
    212,
    208,
    229,
  ); // Zynk Based Gray
  static const Color brandAccent = Color(0xFFFF4D8F); // Zynk Hot Pink

  // ── Neutrals (Zynk Dark) ────────────────────────
  static const Color bgCanvasDark = Color(0xFF0D1117);
  static const Color bgSurfaceDark = Color(0xFF161B22);
  static const Color bgSurfaceHighlightDark = Color(0xFF1C2333);
  static const Color borderSubtleDark = Color(0xFF30363D);
  static const Color textPrimaryDark = Color(0xFFE6EDF3);
  static const Color textMutedDark = Color(0xFF8B949E);

  // ── Neutrals (Zynk Light) ────────────────────────
  static const Color bgCanvasLight = Color(0xFFF9FAFB);
  static const Color bgSurfaceLight = Color(0xFFFFFFFF);
  static const Color borderSubtleLight = Color(0xFFE5E7EB);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textMutedLight = Color(0xFF6B7280);

  // ── Status ───────────────────────
  static const Color error = Color(0xFFCC1F35);
  static const Color errorContainer = Color(0xFFFEE8EB);
  static const Color errorContainerLight = Color(0xFFFEE8EB);
  static const Color warning = Color(0xFFB45309);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color success = Color(0xFF166534);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoContainer = Color(0xFFEFF6FF);

  // ── Shapes (Radii) ────────────────────────
  static const double radiusSoft = 8.0;
  static const double radiusCard = 16.0;
  static const double radiusPill = 100.0;

  static const BorderRadius roundedSoft = BorderRadius.all(
    Radius.circular(radiusSoft),
  );
  static const BorderRadius roundedCard = BorderRadius.all(
    Radius.circular(radiusCard),
  );
  static const BorderRadius roundedPill = BorderRadius.all(
    Radius.circular(radiusPill),
  );
}
