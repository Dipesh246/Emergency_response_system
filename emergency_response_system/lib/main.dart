import 'package:flutter/material.dart';
import 'screens/app_initializer.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/map_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key,});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Response System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<bool>(
        future: AppInitializer.isLoggedIn(),
        builder: (context, snapshot) {
          // Show loading indicator while waiting for future
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show LoginScreen if not logged in, else MainScreen
          if (snapshot.hasData && snapshot.data == true) {
            return MainScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/map': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, double>;
          return MapScreen(latitude: args['latitude']!, longitude: args['longitude']!);
        },
        '/main': (context) => MainScreen(),
      },
    );
  }
}
