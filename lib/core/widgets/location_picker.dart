import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geo;

class LocationPicker extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final Function(double lat, double lng) onLocationSelected;

  const LocationPicker({
    super.key,
    this.initialLatitude = 10.8505,
    this.initialLongitude = 76.2711,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  MapboxMap? _mapboxMap;
  Point? _selectedPoint;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  void _onMapTap(dynamic tapContext) {
    try {
      if (tapContext != null && tapContext.point != null) {
        final point = tapContext.point as Point;
        setState(() {
          _selectedPoint = point;
        });
        widget.onLocationSelected(
          point.coordinates.lat.toDouble(),
          point.coordinates.lng.toDouble(),
        );
      }
    } catch (e) {
      debugPrint("Map Tap Error: $e");
    }
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Using Mapbox Geocoding API
      final accessToken = await MapboxOptions.getAccessToken();
      final url = "https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?access_token=$accessToken&limit=1";
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final List<dynamic> center = feature['center']; // [lng, lat]
          
          final lat = center[1].toDouble();
          final lng = center[0].toDouble();

          final newPoint = Point(coordinates: Position(lng, lat));
          
          setState(() {
            _selectedPoint = newPoint;
          });

          // Move camera to the searched location
          _mapboxMap?.setCamera(CameraOptions(
            center: newPoint,
            zoom: 14.0,
          ));

          widget.onLocationSelected(lat, lng);
        } else {
          _showError("No place found for '$query'");
        }
      }
    } catch (e) {
      _showError("Search failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("Location services are disabled.");
      return;
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        _showError("Location permissions are denied");
        return;
      }
    }
    
    if (permission == geo.LocationPermission.deniedForever) {
      _showError("Location permissions are permanently denied.");
      return;
    } 

    setState(() {
      _isSearching = true;
    });

    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high
      );
      
      final lat = position.latitude;
      final lng = position.longitude;
      
      final newPoint = Point(coordinates: Position(lng, lat));
      
      setState(() {
        _selectedPoint = newPoint;
      });

      _mapboxMap?.setCamera(CameraOptions(
        center: newPoint,
        zoom: 14.0,
      ));

      widget.onLocationSelected(lat, lng);
    } catch (e) {
      _showError("Failed to get location: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_selectedPoint != null) {
                Navigator.pop(context);
              } else {
                _showError("Please select a location first");
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("locationPickerMap"),
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTap,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(widget.initialLongitude, widget.initialLatitude)),
              zoom: 12.0,
            ),
          ),
          
          // Search Bar
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Search for a place...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onSubmitted: (_) => _searchPlace(),
                      ),
                    ),
                    if (_isSearching)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchPlace,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Marker Pointer (Always in middle of map view for visual aid)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35), // Offset to point tip
              child: Icon(
                Icons.location_on,
                size: 40,
                color: Colors.red,
              ),
            ),
          ),

          if (_selectedPoint != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Location Selected",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Lat: ${_selectedPoint!.coordinates.lat.toStringAsFixed(6)}, Lng: ${_selectedPoint!.coordinates.lng.toStringAsFixed(6)}",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
