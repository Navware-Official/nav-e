import 'package:flutter/material.dart';
import 'palette.dart';

/// App typography. Prefer `Theme.of(context).textTheme` (titleLarge,
/// bodyMedium, etc.) for body / titles. Use the named [eyebrow], [label],
/// [readout], [readoutSm] styles for the design's distinctive HUD readouts
/// and mono-uppercase tracked labels.
///
/// Three families:
///   * [family] (Neue Haas Unica) — body, titles, labels.
///   * [decorativeFamily] (Bitcount Grid Single) — display + HUD readouts.
///   * [monoFamily] (JetBrains Mono) — eyebrows, codes, tracked labels.
class AppTypography {
  AppTypography._();

  static const family = 'NeueHaasUnica';
  static const decorativeFamily = 'BitcountGridSingle';

  // Mono family currently routes to Bitcount Grid Single — Bitcount is
  // already monospaced and grid-aligned, fits the brand aesthetic, and is
  // already bundled. To switch to JetBrains Mono, vendor the TTFs into
  // assets/fonts/, register them in pubspec.yaml under family
  // `JetBrainsMono`, and change this constant.
  static const monoFamily = decorativeFamily;

  @Deprecated(
    'Use decorativeFamily for display/headline; use family for body text',
  )
  static const subFamily = decorativeFamily;

  // ─── Tracking constants ───────────────────────────────────────────────
  static const double trackingTight = -0.16; // -0.01em at 16px
  static const double trackingNormal = 0;
  static const double trackingWide = 0.64; // 0.04em at 16px
  static const double trackingGrid = 1.28; // 0.08em at 16px
  static const double trackingMonoLabel = 1.92; // 0.16em at 12px

  // ─── HUD readouts (Bitcount, monospaced numerics) ─────────────────────

  /// Hero readout — speed / distance / ETA on the device HUD.
  static const TextStyle readout = TextStyle(
    fontFamily: decorativeFamily,
    fontSize: 88,
    height: 1.0,
    letterSpacing: 1.76, // 0.02em
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Smaller readout — secondary numeric values inside widgets.
  static const TextStyle readoutSm = TextStyle(
    fontFamily: decorativeFamily,
    fontSize: 22,
    height: 1.15,
    letterSpacing: 0.88, // 0.04em
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ─── Mono labels (JetBrains Mono, uppercase tracked) ──────────────────

  /// 12px uppercase mono — section headers, status pills, widget titles.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12,
    height: 1.45,
    letterSpacing: trackingMonoLabel,
    fontWeight: FontWeight.w500,
  );

  /// Alias of [eyebrow] for stylistic semantics in headers.
  static const TextStyle overline = eyebrow;

  /// 12px mono — tracked labels on form rows, settings values.
  static const TextStyle label = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12,
    height: 1.45,
    letterSpacing: trackingMonoLabel,
    fontWeight: FontWeight.w500,
  );

  /// 11px mono — dense secondary metadata (coordinates, distances).
  static const TextStyle labelSmall = TextStyle(
    fontFamily: monoFamily,
    fontSize: 11,
    height: 1.45,
    letterSpacing: 1.32, // ~0.12em
    fontWeight: FontWeight.w500,
  );

  /// 9px–10px mono — used for status-bar segments and dense pill labels.
  static const TextStyle labelMicro = TextStyle(
    fontFamily: monoFamily,
    fontSize: 10,
    height: 1.4,
    letterSpacing: 1.4, // ~0.14em
    fontWeight: FontWeight.w500,
  );

  // ─── Material TextTheme base ──────────────────────────────────────────
  static const TextTheme base = TextTheme(
    // Display & headline — Bitcount, weight 600/700, tracking-tight
    displayLarge: TextStyle(
      fontFamily: decorativeFamily,
      fontSize: 64,
      height: 1.0,
      letterSpacing: trackingTight,
      fontWeight: FontWeight.w700,
    ),
    displayMedium: TextStyle(
      fontFamily: decorativeFamily,
      fontSize: 48,
      height: 1.0,
      letterSpacing: trackingTight,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: TextStyle(
      fontFamily: decorativeFamily,
      fontSize: 36,
      height: 1.15,
      letterSpacing: trackingTight,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: TextStyle(
      fontFamily: decorativeFamily,
      fontSize: 28,
      height: 1.15,
      letterSpacing: trackingTight,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      fontFamily: decorativeFamily,
      fontSize: 22,
      height: 1.15,
      letterSpacing: trackingTight,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontFamily: decorativeFamily,
      fontSize: 18,
      height: 1.15,
      letterSpacing: 0,
      fontWeight: FontWeight.w600,
    ),

    // Titles / body — Neue Haas Unica (ships at 500 only — don't fake weights)
    titleLarge: TextStyle(
      fontFamily: family,
      fontSize: 22,
      height: 1.15,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: TextStyle(
      fontFamily: family,
      fontSize: 18,
      height: 1.15,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontFamily: family,
      fontSize: 16,
      height: 1.45,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      fontFamily: family,
      fontSize: 16,
      height: 1.45,
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: TextStyle(
      fontFamily: family,
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w500,
    ),
    bodySmall: TextStyle(
      fontFamily: family,
      fontSize: 12,
      height: 1.45,
      fontWeight: FontWeight.w500,
    ),

    // Labels — mono
    labelLarge: TextStyle(
      fontFamily: monoFamily,
      fontSize: 14,
      height: 1.45,
      letterSpacing: trackingWide,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontFamily: monoFamily,
      fontSize: 12,
      height: 1.45,
      letterSpacing: trackingMonoLabel,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontFamily: monoFamily,
      fontSize: 11,
      height: 1.45,
      letterSpacing: 1.32,
      fontWeight: FontWeight.w500,
    ),
  );

  static TextTheme light = base.apply(
    bodyColor: AppPalette.brandCharcoal,
    displayColor: AppPalette.brandCharcoal,
  );

  static TextTheme dark = base.apply(
    bodyColor: AppPalette.brandWhite,
    displayColor: AppPalette.brandWhite,
  );
}
