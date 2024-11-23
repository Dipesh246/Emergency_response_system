import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MapScreen({Key? key, required this.latitude, required this.longitude}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  List<LatLng> _nearestPath = [];
  Marker? _responderMarker;
  Map<String, dynamic>? _responderDetails;
  bool _isLoading = true; // Flag to track loading state

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchNearestResponderPath();
  }

  // Fetch the nearest responder's path from the backend
  Future<void> _fetchNearestResponderPath() async {
    try {
      ApiService apiService = ApiService();
      final pathData = await apiService.getNearestResponderPath(widget.latitude, widget.longitude);

      if (pathData != null) {
        setState(() {
          // Parse the path coordinates
          _nearestPath = List<LatLng>.from(pathData['path'].map((coord) => LatLng(coord[0], coord[1])));

          // Create a marker for the nearest responder
          final responderLocation = _nearestPath.last; // Last point in the path
          _responderMarker = Marker(
            point: responderLocation,
            width: 80,
            height: 80,
            child: const Icon(
              Icons.person_pin_circle,
              color: Colors.blue,
              size: 40,
            ),
          );

          // Store responder details
          _responderDetails = {
            "id": pathData['responder_id'],
            "username": pathData['username'],
            "distance": pathData['distance']
          };
        });
      }
    } catch (e) {
      print("Error fetching nearest responder path: $e");
    } finally {
      setState(() {
        _isLoading = false; // Stop showing the loading screen
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearest Responder Path'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.latitude, widget.longitude),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'emergency_response_system',
              ),
              // Display the user's location marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(widget.latitude, widget.longitude),
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  if (_responderMarker != null) _responderMarker!,
                ],
              ),
              // Display the polyline for the nearest responder's path
              if (_nearestPath.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _nearestPath,
                      color: const Color.fromARGB(255, 134, 135, 135),
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
            ],
          ),
          // Loading screen with a blurred map
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4), // Dark semi-transparent overlay
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          // Show responder details once data is loaded
          if (!_isLoading && _responderDetails != null)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Responder: ${_responderDetails!['username']}"),
                      Text("Distance: ${_responderDetails!['distance'].toStringAsFixed(2)} km"),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
