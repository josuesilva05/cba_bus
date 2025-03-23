import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Para geolocalização

class PontosScreen extends StatefulWidget {
  const PontosScreen({Key? key}) : super(key: key);

  @override
  State<PontosScreen> createState() => _PontosScreenState();
}

class _PontosScreenState extends State<PontosScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  final List<LatLng> _routePoints = [
    const LatLng(-15.627, -56.060),
    const LatLng(-15.625, -56.062),
    const LatLng(-15.623, -56.058),
  ];

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_currentPosition!, 15);
  }

  void _showPointInfo(String title, String description) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(description),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pontos de Ônibus'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
        backgroundColor: Colors.blue[800],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(-15.6274065, -56.0598531),
          initialZoom: 14.0, // Rotação inicial do mapa
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.cba_bus',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: Colors.blue.withOpacity(0.7),
                strokeWidth: 4,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 50,
                height: 50,
                point: const LatLng(-15.6274065, -56.0598531),
                child: GestureDetector(
                  onTap:
                      () => _showPointInfo(
                        'Terminal Central',
                        'Principal terminal de integração',
                      ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                textStyle: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
