import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/services/screenshot_feedback_service.dart';

void main() {
  group('ScreenshotFeedbackService', () {
    test('should be singleton', () {
      final instance1 = ScreenshotFeedbackService.instance;
      final instance2 = ScreenshotFeedbackService.instance;

      expect(instance1, same(instance2));
    });

    test('should dispose without errors', () {
      final service = ScreenshotFeedbackService.instance;

      expect(() => service.dispose(), returnsNormally);
    });
  });
}
