import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme get arabicTextTheme {
    return GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(fontSize: 57, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      displayMedium: GoogleFonts.cairo(fontSize: 45, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      displaySmall: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      headlineLarge: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      headlineMedium: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      headlineSmall: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      titleLarge: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      titleMedium: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleSmall: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
      bodyMedium: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
      bodySmall: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
      labelLarge: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      labelMedium: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      labelSmall: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    );
  }

  static TextTheme get englishTextTheme {
    return GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.nunito(fontSize: 57, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      displayMedium: GoogleFonts.nunito(fontSize: 45, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      displaySmall: GoogleFonts.nunito(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      headlineLarge: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      headlineMedium: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      headlineSmall: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      titleLarge: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      titleMedium: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleSmall: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
      bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
      bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
      labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      labelMedium: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      labelSmall: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    );
  }
}
