import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatefulWidget {
  final LatLng initialPosition;

  MapWidget({required this.initialPosition});

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late GoogleMapController mapController;
  late CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    _initialCameraPosition = CameraPosition(
      target: widget.initialPosition,
      zoom: 11.0,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: _initialCameraPosition,
      markers: {
        Marker(
          markerId: MarkerId('initial_position'),
          position: widget.initialPosition,
          infoWindow: InfoWindow(
            title: 'Local Inicial',
            snippet: 'Esta é a posição inicial do mapa.',
          ),
        ),
      },
    );
  }
}
