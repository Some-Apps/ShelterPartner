import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class GeorestrictionMapView extends StatefulWidget {
  final LatLng initialLocation;  // Initial map center location
  final double initialRadius;    // Initial radius of the circle overlay
  final double initialZoomLevel; // Initial zoom level of the map

  const GeorestrictionMapView({
    super.key,
    required this.initialLocation,
    required this.initialRadius,
    required this.initialZoomLevel,
  });

  @override
  _GeorestrictionMapViewState createState() => _GeorestrictionMapViewState();
}

class _GeorestrictionMapViewState extends State<GeorestrictionMapView> {
  GoogleMapController? _mapController;
  late LatLng _center;
  late double _radius;
  late double _zoomLevel;
  Circle? _circle;

  @override
  void initState() {
    super.initState();
    _center = widget.initialLocation;
    _radius = widget.initialRadius;
    _zoomLevel = widget.initialZoomLevel;

    // Debug print to check zoom level
    print("Initial Zoom Level: $_zoomLevel");

    // Initialize the circle overlay
    _circle = Circle(
      circleId: const CircleId("geo_restriction_circle"),
      center: _center,
      radius: _radius,
      strokeColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(0.3),
      strokeWidth: 2,
    );
  }

  // Center the map on the user's current location using Geolocator
  Future<void> _centerOnUserLocation() async {
    try {
      // Check permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return; // If permission is denied, return early.
        }
      }

      // Fetch the user's current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = userLocation;
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, _zoomLevel));
        _updateCircle();
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // Update the circular overlay when the center or radius changes
  void _updateCircle() {
    setState(() {
      _circle = Circle(
        circleId: const CircleId("geo_restriction_circle"),
        center: _center,
        radius: _radius,
        strokeColor: Colors.blue,
        fillColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        

        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,  // Set the map height to 70% of screen height
          width: double.infinity,  // Set the map width to match parent width
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: _zoomLevel,
            ),
            mapType: MapType.satellite, // Map type set to normal
            myLocationEnabled: true,
            onMapCreated: (GoogleMapController controller) {
  _mapController = controller;
  print("Map Created - controller assigned");
  
  _mapController?.animateCamera(CameraUpdate.newCameraPosition(
    CameraPosition(target: _center, zoom: _zoomLevel),
  ));
},

            circles: _circle != null ? {_circle!} : {},  // Ensure the circle isn't null
            onCameraMove: (CameraPosition position) {
              setState(() {
                _center = position.target;  // Update center when map is moved
                _zoomLevel = position.zoom; // Update zoom level when map is zoomed
                _updateCircle();            // Update the circular overlay
              });
            },
            indoorViewEnabled: false,  // Enable indoor view for testing
            trafficEnabled: false,     // Enable traffic layer for testing
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _centerOnUserLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Row(
            children: [
              Text("Radius: ${_radius.toStringAsFixed(0)}m"),
              const SizedBox(width: 10),
              Slider(
                min: 100.0,
                max: 5000.0,
                divisions: 50,
                value: _radius,
                onChanged: (value) {
                  setState(() {
                    _radius = value;  // Update the radius
                    _updateCircle();
                  });
                },
              ),
            ],
          ),
        ),
        // Zoom slider
        Positioned(
          bottom: 50,
          left: 20,
          child: Row(
            children: [
              Text("Zoom: ${_zoomLevel.toStringAsFixed(1)}"),
              Slider(
                min: 1.0,
                max: 20.0,
                value: _zoomLevel,
                onChanged: (value) {
                  setState(() {
                    _zoomLevel = value;
                    _mapController?.moveCamera(CameraUpdate.zoomTo(_zoomLevel));
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
