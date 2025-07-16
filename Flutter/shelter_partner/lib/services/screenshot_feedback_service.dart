import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:shelter_partner/views/components/feedback_submission_dialog.dart';

class ScreenshotFeedbackService {
  static ScreenshotFeedbackService? _instance;
  static ScreenshotFeedbackService get instance =>
      _instance ??= ScreenshotFeedbackService._();

  ScreenshotFeedbackService._();

  ScreenshotCallback? _screenshotCallback;
  BuildContext? _context;

  /// Initialize screenshot detection for mobile platforms
  void initialize(BuildContext context) {
    // Only enable on mobile platforms (iOS and Android)
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return;
    }

    _context = context;
    _screenshotCallback = ScreenshotCallback();

    _screenshotCallback?.addListener(() {
      _showScreenshotFeedbackDialog();
    });
  }

  /// Show feedback dialog when screenshot is detected
  void _showScreenshotFeedbackDialog() {
    // Use post-frame callback to ensure we show dialog after screenshot event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_context != null && _context!.mounted) {
        showDialog(
          context: _context!,
          builder: (context) => AlertDialog(
            title: const Text('Screenshot Detected'),
            content: const Text(
              'Would you like to submit feedback about the app? You can include this screenshot with your feedback.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Not Now'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Show feedback dialog
                  showDialog(
                    context: context,
                    builder: (context) => const FeedbackSubmissionDialog(),
                  );
                },
                child: const Text('Submit Feedback'),
              ),
            ],
          ),
        );
      }
    });
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    _screenshotCallback?.dispose();
    _screenshotCallback = null;
    _context = null;
  }
}
