import 'package:cloud_firestore/cloud_firestore.dart';

class Geofence {
  final GeoPoint location;
  final double radius;
  final double zoom;
  final bool isEnabled;

  Geofence({
    required this.location,
    required this.radius,
    required this.zoom,
    this.isEnabled = false,
  });

  // Convert Geofence to Map<String, dynamic> for Firestore
  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'radius': radius,
      'zoom': zoom,
      'isEnabled': isEnabled,
    };
  }

  // Factory constructor to create Geofence from Firestore Map
  factory Geofence.fromMap(Map<String, dynamic> data) {
    return Geofence(
      location: (data['location'] != null
          ? data['location'] as GeoPoint
          : const GeoPoint(
              43.0722, -89.4008)), // Default to GeoPoint(0.0, 0.0) if null
      radius: (data['radius'] != null
          ? (data['radius'] as num).toDouble()
          : 500.0), // Default to 1000.0 if null
      zoom: (data['zoom'] != null
          ? (data['zoom'] as num).toDouble()
          : 15.0), // Default to 14.0 if null
      isEnabled: data['isEnabled'] ?? false, // Default to false if null
    );
  }
}
