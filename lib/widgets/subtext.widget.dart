import 'package:flutter/widgets.dart';
import 'package:nav_e/core/theme/typography.dart';

class SubText extends StatelessWidget {
  const SubText(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? const TextStyle(fontFamily: AppTypography.subFamily),
    );
  }
}