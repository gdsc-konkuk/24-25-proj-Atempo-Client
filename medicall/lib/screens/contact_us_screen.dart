import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppTheme.buildAppBar(
        title: 'Contact Us',
        leading: AppTheme.buildBackButton(context),
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
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Contact Us',
                    style: AppTheme.textTheme.displayMedium,
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
                  side: BorderSide(color: AppTheme.primaryColor, width: 1.5), 
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.email_outlined, color: AppTheme.primaryColor, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Email Us',
                            style: AppTheme.textTheme.displaySmall,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Have a question or feedback? Reach out to us directly:',
                        style: AppTheme.textTheme.bodyMedium,
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
                                  // Copy email to clipboard
                                  Clipboard.setData(ClipboardData(text: 'medicall.developer@gmail.com'));
                                  // Show snackbar for copy notification
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
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
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
