import 'package:flutter/material.dart';
import 'palette.dart';

/// Semantic colour tokens that extend Material's ColorScheme.
///
/// Access in widgets:
///   final appColors = Theme.of(context).extension[AppColors]()!;
///   appColors.success / appColors.warning / appColors.fgMuted / etc.
///
/// Registered in AppTheme via ThemeData.extensions.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.info,
    required this.fgPrimary,
    required this.fgSecondary,
    required this.fgMuted,
    required this.surfaceRaised,
    required this.surfaceCard,
    required this.borderStrong,
    required this.borderSubtle,
    required this.gridLine,
    required this.gridLineStrong,
    required this.gridMajor,
    required this.hiVis,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// Error / off-route. Mirrors `--alert` in the design CSS.
  final Color danger;

  /// Informational accent. Resolves to brand-blue-mid.
  final Color info;

  /// Foreground hierarchy.
  final Color fgPrimary;
  final Color fgSecondary;
  final Color fgMuted;

  /// Surface hierarchy beyond Material's surface tokens.
  final Color surfaceRaised;
  final Color surfaceCard;

  /// Border hierarchy.
  final Color borderStrong;
  final Color borderSubtle;

  /// Map / grid lines (used by the map adapter and HUD backdrops).
  final Color gridLine;
  final Color gridLineStrong;
  final Color gridMajor;

  /// "You are here" / active route accent. Alias for primary brand-blue.
  final Color hiVis;

  static const light = AppColors(
    success: AppPalette.signal,
    onSuccess: AppPalette.brandWhite,
    successContainer: Color(0xFFD8EFE0),
    onSuccessContainer: AppPalette.signalDeep,
    warning: AppPalette.amber,
    onWarning: AppPalette.brandBlack,
    warningContainer: Color(0xFFFFF1D6),
    onWarningContainer: AppPalette.amberDeep,
    danger: AppPalette.alert,
    info: AppPalette.brandBlueMid,
    fgPrimary: AppPalette.brandCharcoal,
    fgSecondary: AppPalette.brandGray,
    fgMuted: Color(0xFF8A8C8D),
    surfaceRaised: AppPalette.paper100,
    surfaceCard: AppPalette.paper000,
    borderStrong: AppPalette.brandGray,
    borderSubtle: AppPalette.paper300,
    gridLine: AppPalette.gridLineLight,
    gridLineStrong: AppPalette.gridLineStrongLight,
    gridMajor: AppPalette.brandGray,
    hiVis: AppPalette.brandBlue,
  );

  static const dark = AppColors(
    success: AppPalette.signal,
    onSuccess: AppPalette.brandWhite,
    successContainer: AppPalette.signalDeep,
    onSuccessContainer: Color(0xFFD8EFE0),
    warning: AppPalette.amber,
    onWarning: AppPalette.brandBlack,
    warningContainer: AppPalette.amberDeep,
    onWarningContainer: Color(0xFFFFF1D6),
    danger: AppPalette.alert,
    info: AppPalette.brandBlueMid,
    fgPrimary: AppPalette.ink999,
    fgSecondary: AppPalette.ink800,
    fgMuted: AppPalette.ink600,
    surfaceRaised: AppPalette.ink200,
    surfaceCard: AppPalette.ink300,
    borderStrong: AppPalette.ink400,
    borderSubtle: Color(0xFF242527),
    gridLine: AppPalette.gridLineDark,
    gridLineStrong: AppPalette.gridLineStrongDark,
    gridMajor: AppPalette.ink500,
    hiVis: AppPalette.brandBlue,
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? info,
    Color? fgPrimary,
    Color? fgSecondary,
    Color? fgMuted,
    Color? surfaceRaised,
    Color? surfaceCard,
    Color? borderStrong,
    Color? borderSubtle,
    Color? gridLine,
    Color? gridLineStrong,
    Color? gridMajor,
    Color? hiVis,
  }) {
    return AppColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      fgPrimary: fgPrimary ?? this.fgPrimary,
      fgSecondary: fgSecondary ?? this.fgSecondary,
      fgMuted: fgMuted ?? this.fgMuted,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      borderStrong: borderStrong ?? this.borderStrong,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      gridLine: gridLine ?? this.gridLine,
      gridLineStrong: gridLineStrong ?? this.gridLineStrong,
      gridMajor: gridMajor ?? this.gridMajor,
      hiVis: hiVis ?? this.hiVis,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      fgPrimary: Color.lerp(fgPrimary, other.fgPrimary, t)!,
      fgSecondary: Color.lerp(fgSecondary, other.fgSecondary, t)!,
      fgMuted: Color.lerp(fgMuted, other.fgMuted, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      gridLineStrong: Color.lerp(gridLineStrong, other.gridLineStrong, t)!,
      gridMajor: Color.lerp(gridMajor, other.gridMajor, t)!,
      hiVis: Color.lerp(hiVis, other.hiVis, t)!,
    );
  }
}
