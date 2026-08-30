import 'package:flutter/material.dart';

/// "Stockroom" palette.
///
/// Built out from the app mark's deep teal (#18353D) rather than a neutral grey
/// scale. The app is used walking around a stockroom under mixed light, so the
/// ground is dark and one hi-vis accent carries every actionable thing. Green is
/// reserved exclusively for work that is done - nothing else is allowed to use it,
/// so a glance at the screen answers "what is left" without reading a word.
class AppColors {
  AppColors._();

  /// Page ground.
  static const Color ground = Color(0xFF081418);

  /// Cards, headers, sheets - one step up from the ground.
  static const Color deck = Color(0xFF10262D);

  /// Raised or selected panels - one step above [deck].
  static const Color deckHigh = Color(0xFF163038);

  /// Hairlines and dividers.
  static const Color rule = Color(0xFF1F444E);

  /// Primary text and icons.
  static const Color chalk = Color(0xFFE8EEEF);

  /// Secondary text - labels, counts, supporting detail.
  static const Color chalkDim = Color(0xFF8FA6AC);

  /// Disabled or decorative text.
  static const Color chalkFaint = Color(0xFF5B767E);

  /// The single accent: outstanding work, progress, active selection.
  static const Color signal = Color(0xFFFFB43D);

  /// Text/icons sitting on [signal].
  static const Color onSignal = Color(0xFF1A1000);

  /// Picked. Used for nothing else.
  static const Color done = Color(0xFF4FB286);

  /// Failures and destructive confirmation.
  static const Color alert = Color(0xFFE86B5A);
}
