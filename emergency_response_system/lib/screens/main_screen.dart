import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart'; // You should implement ApiService for API calls
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _detailsController = TextEditingController();
  bool isRequesting = false;
  MapController _mapController = MapController();
  LatLng _currentLocation = LatLng(27.7172, 85.3240);
  bool _locationFetched = false;
  List<LatLng> respondersLocations = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _fetchResponders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Widget
          _buildMap(),

          // Customer Request Form
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.25,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextField(
                    controller: _detailsController,
                    decoration: InputDecoration(
                      labelText: 'Enter emergency details (optional)',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isRequesting ? null : _sendEmergencyRequest,
                    child: isRequesting
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Send Emergency Request"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build Map widget
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation,
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
              width: 80.0,
              height: 80.0,
              point: _currentLocation,
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
            // Add markers for each responder's location
            ...respondersLocations.map(
              (responderLocation) => Marker(
                width: 80.0,
                height: 80.0,
                point: responderLocation,
                child: Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Fetch the current location
  Future<void> _fetchCurrentLocation() async {
    LocationService locationService = LocationService();
    Position? position = await locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationFetched = true;
        _mapController.move(_currentLocation, 15.0);
      });

      
      await locationService.updateResponderLocation(position.latitude, position.longitude);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to get current location.")),
      );
    }
  }

  Future<void> _fetchResponders() async {
    try {
      ApiService apiService = ApiService();
      List<dynamic> responders = await apiService.fetchResponders();
      setState(() {
        respondersLocations = responders.map((responder) {
          return LatLng(responder['latitude'], responder['longitude']);
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching responders: $e")),
      );
    }
  }

  // Send emergency request to the backend
  Future<void> _sendEmergencyRequest() async {
    setState(() {
      isRequesting = true;
    });

    try {
      if (!_locationFetched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location not available.")),
        );
        return;
      }

      String details = _detailsController.text;
      bool requestSent = await ApiService().sendEmergencyRequest(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        details: details,
      );

      if (requestSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Emergency request sent successfully!")),
        );
         // Navigate to MapScreen after the request is sent
        Navigator.pushNamed(
          context,
          '/map',
          arguments: {
            'latitude': _currentLocation.latitude,
            'longitude': _currentLocation.longitude,
          },
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send emergency request.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isRequesting = false;
      });
    }
  }
}
