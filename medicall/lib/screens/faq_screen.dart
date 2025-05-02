import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

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
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.red[400],
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // FAQ Items
          _buildFAQItem(
            context,
            "What is Medicall?",
            "Medicall is an AI-powered hospital auto-matching system designed for paramedics.\n\n"
            "The app calls hospitals on behalf of the user, collects real-time bed availability via automated response, "
            "and matches the patient to the most appropriate emergency room as quickly as possible.",
          ),
          
          _buildFAQItem(
            context,
            "What technology powers this app?",
            "Medicall is built with the following technologies:\n"
            "• Developed in Flutter to support Android-based paramedic PDAs\n"
            "• Gemini AI analyzes patient data and suggests appropriate hospitals\n"
            "• TTS (Text-to-Speech) generates voice messages to communicate with hospitals\n"
            "• Twilio API enables simultaneous (parallel) phone calls to multiple hospitals\n"
            "• Responses via dial-tone input are collected and ranked\n"
            "• Google Maps API provides optimized navigation to the selected hospital",
          ),
          
          _buildFAQItem(
            context,
            "How does it work?",
            "1. The paramedic enters the patient's condition and location into the app\n"
            "2. AI analyzes the situation and identifies candidate hospitals\n"
            "3. A voice message is auto-generated and calls are placed to the hospitals\n"
            "4. Each hospital responds using dial-tone input (e.g., 1 for available, 2 for unavailable)\n"
            "5. The app ranks the hospitals based on response and selects the best match\n"
            "6. Directions to the selected hospital are provided immediately in-app",
          ),
          
          _buildFAQItem(
            context,
            "Who can use Medicall?",
            "Medicall is currently available only for verified paramedics.\n"
            "Users must be affiliated with a registered institution, and "
            "device verification and a unique access code are required upon first login.\n\n"
            "Although the app is currently limited to emergency responders, "
            "we are planning to add features in the future that allow general users "
            "to find nearby emergency hospitals in urgent situations.",
          ),
          
          _buildFAQItem(
            context,
            "How does a hospital respond to the call?",
            "Medicall automatically dials the hospital's emergency contact number.\n"
            "A TTS-generated voice message presents patient details, "
            "and the hospital staff responds by pressing a number (e.g., 1 = available).\n"
            "The app records the response in real-time and displays available hospitals to the user instantly.",
          ),
          
          _buildFAQItem(
            context,
            "How are hospitals connected with Medicall?",
            "Currently, Medicall is integrated only with partnered or test hospitals.\n"
            "The system operates based on prior agreements or MoUs with each hospital.\n"
            "We aim to expand integration to public emergency medical networks in the future.",
          ),
          
          _buildFAQItem(
            context,
            "How is user data handled?",
            "Medicall does not collect personally identifiable information such as names or national IDs.\n"
            "Only essential data—such as symptoms, approximate age, and current location—is used.\n"
            "All information is encrypted during transmission and is not stored.",
          ),
          
          _buildFAQItem(
            context,
            "Can the app be used outside of real emergencies?",
            "Currently, Medicall is intended for use in real emergency scenarios or authorized simulation training only.\n"
            "Unauthorized or abnormal use is restricted and will be automatically blocked by the server.",
          ),
          
          _buildFAQItem(
            context,
            "How can I get support or ask questions?",
            "📧 Email us at: medicall.developer@gmail.com",
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer, {bool isLast = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.only(bottom: 2),
          elevation: 0,
          color: const Color(0xFFD94B4B).withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.help, color: const Color(0xFFD94B4B), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
