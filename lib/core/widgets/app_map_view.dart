import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class AppMapView extends StatelessWidget {
  final MapCreatedCallback? onMapCreated;

  const AppMapView({super.key, this.onMapCreated});

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey("mapWidget"),
      onMapCreated: onMapCreated,
      cameraOptions: CameraOptions(
        // Fixed: center expects a Point object, not a JSON Map
        center: Point(coordinates: Position(76.2711, 10.8505)), // Default to Kerala
        zoom: 10.0,
      ),
    );
  }
}