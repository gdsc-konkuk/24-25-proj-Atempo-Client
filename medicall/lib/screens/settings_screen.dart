import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'faq_screen.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart'; // 추가된 import

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.notoSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: 'Medi'),
              WidgetSpan(
                child: Transform.translate(
                  offset: Offset(0, -2),
                  child: Icon(Icons.call, color: Colors.white, size: 20),
                ),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: 'all'),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFD94B4B),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.settings,
                    color: Colors.red[400],
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                title: Text(
                  'Search Radius',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('Current search radius setting'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '5km',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  // Handle search radius setting
                },
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.headset_mic_outlined,
                    color: Colors.red[400],
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Customer Service',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Contact Us',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('1:1 Inquiry'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to Contact Us screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ContactUsScreen()),
                      );
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    title: Text(
                      'FAQ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('Frequently Asked Questions'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to FAQ screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FAQScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red[400],
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'About Us',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('About our team and project'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutUsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
