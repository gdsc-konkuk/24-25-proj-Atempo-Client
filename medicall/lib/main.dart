import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFD94B4B),
        textTheme: GoogleFonts.notoSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD94B4B),
          primary: const Color(0xFFD94B4B),
        ),
      ),
      home: SplashScreen(),
    );
  }
}
