import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmtLicenseVerificationScreen extends StatefulWidget {
  const EmtLicenseVerificationScreen({Key? key}) : super(key: key);

  @override
  _EmtLicenseVerificationScreenState createState() => _EmtLicenseVerificationScreenState();
}

class _EmtLicenseVerificationScreenState extends State<EmtLicenseVerificationScreen> {
  String dropdownValue = 'Level 1';
  final TextEditingController _licenseController = TextEditingController();

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Title
              Text(
                'Enter Your',
                style: GoogleFonts.notoSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'EMT License Number',
                style: GoogleFonts.notoSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                'This service is only available for certified EMTs.',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              // License level dropdown and text field
              Row(
                children: [
                  // Dropdown
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: DropdownButton<String>(
                        value: dropdownValue,
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              dropdownValue = newValue;
                            });
                          }
                        },
                        items: <String>['Level 1', 'Level 2', 'Level 3']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // License number text field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _licenseController,
                        decoration: InputDecoration(
                          hintText: 'EMT-1234',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // "Don't know your license number?" link
              Center(
                child: GestureDetector(
                  onTap: () {
                    // No functionality as requested
                  },
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Don't know your license number? ",
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        TextSpan(
                          text: 'Learn more',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Verify button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // No functionality as requested
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD94B4B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Verify License',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
