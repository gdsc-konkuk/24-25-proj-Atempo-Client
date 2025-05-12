import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorScreen extends StatelessWidget {
  final String title;
  final String errorMessage;
  final VoidCallback? onRetry;
  final Widget? additionalContent;
  final String backButtonText;

  const ErrorScreen({
    Key? key,
    this.title = 'Error occurred',
    required this.errorMessage,
    this.onRetry,
    this.additionalContent,
    this.backButtonText = 'Go back',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Error information',
          style: TextStyle(
            fontFamily: 'Pretendard',
            color: Colors.white, 
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFFE93C4A),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Color(0xFFE93C4A),
                  size: 80,
                ),
                SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (additionalContent != null) ...[
                  SizedBox(height: 24),
                  additionalContent!,
                ],
                SizedBox(height: 40),
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE93C4A),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      textStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back),
                  label: Text(backButtonText),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    textStyle: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Alias for compatibility with previous versions
class NavigationErrorScreen extends ErrorScreen {
  const NavigationErrorScreen({
    Key? key,
    required String errorMessage,
    VoidCallback? onRetry,
  }) : super(
    key: key,
    title: 'Cannot start navigation',
    errorMessage: errorMessage,
    onRetry: onRetry,
  );
} 