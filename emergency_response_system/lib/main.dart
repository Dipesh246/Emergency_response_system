import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Response System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState()=> _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'OpenStreetMap Example',
          style: TextStyle(fontSize: 22),
        ),
      ),
      body: content()
    );
  }
  Widget content(){
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(29.0773039,80.2707315),
        initialZoom: 11,
        interactionOptions: 
          const InteractionOptions(flags: ~InteractiveFlag.doubleTapZoom),
      ),
      children: [
        openStreetMapTileLater,
        PolylineLayer(
          polylines: [
            Polyline(
              points: [
                LatLng(28.9979789, 80.1482283), // Starting point
                LatLng(29.0773039, 80.2707315), // Destination
              ],
              strokeWidth: 4.0,
              color: Colors.blue,
            ),
          ],
        ),

        MarkerLayer(markers: [
          Marker(
            point: LatLng(28.9979789,80.1482283),
            width: 60,
            height: 60,
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.location_pin,
              size: 60,
              color: Colors.red,
            )
          )
        ])
      ],
    );
  }
}

TileLayer get openStreetMapTileLater => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);