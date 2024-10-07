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
      location: data['location'] as GeoPoint,
      radius: (data['radius'] != null ? (data['radius'] as num).toDouble() : 1000.0), // Default to 1000.0 if null
      zoom: (data['zoom'] != null ? (data['zoom'] as num).toDouble() : 14.0),
      isEnabled: data['isEnabled'] ?? false,
    );
  }
}