import 'package:flutter/material.dart';

/// Semantic colour tokens that extend Material's ColorScheme.
///
/// Access in widgets:
///   final appColors = Theme.of(context).extension<AppColors>()!;
///   appColors.success / appColors.successContainer / etc.
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
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  static const light = AppColors(
    success:            Color(0xFF2E7D32),
    onSuccess:          Color(0xFFFFFFFF),
    successContainer:   Color(0xFFC8E6C9),
    onSuccessContainer: Color(0xFF1B5E20),
    warning:            Color(0xFFF9A825),
    onWarning:          Color(0xFF000000),
    warningContainer:   Color(0xFFFFF8E1),
    onWarningContainer: Color(0xFF7A5000),
  );

  static const dark = AppColors(
    success:            Color(0xFF66BB6A),
    onSuccess:          Color(0xFF000000),
    successContainer:   Color(0xFF1B5E20),
    onSuccessContainer: Color(0xFFC8E6C9),
    warning:            Color(0xFFFFD54F),
    onWarning:          Color(0xFF000000),
    warningContainer:   Color(0xFF7A5000),
    onWarningContainer: Color(0xFFFFF8E1),
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
  }) {
    return AppColors(
      success:            success            ?? this.success,
      onSuccess:          onSuccess          ?? this.onSuccess,
      successContainer:   successContainer   ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning:            warning            ?? this.warning,
      onWarning:          onWarning          ?? this.onWarning,
      warningContainer:   warningContainer   ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success:            Color.lerp(success,            other.success,            t)!,
      onSuccess:          Color.lerp(onSuccess,          other.onSuccess,          t)!,
      successContainer:   Color.lerp(successContainer,   other.successContainer,   t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning:            Color.lerp(warning,            other.warning,            t)!,
      onWarning:          Color.lerp(onWarning,          other.onWarning,          t)!,
      warningContainer:   Color.lerp(warningContainer,   other.warningContainer,   t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
    );
  }
}
