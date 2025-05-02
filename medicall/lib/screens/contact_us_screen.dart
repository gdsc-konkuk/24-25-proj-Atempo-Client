import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.contact_support_outlined,
                    color: Colors.red[400],
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Email Contact Card 
              Card(
                elevation: 2,
                color: Colors.white, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: const Color(0xFFD94B4B), width: 1.5), 
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.email_outlined, color: const Color(0xFFD94B4B), size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Email Us',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF303030),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Have a question or feedback? Reach out to us directly:',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      InkWell(
                        onTap: () => _launchUrl('mailto:medicall.developer@gmail.com'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'medicall.developer@gmail.com',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.content_copy, color: Colors.grey),
                                onPressed: () {
                                  // 클립보드에 이메일 복사
                                  Clipboard.setData(ClipboardData(text: 'medicall.developer@gmail.com'));
                                  // 스낵바로 복사 알림
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Email copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.open_in_new, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'We typically respond within 24-48 hours',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
                      
              // Copyright footer
              Center(
                child: Text(
                  '© 2025 Atempo, Konkuk University',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
