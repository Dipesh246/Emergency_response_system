import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://192.168.1.78:8002/api";

  Future<bool> updateLocation(LatLng location, String userType) async {
    final url = Uri.parse("$baseUrl/update-location");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "latitude": location.latitude,
        "longitude": location.longitude,
        "user_type": userType,
      }),
    );

    return response.statusCode == 200;
  }
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Function to send emergency request
  Future<bool> sendEmergencyRequest({
    required double latitude,
    required double longitude,
    String? details,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      print('No access token found. Please log in.');
      return false;
    }

    final url = Uri.parse('$baseUrl/emergency-requests/');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      'details': details ?? '',
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 201) {
      print('Emergency request sent successfully!');
      return true;
    } else {
      print('Failed to send emergency request: ${response.body}');
      return false;
    }
  }
}
