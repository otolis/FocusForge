import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Creates the app [TextTheme] using Nunito for headings/display
/// and Inter for body/label text.
TextTheme createTextTheme() {
  final nunitoTheme = GoogleFonts.nunitoTextTheme();
  final interTheme = GoogleFonts.interTextTheme();

  return TextTheme(
    // Display -- Nunito 28dp bold
    displayLarge: nunitoTheme.displayLarge?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    displayMedium: nunitoTheme.displayMedium?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    // Headline -- Nunito 22dp bold
    headlineMedium: nunitoTheme.headlineMedium?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    headlineSmall: nunitoTheme.headlineSmall?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    // Body -- Inter 16dp regular
    bodyLarge: interTheme.bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: interTheme.bodyMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    // Label -- Inter 14dp regular
    labelLarge: interTheme.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    labelMedium: interTheme.labelMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
  );
}
