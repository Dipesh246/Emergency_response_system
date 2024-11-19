import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppInitializer {
  static Future<bool> isLoggedIn() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}
