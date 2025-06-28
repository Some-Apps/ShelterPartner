import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/config/app_environment.dart';
import 'package:shelter_partner/config/service_urls.dart';

void main() {
  group('AppEnvironment', () {
    test(
      'development() should create development environment with correct properties',
      () {
        final env = AppEnvironment.development();

        expect(env.isProduction, false);
        expect(env.isDebugMode, true);
        expect(env.environment, 'development');
        expect(env.serviceUrls, isA<ServiceUrls>());
        expect(env.serviceUrls.corsImagesUrl, contains('development-e5282'));
      },
    );

    test(
      'production() should create production environment with correct properties',
      () {
        final env = AppEnvironment.production();

        expect(env.isProduction, true);
        expect(env.isDebugMode, false);
        expect(env.environment, 'production');
        expect(env.serviceUrls, isA<ServiceUrls>());
        expect(
          env.serviceUrls.corsImagesUrl,
          contains('cors-images-222422545919'),
        );
      },
    );

    test('toString() should include environment and service URLs', () {
      final env = AppEnvironment.development();

      final result = env.toString();

      expect(result, contains('AppEnvironment'));
      expect(result, contains('development'));
      expect(result, contains('urls:'));
    });
  });
}
