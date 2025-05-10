import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFFE53935);
  static const Color secondaryColor = Color(0xFFD94B4B);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF43A047);

  // Typography
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.pretendard(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: textPrimaryColor,
    ),
    displayMedium: GoogleFonts.pretendard(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: textPrimaryColor,
    ),
    displaySmall: GoogleFonts.pretendard(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.25,
      color: textPrimaryColor,
    ),
    bodyLarge: GoogleFonts.pretendard(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      color: textPrimaryColor,
    ),
    bodyMedium: GoogleFonts.pretendard(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: textSecondaryColor,
    ),
  );

  // AppBar Theme
  static final AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: primaryColor,
    elevation: 4,
    centerTitle: true,
    titleTextStyle: GoogleFonts.pretendard(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 24,
    ),
  );

  // Button Theme
  static final ButtonThemeData buttonTheme = ButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  // Card Theme
  static final CardTheme cardTheme = CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    color: surfaceColor,
  );

  // Input Decoration Theme
  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: errorColor),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  // Custom AppBar
  static PreferredSizeWidget buildAppBar({
    required String title,
    String? subtitle,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return AppBar(
      backgroundColor: primaryColor,
      elevation: 4,
      centerTitle: centerTitle,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.pretendard(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: GoogleFonts.pretendard(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
        ],
      ),
      leading: leading != null
          ? Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: leading,
            )
          : null,
      actions: actions?.map((action) {
        return Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: action,
        );
      }).toList(),
    );
  }

  // Custom Back Button
  static Widget buildBackButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.of(context).pop(),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        padding: EdgeInsets.all(12),
      ),
    );
  }

  // Custom Action Button
  static Widget buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.white.withOpacity(0.2),
        padding: EdgeInsets.all(12),
      ),
    );
  }
} 