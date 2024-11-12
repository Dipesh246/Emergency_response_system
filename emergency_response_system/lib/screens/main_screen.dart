import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _detailsController = TextEditingController();
  bool isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Widget (Replace with your map implementation)
          Center(child: Text("Map goes here")),

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

  Future<void> _sendEmergencyRequest() async {
    setState(() {
      isRequesting = true;
    });

    try {
      // Get the current location
      Position? position = await LocationService().getCurrentLocation();
      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to get current location.")),
        );
        return;
      }

      // Send the request to the backend
      String details = _detailsController.text;
      bool requestSent = await ApiService().sendEmergencyRequest(
        latitude: position.latitude,
        longitude: position.longitude,
        details: details,
      );

      if (requestSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Emergency request sent successfully!")),
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
