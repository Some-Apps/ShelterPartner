/// Service URL configuration for different environments
///
/// Provides URLs for cloud functions and API services with environment variable
/// support and fallback values for production and development environments.
class ServiceUrls {
  /// CORS image proxy service URL
  final String corsImagesUrl;

  /// Main API service URL
  final String apiUrl;

  /// Delete volunteer service URL
  final String deleteVolunteerUrl;

  /// Invite volunteer service URL
  final String inviteVolunteerUrl;

  /// Places API service URL
  final String placesApiUrl;

  /// Places API details service URL
  final String placesApiDetailsUrl;

  const ServiceUrls._({
    required this.corsImagesUrl,
    required this.apiUrl,
    required this.deleteVolunteerUrl,
    required this.inviteVolunteerUrl,
    required this.placesApiUrl,
    required this.placesApiDetailsUrl,
  });

  /// Create service URLs for development environment
  factory ServiceUrls.development() {
    return const ServiceUrls._(
      corsImagesUrl: String.fromEnvironment(
        'CORS_IMAGES_URL',
        defaultValue: 'https://us-central1-development-e5282.cloudfunctions.net/cors_images',
      ),
      apiUrl: String.fromEnvironment(
        'API_URL',
        defaultValue: 'https://api-dev-222422545919.us-central1.run.app',
      ),
      deleteVolunteerUrl: String.fromEnvironment(
        'DELETE_VOLUNTEER_URL',
        defaultValue: 'https://delete-volunteer-dev-222422545919.us-central1.run.app',
      ),
      inviteVolunteerUrl: String.fromEnvironment(
        'INVITE_VOLUNTEER_URL',
        defaultValue: 'https://invite-volunteer-dev-222422545919.us-central1.run.app',
      ),
      placesApiUrl: String.fromEnvironment(
        'PLACES_API_URL',
        defaultValue: 'https://places-api-dev-222422545919.us-central1.run.app',
      ),
      placesApiDetailsUrl: String.fromEnvironment(
        'PLACES_API_DETAILS_URL',
        defaultValue: 'https://places-api-details-dev-222422545919.us-central1.run.app',
      ),
    );
  }

  /// Create service URLs for production environment
  factory ServiceUrls.production() {
    return const ServiceUrls._(
      corsImagesUrl: String.fromEnvironment(
        'CORS_IMAGES_URL',
        defaultValue: 'https://cors-images-222422545919.us-central1.run.app',
      ),
      apiUrl: String.fromEnvironment(
        'API_URL',
        defaultValue: 'https://api-222422545919.us-central1.run.app',
      ),
      deleteVolunteerUrl: String.fromEnvironment(
        'DELETE_VOLUNTEER_URL',
        defaultValue: 'https://delete-volunteer-222422545919.us-central1.run.app',
      ),
      inviteVolunteerUrl: String.fromEnvironment(
        'INVITE_VOLUNTEER_URL',
        defaultValue: 'https://invite-volunteer-222422545919.us-central1.run.app',
      ),
      placesApiUrl: String.fromEnvironment(
        'PLACES_API_URL',
        defaultValue: 'https://places-api-222422545919.us-central1.run.app',
      ),
      placesApiDetailsUrl: String.fromEnvironment(
        'PLACES_API_DETAILS_URL',
        defaultValue: 'https://places-api-details-222422545919.us-central1.run.app',
      ),
    );
  }

  /// Build CORS image URL with the given image URL
  String corsImageUrl(String imageUrl) {
    return '$corsImagesUrl?url=${Uri.encodeComponent(imageUrl)}';
  }

  /// Build Places API details URL with the given place ID
  String placesApiDetailsUrlWithPlaceId(String placeId) {
    return '$placesApiDetailsUrl?place_id=$placeId';
  }

  @override
  String toString() => 'ServiceUrls(corsImages: $corsImagesUrl, api: $apiUrl)';
}