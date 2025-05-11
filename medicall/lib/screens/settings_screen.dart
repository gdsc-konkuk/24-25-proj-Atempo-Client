import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'faq_screen.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _showSearchRadiusModal() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    double tempRadius = settingsProvider.searchRadius;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  color: Color(0xFFFEEBEB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Search Radius Settings',
                      style: AppTheme.textTheme.displaySmall,
                    ),
                    SizedBox(height: 20),
                    Text(
                      '${tempRadius.toInt()}km',
                      style: AppTheme.textTheme.bodyLarge,
                    ),
                    SizedBox(height: 10),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primaryColor,
                        inactiveTrackColor: Colors.grey[300],
                        thumbColor: AppTheme.primaryColor,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 8.0,
                        ),
                        overlayColor: AppTheme.primaryColor.withAlpha(50),
                      ),
                      child: Slider(
                        min: 1,
                        max: 50,
                        divisions: 49,
                        value: tempRadius,
                        onChanged: (value) {
                          setModalState(() {
                            tempRadius = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await settingsProvider.setSearchRadius(tempRadius);
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Confirm',
                            style: GoogleFonts.notoSans(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchRadius = context.watch<SettingsProvider>().searchRadius;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppTheme.buildAppBar(
        title: 'Settings',
        leading: AppTheme.buildBackButton(context),
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
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: AppTheme.textTheme.displayMedium,
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
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Current search radius setting',
                  style: AppTheme.textTheme.bodyMedium,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${searchRadius.toInt()}km',
                      style: AppTheme.textTheme.bodyLarge,
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
                onTap: _showSearchRadiusModal,
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.headset_mic_outlined,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Customer Service',
                    style: AppTheme.textTheme.displaySmall,
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
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '1:1 Inquiry',
                      style: AppTheme.textTheme.bodyMedium,
                    ),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
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
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Frequently Asked Questions',
                      style: AppTheme.textTheme.bodyMedium,
                    ),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
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
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'About',
                    style: AppTheme.textTheme.displaySmall,
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
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'About our team and project',
                      style: AppTheme.textTheme.bodyMedium,
                    ),
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
