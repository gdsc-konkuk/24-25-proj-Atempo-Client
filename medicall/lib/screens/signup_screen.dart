import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD94B4B),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              // Logo
              Center(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.notoSans(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'Med'),
                      WidgetSpan(
                        child: Icon(Icons.phone, color: Colors.white, size: 32),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      TextSpan(text: 'call'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Find the right ER, right now.",
                style: GoogleFonts.notoSans(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 40),
              // Ambulance image placeholder
              Image.asset(
                'assets/images/ambulance.png', // This image should be added to assets
                height: 200,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 40),
              // SignUp Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SignUp",
                      style: GoogleFonts.notoSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD94B4B),
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        // Navigate back to login
                        Navigator.of(context).pop();
                      },
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          children: [
                            TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Login",
                              style: TextStyle(
                                color: const Color(0xFFD94B4B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Google SignUp Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        // Add Google signup functionality
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google_logo.png', // This image should be added to assets
                            height: 24,
                          ),
                          SizedBox(width: 10),
                          Text("Sign up with Google"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
