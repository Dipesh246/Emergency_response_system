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
    print("inside send emergency request.");
    final url = Uri.parse('$baseUrl/emergency-request');
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

  // Function to fetch the list of emergency requests
  Future<List<dynamic>?> fetchEmergencyRequests() async {
    final token = await getAccessToken();
    if (token == null) {
      print('No access token found. Please log in.');
      return null;
    }

    final url = Uri.parse('$baseUrl/emergency-request');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      print('Emergency requests fetched successfully!');
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch emergency requests: ${response.body}');
      return null;
    }
  }

  // Function to assign an emergency request
  Future<bool> assignEmergencyRequest(int requestId) async {
    final token = await getAccessToken();
    if (token == null) {
      print('No access token found. Please log in.');
      return false;
    }

    final url = Uri.parse('$baseUrl/emergency-request/$requestId/assign');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final response = await http.patch(url, headers: headers);
    
    if (response.statusCode == 200) {
      print('Emergency request assigned successfully!');
      return true;
    } else {
      print('Failed to assign emergency request: ${response.body}');
      return false;
    }
  }
  // Fetch nearby responders
  Future<List<dynamic>> fetchResponders() async {
    print("Fetching responders...");
    final token = await getAccessToken();

    if (token == null) {
      print('No access token found.');
      return [];
    }

    final url = Uri.parse('$baseUrl/responders');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final response = await http.get(url, headers: headers);
    print(response);
    if (response.statusCode == 200) {
      List<dynamic> respondersData = json.decode(response.body);
      return respondersData.map((data) => Map<String, dynamic>.from(data)).toList();
    } else {
      print('Failed to fetch nearby responders: ${response.statusCode}');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getNearestResponderPath(double latitude, double longitude) async {
    final url = Uri.parse('$baseUrl/emergency-request/nearest-responder-path?latitude=$latitude&longitude=$longitude');
    final response = await http.get(url);
    print(response.statusCode);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      return Map<String, dynamic>.from(data); // Return the nearest responder's path and details
    } else {
      print('Failed to fetch nearest responder path: ${response.body}');
      return null; // Return null in case of failure
    }
  }
}
