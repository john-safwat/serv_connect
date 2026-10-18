import 'package:flutter/widgets.dart';

/// Responsive screen width breakpoints for phones and tablets.
abstract final class ServeBreakpoints {
  static const double compactMaxWidth = 599;
  static const double mediumMaxWidth = 839;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= compactMaxWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width > compactMaxWidth;
}
