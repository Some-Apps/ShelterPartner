import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class GeorestrictionMapView extends StatefulWidget {
  final LatLng initialLocation;
  final double initialRadius;
  final double initialZoomLevel;

  const GeorestrictionMapView({
    Key? key,
    required this.initialLocation,
    required this.initialRadius,
    required this.initialZoomLevel,
  }) : super(key: key);

  @override
  _GeorestrictionMapViewState createState() => _GeorestrictionMapViewState();
}

class _GeorestrictionMapViewState extends State<GeorestrictionMapView> {
  GoogleMapController? _mapController;
  late LatLng _center;
  late double _radius;
  late double _zoomLevel;
  Circle? _circle;
  String _locationOption = 'Neither';
  String _address = '';
  String? _selectedAddress;
  List<AddressSuggestion> _addressSuggestions = [];
  String googleApiKey = 'AIzaSyBGsaMT4Fo-4_d-z4NoTmPEPVUm9pjuWQE'; // Replace with your Google API key

  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _center = widget.initialLocation;
    _radius = widget.initialRadius;
    _zoomLevel = widget.initialZoomLevel;

    _circle = Circle(
      circleId: const CircleId("geo_restriction_circle"),
      center: _center,
      radius: _radius,
      strokeColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(0.3),
      strokeWidth: 2,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Fetch address suggestions using Google Places API
  Future<void> _fetchAddressSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _addressSuggestions = [];
      });
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleApiKey&components=country:us',
    );
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

  Future<void> _getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        final LatLng placeLocation = LatLng(location['lat'], location['lng']);
        setState(() {
          _center = placeLocation;
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_center, _zoomLevel),
          );
          _updateCircle();
        });
      } else {
        _showErrorMessage('Unable to get location details.');
      }
    } else {
      _showErrorMessage('Unable to get location details.');
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
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, _zoomLevel));
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
        center: _center,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map Section
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: _zoomLevel,
              ),
              mapType: MapType.satellite,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _mapController?.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: _center, zoom: _zoomLevel),
                ));
              },
              circles: _circle != null ? {_circle!} : {},
              onCameraMove: (CameraPosition position) {
                if (_locationOption == 'Neither') {
                  setState(() {
                    _center = position.target;
                    _zoomLevel = position.zoom;
                    _updateCircle();
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Options Section without Expanded
        SingleChildScrollView(
          child: Column(
            children: [
              // Dropdown Menu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _locationOption,
                  decoration: const InputDecoration(labelText: "Map Centering Option"),
                  items: ['Neither', 'Center on Current Location', 'Center on Address']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) async {
                    if (newValue != null) {
                      setState(() {
                        _locationOption = newValue;
                        _selectedAddress = null; // Reset selected address
                        _addressController.clear(); // Clear the text field
                        _addressSuggestions = []; // Clear suggestions
                      });

                      if (newValue == 'Center on Current Location') {
                        await _centerOnUserLocation();
                      }
                    }
                  },
                ),
              ),
              // Address Input and Suggestions
              if (_locationOption == 'Center on Address') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: TextField(
                    controller: _addressController,
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
                        final suggestion = _addressSuggestions[index];
                        return ListTile(
                          title: Text(suggestion.description),
                          onTap: () async {
                            setState(() {
                              _selectedAddress = suggestion.description;
                              _addressController.clear();
                              _addressSuggestions = [];
                            });
                            await _getPlaceDetails(suggestion.placeId);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// Define a model for address suggestions
class AddressSuggestion {
  final String description;
  final String placeId;

  AddressSuggestion({required this.description, required this.placeId});
}
