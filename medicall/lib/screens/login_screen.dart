import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_screen.dart';
import 'map_screen.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                // Logo
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.notoSans(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(text: 'Med'),
                        WidgetSpan(
                          child: Transform.translate(
                            offset: Offset(0, -2),
                            child: Icon(Icons.call, color: const Color(0xFFD94B4B), size: 32),
                          ),
                          alignment: PlaceholderAlignment.middle,
                        ),
                        TextSpan(text: 'all'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    "Find the right ER, right now.",
                    style: GoogleFonts.notoSans(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 60),
                // Ambulance image 
                Center(
                  child: Container(
                    height: 240,
                    child: Image.asset(
                      'assets/images/ambulance.png', // Updated to use the new ambulance image
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 60),
                // Login Section
                Text(
                  "Login",
                  style: GoogleFonts.notoSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    // Navigate to signup with custom animation
                    Navigator.of(context).push(_createRoute());
                  },
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      children: [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color: const Color(0xFF323232),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Google Login Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    // Show a snackbar message for successful login
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Login successful!"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    
                    // 오류 처리를 위한 try-catch 블록 추가
                    try {
                      // Navigate after a short delay
                      Future.delayed(Duration(seconds: 1), () {
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MapScreen()),
                        );
                      });
                    } catch (e) {
                      // 오류 발생 시 메시지 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("오류가 발생했습니다: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google_logo.png',
                        height: 24,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Continue with Google",
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.w500,
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
      ),
    );
  }

  // Custom route for animated transition
  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SignUpScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Animation<double> sizeAnimation = Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
            
        return Stack(
          children: [
            PositionedTransition(
              rect: RelativeRectTween(
                begin: RelativeRect.fromLTRB(
                  MediaQuery.of(context).size.width, 
                  MediaQuery.of(context).size.height, 
                  0, 
                  0
                ),
                end: RelativeRect.fill,
              ).animate(animation),
              child: Container(color: const Color(0xFFD94B4B)),
            ),
            ScaleTransition(
              scale: sizeAnimation,
              alignment: Alignment.bottomRight,
              child: child,
            ),
          ],
        );
      },
    );
  }
}
