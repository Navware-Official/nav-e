/// Spacing scale on an 8-pt grid.
///
/// Use these constants for [SizedBox], [EdgeInsets], and [Gap] values
/// whenever the measurement falls on the grid.
/// Off-grid values (6, 10, 12, 20, 28, …) should remain as literals
/// with an `// off-grid` comment.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
