import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart'; // Import the LocationService
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  LatLng _currentLatLng = LatLng(27.7172, 85.3240); // Default to Kathmandu

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  // Fetch current location and update responder location
  Future<void> _getCurrentLocation() async {
    LocationService locationService = LocationService();
    Position? position = await locationService.getCurrentLocation();

    if (position != null) {
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentLatLng, 15.0); // Move the map to the new location
      });

      // Send the location update to the backend
      await locationService.updateResponderLocation(position.latitude, position.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Response Map'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLatLng,  // Dynamically update the center
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'emergency_response_system',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLatLng,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}