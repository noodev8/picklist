import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Two faces, each with a job.
///
/// Barlow Condensed carries anything a picker reads at arm's length while
/// walking - bay codes, shoe sizes, remaining counts. It is the type used on
/// warehouse racking and shipping labels, and it fits long codes without
/// shrinking them.
///
/// Barlow (the same family, normal width) carries everything read standing
/// still: product names, colours, order refs, help text.
///
/// Every numeral style is tabular so counts and sizes stay in column as they
/// change, instead of jittering the row.
class AppTypography {
  AppTypography._();

  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  // ---------------------------------------------------------------- signage

  /// The shoe size on a pick row - the single biggest thing on screen.
  static TextStyle get sizeNumeral => GoogleFonts.barlowCondensed(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1,
        letterSpacing: -0.5,
        fontFeatures: _tabular,
      );

  /// The style reference on a pick row - the second thing read, straight after
  /// the size, and the one that settles which box it is.
  static TextStyle get itemCode => GoogleFonts.barlowCondensed(
        fontSize: 25,
        fontWeight: FontWeight.w600,
        height: 1.05,
        letterSpacing: 0.8,
        color: AppColors.chalk,
        fontFeatures: _tabular,
      );

  /// Bay code on a section bar, and area name on the home screen.
  static TextStyle get bayCode => GoogleFonts.barlowCondensed(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.05,
        letterSpacing: 0.5,
        color: AppColors.chalk,
        fontFeatures: _tabular,
      );

  /// Big remaining-count numerals on the home screen.
  static TextStyle get counter => GoogleFonts.barlowCondensed(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 0.95,
        letterSpacing: -1,
        fontFeatures: _tabular,
      );

  /// Screen titles.
  static TextStyle get title => GoogleFonts.barlowCondensed(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: 0.3,
        color: AppColors.chalk,
      );

  /// All-caps eyebrow above a group of content.
  static TextStyle get eyebrow => GoogleFonts.barlowCondensed(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.6,
        color: AppColors.chalkDim,
      );

  // ------------------------------------------------------------------- body

  static TextStyle get body => GoogleFonts.barlow(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.chalk,
      );

  /// Supporting detail on a row: brand, colour, order ref.
  static TextStyle get detail => GoogleFonts.barlow(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.chalkDim,
        fontFeatures: _tabular,
      );

  /// Product code - a machine string, spaced out so it can be read back.
  static TextStyle get code => GoogleFonts.barlow(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.4,
        color: AppColors.chalkFaint,
        fontFeatures: _tabular,
      );

  /// Buttons and chips.
  static TextStyle get label => GoogleFonts.barlow(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
        color: AppColors.chalk,
      );

  static TextStyle get labelSmall => GoogleFonts.barlow(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.8,
        color: AppColors.chalkDim,
      );
}
