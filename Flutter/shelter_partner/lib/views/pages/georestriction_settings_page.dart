import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shelter_partner/views/components/georestriction_map_view.dart';

class GeorestrictionSettingsPage extends StatefulWidget {
  const GeorestrictionSettingsPage({Key? key}) : super(key: key);

  @override
  State<GeorestrictionSettingsPage> createState() => _GeorestrictionSettingsPageState();
}

class _GeorestrictionSettingsPageState extends State<GeorestrictionSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Georestriction Settings"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              GeorestrictionMapView(
                initialLocation: const LatLng(37.7749, -122.4194), // San Francisco, for example
                initialRadius: 1000, // Initial radius in meters
                initialZoomLevel: 14.0, // Initial zoom level
              ),
            ],
          ),
        ),
      ),
    );
  }
}
