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
  List<List<LatLng>> _allPaths = [];
  List<Marker> _responderMarkers = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchTemporaryPaths();
  }

  // Fetch paths to nearby responders from the backend
  Future<void> _fetchTemporaryPaths() async {
    ApiService apiService = ApiService();
    final pathData = await apiService.getTemporaryPaths(widget.latitude, widget.longitude);

    if (pathData != null) {
      setState(() {
        // Parse the paths and markers for responders
        _allPaths = pathData.map((path) {
          return List<LatLng>.from(path['coordinates'].map((coord) => LatLng(coord[0], coord[1])));
        }).toList();

        // Create markers for each responder
        _responderMarkers = pathData.map((path) {
          final responderLocation = path['coordinates'].last;
          return Marker(
            point: LatLng(responderLocation[0], responderLocation[1]),
            width: 80,
            height: 80,
            child: const Icon(
              Icons.person_pin_circle,
              color: Colors.blue,
              size: 40,
            ),
          );
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temporary Paths to Responders'),
      ),
      body: FlutterMap(
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
          // Display markers for each responder
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
              ..._responderMarkers,
            ],
          ),
          // Display polylines for all paths to responders
          PolylineLayer(
            polylines: _allPaths.map((path) {
              return Polyline(
                points: path,
                color: const Color.fromARGB(255, 134, 135, 135),
                strokeWidth: 5.0,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
