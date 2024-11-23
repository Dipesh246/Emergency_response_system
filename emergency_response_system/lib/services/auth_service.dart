import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://192.168.1.78:8002/api';

  Future<Map<String, dynamic>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String confirmPassword,
    required String email,
    required String phoneNumber,
    required String address,
    required String userType,
    String? licenseNumber,
    String? vehicleNumber,
  }) async {
    final body = {
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'password': password,
      'confirm_password': confirmPassword,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'user_type': userType,
    };

    // Include responder-specific fields if the user is a responder
    if (userType == 'RESPONDER') {
      body['license_number'] = licenseNumber!;
      body['vehicle_number'] = vehicleNumber!;
    }
    final url = Uri.parse('$baseUrl/user/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
    // Registration successful, return the user data or success response
      final responseData = jsonDecode(response.body);
      return {
        'status': 'success',
        'user': responseData['user'],
        'access_token': responseData['access'],
        'refresh_token': responseData['refresh'],
      };
    } else {
    // Handle the error from the backend
      String errorMessage = 'An unknown error occurred';
      try {
        final errorResponse = json.decode(response.body);
        if (errorResponse is Map && errorResponse.containsKey('error')) {
          errorMessage = errorResponse['error']; // Extract the error message from the backend
        } else {
          errorMessage = 'Registration failed with status: ${response.statusCode}';
        }
      } catch (e) {
        // In case the error response is not a valid JSON
        errorMessage = 'Registration failed';
      }

      // Throw the exception with the error message
      throw Exception('Registration failed: $errorMessage');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/user/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
      await prefs.setInt('user_id', data['user']['id']);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}
