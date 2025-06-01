import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shelter_partner/models/shelter.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';

class GeorestrictionSettingsPage extends ConsumerStatefulWidget {
  const GeorestrictionSettingsPage({super.key});

  @override
  _GeorestrictionSettingsPageState createState() =>
      _GeorestrictionSettingsPageState();
}

class _GeorestrictionSettingsPageState
    extends ConsumerState<GeorestrictionSettingsPage> {
  GoogleMapController? _mapController;
  LatLng? _center;
  double _radius = 1000;
  double _zoomLevel = 10;
  Circle? _circle;
  String _locationOption = 'Screen';
  String _address = '';
  String? _selectedAddress;
  List<AddressSuggestion> _addressSuggestions = [];

  // Replace with your actual API URL
  final String placesApiUrl =
      'https://places-api-222422545919.us-central1.run.app';

  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode(); // Create a FocusNode

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocusNode.dispose(); // Dispose of the FocusNode
    super.dispose();
  }

  // Fetch address suggestions using your Cloud Function
  Future<void> _fetchAddressSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _addressSuggestions = [];
      });
      return;
    }

    final url = Uri.parse('$placesApiUrl?input=$input');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final suggestions = data['predictions'] as List;

      setState(() {
        _addressSuggestions = suggestions.map((suggestion) {
          return AddressSuggestion(
            description: suggestion['description'] as String,
            placeId: suggestion['place_id'] as String,
          );
        }).toList();
      });
    } else {
      print('Error fetching address suggestions: ${response.body}');
    }
  }

  // Fetch place details using the Cloud Function API
  Future<void> _getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://places-api-details-222422545919.us-central1.run.app?place_id=$placeId',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final LatLng placeLocation = LatLng(location['lat'], location['lng']);
          setState(() {
            _center = placeLocation;
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_center!, _zoomLevel),
            );
            _updateCircle();
          });
        } else {
          _showErrorMessage('Unable to get location details.');
        }
      } else {
        _showErrorMessage('Unable to get location details.');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    }
  }

  // Center the map on the user's current location
  Future<void> _centerOnUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = userLocation;
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_center!, _zoomLevel),
        );
        _updateCircle();
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _updateCircle() {
    setState(() {
      _circle = Circle(
        circleId: const CircleId("geo_restriction_circle"),
        center: _center!,
        radius: _radius,
        strokeColor: Colors.blue,
        fillColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 2,
      );
    });
  }

  // Show error message when location cannot be found
  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Address Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Slider for radius
  Widget _buildRadiusSlider() {
    return Column(
      children: [
        Text('Radius: ${_radius.toStringAsFixed(0)} meters'),
        Slider(
          value: _radius,
          min: 10,
          max: 5000,
          divisions: 100,
          label: _radius.toStringAsFixed(0),
          onChanged: (value) {
            setState(() {
              _radius = value;
              _updateCircle();
            });
          },
        ),
      ],
    );
  }

  // Slider for zoom level
  Widget _buildZoomSlider() {
    return Column(
      children: [
        Text('Zoom Level: ${_zoomLevel.toStringAsFixed(1)}'),
        Slider(
          value: _zoomLevel,
          min: 9,
          max: 20,
          divisions: 100,
          label: _zoomLevel.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _zoomLevel = value;
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: _center!, zoom: _zoomLevel),
                ),
              );
            });
          },
        ),
      ],
    );
  }

  // Save changes button
  Widget _buildSaveButton(Shelter shelter) {
    return ElevatedButton(
      onPressed: () {
        if (_center != null) {
          ref
              .read(volunteersViewModelProvider.notifier)
              .changeGeofence(
                shelter.id,
                GeoPoint(_center!.latitude, _center!.longitude),
                _radius,
                _zoomLevel,
              );
          Navigator.of(context).pop();
          print('Save changes pressed');
        } else {
          _showErrorMessage('Center location is not set.');
        }
      },
      child: const Text('Save Changes'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(volunteersViewModelProvider);

    return shelterAsyncValue.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text("Georestriction Settings")),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text("Georestriction Settings")),
        body: Center(child: Text('Error: $error')),
      ),
      data: (shelter) {
        // Initialize the variables if they are not initialized yet
        if (_center == null) {
          _center = LatLng(
            shelter?.volunteerSettings.geofence?.location.latitude ?? 37.7749,
            shelter?.volunteerSettings.geofence?.location.longitude ??
                -122.4194,
          );
          _radius = shelter?.volunteerSettings.geofence?.radius ?? 1000;
          _zoomLevel = shelter?.volunteerSettings.geofence?.zoom ?? 10;
          _updateCircle();
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Georestriction Settings")),
          body: SafeArea(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(
                  context,
                ).unfocus(); // Unfocus when tapping outside
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Map Section
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _center!,
                            zoom: _zoomLevel,
                          ),
                          mapType: MapType.satellite,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                            _mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: _center!,
                                  zoom: _zoomLevel,
                                ),
                              ),
                            );
                          },
                          circles: _circle != null ? {_circle!} : {},
                          onCameraMove: (CameraPosition position) {
                            if (_locationOption == 'Screen') {
                              setState(() {
                                _center = position.target;
                                _zoomLevel = position.zoom;
                                _updateCircle();
                              });
                              // Unfocus the TextField when the map moves
                              _addressFocusNode.unfocus();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Options Section without Expanded
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Dropdown Menu
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _locationOption,
                                decoration: const InputDecoration(
                                  labelText: "Geofence Center",
                                ),
                                items: ['Screen', 'Current Location', 'Address']
                                    .map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    })
                                    .toList(),
                                onChanged: (String? newValue) async {
                                  if (newValue != null) {
                                    setState(() {
                                      _locationOption = newValue;
                                      _selectedAddress =
                                          null; // Reset selected address
                                      _addressController
                                          .clear(); // Clear the text field
                                      _addressSuggestions =
                                          []; // Clear suggestions
                                    });

                                    if (newValue == 'Current Location') {
                                      await _centerOnUserLocation();
                                    }
                                  }
                                },
                              ),
                            ),
                            // Address Input and Suggestions
                            if (_locationOption == 'Address') ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 10.0,
                                ),
                                child: TextField(
                                  controller: _addressController,
                                  focusNode:
                                      _addressFocusNode, // Attach the FocusNode
                                  decoration: const InputDecoration(
                                    labelText: 'Enter Address',
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _address = value;
                                    });
                                    _fetchAddressSuggestions(value);
                                  },
                                ),
                              ),
                              if (_addressSuggestions.isNotEmpty)
                                SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    itemCount: _addressSuggestions.length,
                                    itemBuilder: (context, index) {
                                      final suggestion =
                                          _addressSuggestions[index];
                                      return ListTile(
                                        title: Text(suggestion.description),
                                        onTap: () async {
                                          setState(() {
                                            _selectedAddress =
                                                suggestion.description;
                                            _addressController.clear();
                                            _addressSuggestions = [];
                                            _addressFocusNode.unfocus();
                                          });
                                          await _getPlaceDetails(
                                            suggestion.placeId,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                            const SizedBox(height: 20),
                            // Sliders and Save Button
                            _buildRadiusSlider(),
                            const SizedBox(height: 10),
                            _buildZoomSlider(),
                            const SizedBox(height: 20),
                            if (shelter != null) _buildSaveButton(shelter),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Define a model for address suggestions
class AddressSuggestion {
  final String description;
  final String placeId;

  AddressSuggestion({required this.description, required this.placeId});
}
