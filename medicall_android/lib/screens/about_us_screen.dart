import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

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
        title: 'About Us',
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
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'About Us',
                    style: AppTheme.textTheme.displayLarge,
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Team Info
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school, color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Our Team',
                            style: AppTheme.textTheme.displayMedium,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Atempo from Konkuk University, South Korea',
                        style: AppTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'We are a team of students dedicated to improving emergency medical services through technology.',
                        style: AppTheme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Campaign Video
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  onTap: () {
                    _launchUrl('https://www.youtube.com/watch?v=BO4XVvRMoO0&ab_channel=Medicall');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.video_library, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Campaign Video',
                              style: AppTheme.textTheme.displayMedium,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/campaign_thumbnail.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.video_library,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.8),
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Watch our campaign video to learn more about Medicall',
                          style: AppTheme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // GitHub Repositories
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code, color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'GitHub Repositories',
                            style: AppTheme.textTheme.displayMedium,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // AI Repo
                      _buildGitHubLink(
                        context,
                        title: 'AI Repository',
                        description: 'ML models for patient data analysis and hospital matching',
                        url: 'https://github.com/gdsc-konkuk/24-25-proj-Atempo-AI',
                      ),
                      
                      Divider(height: 24),
                      
                      // Server Repo
                      _buildGitHubLink(
                        context,
                        title: 'Server Repository',
                        description: 'Backend services for Medicall application',
                        url: 'https://github.com/gdsc-konkuk/24-25-proj-Atempo-Server',
                      ),
                      
                      Divider(height: 24),
                      
                      // Mobile Repo
                      _buildGitHubLink(
                        context,
                        title: 'Mobile Repository',
                        description: 'Flutter client application for Android devices',
                        url: 'https://github.com/gdsc-konkuk/24-25-proj-Atempo-Client',
                        isLast: true,
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
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
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
  
  Widget _buildGitHubLink(
    BuildContext context, {
    required String title,
    required String description,
    required String url,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _launchUrl(url),
          child: Row(
            children: [
              Image.network(
                'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.code, size: 24);
                },
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTheme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }
}
