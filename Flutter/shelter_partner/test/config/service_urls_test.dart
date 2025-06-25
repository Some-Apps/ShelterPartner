import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/config/service_urls.dart';

void main() {
  group('ServiceUrls', () {
    test('development() should create ServiceUrls with development defaults', () {
      final urls = ServiceUrls.development();

      expect(urls.corsImagesUrl, 'https://us-central1-development-e5282.cloudfunctions.net/cors_images');
      expect(urls.apiUrl, 'https://api-dev-222422545919.us-central1.run.app');
      expect(urls.deleteVolunteerUrl, 'https://delete-volunteer-dev-222422545919.us-central1.run.app');
      expect(urls.inviteVolunteerUrl, 'https://invite-volunteer-dev-222422545919.us-central1.run.app');
      expect(urls.placesApiUrl, 'https://places-api-dev-222422545919.us-central1.run.app');
      expect(urls.placesApiDetailsUrl, 'https://places-api-details-dev-222422545919.us-central1.run.app');
    });

    test('production() should create ServiceUrls with production defaults', () {
      final urls = ServiceUrls.production();

      expect(urls.corsImagesUrl, 'https://cors-images-222422545919.us-central1.run.app');
      expect(urls.apiUrl, 'https://api-222422545919.us-central1.run.app');
      expect(urls.deleteVolunteerUrl, 'https://delete-volunteer-222422545919.us-central1.run.app');
      expect(urls.inviteVolunteerUrl, 'https://invite-volunteer-222422545919.us-central1.run.app');
      expect(urls.placesApiUrl, 'https://places-api-222422545919.us-central1.run.app');
      expect(urls.placesApiDetailsUrl, 'https://places-api-details-222422545919.us-central1.run.app');
    });

    test('corsImageUrl() should build correct CORS image URL', () {
      final urls = ServiceUrls.production();
      const testImageUrl = 'https://example.com/image.jpg';

      final result = urls.corsImageUrl(testImageUrl);

      expect(result, 'https://cors-images-222422545919.us-central1.run.app?url=https%3A%2F%2Fexample.com%2Fimage.jpg');
    });

    test('placesApiDetailsUrlWithPlaceId() should build correct Places API details URL', () {
      final urls = ServiceUrls.production();
      const testPlaceId = 'ChIJN1t_tDeuEmsRUsoyG83frY4';

      final result = urls.placesApiDetailsUrlWithPlaceId(testPlaceId);

      expect(result, 'https://places-api-details-222422545919.us-central1.run.app?place_id=ChIJN1t_tDeuEmsRUsoyG83frY4');
    });

    test('toString() should return readable string representation', () {
      final urls = ServiceUrls.development();

      final result = urls.toString();

      expect(result, contains('ServiceUrls'));
      expect(result, contains('corsImages'));
      expect(result, contains('development-e5282'));
    });
  });
}