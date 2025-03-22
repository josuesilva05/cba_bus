import 'package:cba_bus/pages/pontos/map_view.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PontosScreen extends StatelessWidget {
  final Set<Marker> _markers = {};

  void _onMapCreated(GoogleMapController controller) {
    // Aqui você pode adicionar os marcadores ou outras configurações do mapa
    _markers.add(
      Marker(
        markerId: MarkerId('1'),
        position: LatLng(-23.5505, -46.6333), // Exemplo: São Paulo
        infoWindow: InfoWindow(title: 'São Paulo', snippet: 'Capital de SP'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mapa de Pontos')),
      body: MapView(),
    );
  }
}
