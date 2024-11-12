import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class LocationService {
  final String apiUrl = 'http://192.168.1.78:8002/api';  // Your backend API URL

  // Function to get the access token from SharedPreferences
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');  // Fetch the access token
  }

  // Function to extract the user ID from the JWT token
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');  // Fetch the user_id
  }

  // Function to update responder's location
  Future<void> updateResponderLocation(double latitude, double longitude) async {
    final token = await getAccessToken();

    if (token == null) {
      print('No access token found. Please log in.');
      return;
    }

    final userId = await getUserId();
    if (userId == null) {
      print('User ID not found. Please log in again.');
      return;
    }

    final patch_url = Uri.parse('$apiUrl/responders/userId');
    final post_url = Uri.parse('$apiUrl/responders');
    final headers = {
      'Authorization': 'Bearer $token', // Use the JWT token
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'latitude': latitude,
      'longitude': longitude,
    });

    // First, try to update the location
    final response = await http.patch(patch_url, headers: headers, body: body);

    if (response.statusCode == 200) {
      print('Location updated successfully!');
    } else if (response.statusCode == 404) {
      // If responder doesn't exist, create a new one
      final userBody = json.encode({
        'user': userId,  // Use the decoded user ID
        'latitude': latitude,
        'longitude': longitude,
      });

      final createResponse = await http.post(post_url, headers: headers, body: userBody);

      if (createResponse.statusCode == 201) {
        print('Responder profile created and location set!');
      } else {
        print('Failed to create responder profile. Error: ${createResponse.body}');
      }
    } else {
      print('Failed to update location. Error: ${response.body}');
    }
  }

  // Function to get current location
  Future<Position?> getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check location permission status
    PermissionStatus permission = await Permission.location.status;
    if (permission == PermissionStatus.denied) {
      permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
        return null;
      }
    }

    if (permission == PermissionStatus.permanentlyDenied) {
      // If permission is permanently denied, open app settings
      openAppSettings();
      return null;
    }

    // Fetch the current location
    Position position = await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );
    return position;
  }
}
