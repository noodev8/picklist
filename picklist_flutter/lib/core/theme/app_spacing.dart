import 'package:flutter/material.dart';

/// 4px base grid. Tighter than the usual 8px scale because pick rows carry a lot
/// of short data and need to stay dense enough to see a whole bay at once.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 40;

  /// Horizontal gutter used by every screen, so headers, rows and empty states
  /// all hang off the same left edge.
  static const double gutter = 16;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: gutter);

  static const Widget h4 = SizedBox(height: xs);
  static const Widget h8 = SizedBox(height: sm);
  static const Widget h12 = SizedBox(height: md);
  static const Widget h16 = SizedBox(height: lg);
  static const Widget h24 = SizedBox(height: xl);
  static const Widget h40 = SizedBox(height: xxl);

  static const Widget w4 = SizedBox(width: xs);
  static const Widget w8 = SizedBox(width: sm);
  static const Widget w12 = SizedBox(width: md);
  static const Widget w16 = SizedBox(width: lg);
}

/// Corners stay small and consistent - this is signage, not a consumer app.
class AppRadius {
  AppRadius._();

  static const BorderRadius sm = BorderRadius.all(Radius.circular(4));
  static const BorderRadius md = BorderRadius.all(Radius.circular(8));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(12));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}
