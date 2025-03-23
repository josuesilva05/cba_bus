import 'dart:convert';
import 'package:cba_bus/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class MapView extends StatefulWidget {
  final List<String> selectedBusIds;

  const MapView({super.key, required this.selectedBusIds});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Map<String, Marker> _markers = {};
  late io.Socket _socket;
  final LatLng _initialPosition = const LatLng(-15.6274065, -56.0598531);

  @override
  void initState() {
    super.initState();
    if (widget.selectedBusIds.isEmpty) {
      Future.microtask(() {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Nenhum ID selecionado")));
      });
      return;
    }
    _initSocket();
  }

  void _initSocket() {
    final String busIds = widget.selectedBusIds.join(',');

    print('🔌 Conectando ao WebSocket...');
    print('📡 Enviando IDs: $busIds');

    _socket = io.io('http://144.22.240.151:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {'ids': busIds},
    });

    _socket.onConnect((_) {
      print('✅ Conectado ao WebSocket!');
      print('📤 Enviando evento "bus_lines" com IDs: $busIds');
      _socket.emit("bus_lines", busIds);
      _socket.on('data', _handleSocketData);
    });

    _socket.onError((error) {
      print('❌ Erro no socket: $error');
    });

    _socket.onDisconnect((_) {
      print('🔌 Desconectado do WebSocket');
    });
  }

  void _handleSocketData(dynamic data) {
    if (data is List && data.length == 2) {
      final eventType = data[0];
      final eventData = data[1];

      print('🆕 Evento recebido: $eventType');

      switch (eventType) {
        case 'sync':
          print('🔄 Sincronização de dados recebida!');
          if (eventData is Map && eventData.containsKey('data')) {
            _handleSyncEvent(eventData['data']);
          } else {
            print('⚠️ Estrutura inválida para sync: $eventData');
          }
          break;
        case 'update':
        case 'insert':
          print('📌 Atualizando marcador para veículo: ${eventData['id']}');
          final correctedVehicle = Map<String, dynamic>.from(eventData);
          _handleVehicleUpdate(correctedVehicle);
          break;
        default:
          print('⚠️ Tipo de evento desconhecido: $eventType');
      }
    } else {
      print('⚠️ Dados inválidos recebidos do WebSocket!');
    }
  }

  void _handleSyncEvent(List<dynamic> vehicles) {
    print('🚍 Sincronizando ${vehicles.length} veículos');

    final newMarkers = <String, Marker>{};

    for (final vehicle in vehicles) {
      if (vehicle is! Map ||
          !vehicle.containsKey('id') ||
          !vehicle.containsKey('gps')) {
        print('⚠️ Veículo ignorado por falta de dados: $vehicle');
        continue;
      }

      final id = vehicle['id'] as String;
      final coords = vehicle['gps']['coordinates'] as List<dynamic>;

      if (coords.length < 2) {
        print('⚠️ Coordenadas inválidas para veículo $id: $coords');
        continue;
      }

      print('📍 Criando marcador para $id em (${coords[1]}, ${coords[0]})');

      newMarkers[id] = _createMarker(
        LatLng(coords[1].toDouble(), coords[0].toDouble()),
        vehicle as Map<String, dynamic>,
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
    });

    print('✅ Markers atualizados!');
  }

  void _handleVehicleUpdate(Map<String, dynamic> vehicle) {
    if (!vehicle.containsKey('id') || !vehicle.containsKey('gps')) {
      print('⚠️ Atualização ignorada: Dados incompletos $vehicle');
      return;
    }

    final id = vehicle['id'] as String;
    final coords = vehicle['gps']['coordinates'] as List<dynamic>;

    if (coords.length < 2) {
      print(
        '⚠️ Coordenadas inválidas para atualização do veículo $id: $coords',
      );
      return;
    }

    print('📍 Atualizando marcador para $id em (${coords[1]}, ${coords[0]})');

    setState(() {
      _markers[id] = _createMarker(
        LatLng(coords[1].toDouble(), coords[0].toDouble()),
        vehicle as Map<String, dynamic>,
      );
    });
  }

  Marker _createMarker(LatLng position, Map<String, dynamic> vehicle) {
    return Marker(
      point: position,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showVehicleInfo(vehicle),
        child: Icon(
          Icons.location_on, // Ícone de alfinete
          color: _getVehicleColor(vehicle),
          size: 40, // Ajuste o tamanho conforme necessário
        ),
      ),
    );
  }

  Color _getVehicleColor(Map<String, dynamic> vehicle) {
    final status = vehicle['sinotico']?['estadoViagem'] ?? 0;
    return switch (status) {
      3 => Colors.green, // Em movimento
      1 => Colors.orange, // Parado
      _ => Colors.blue, // Default
    };
  }

  void _showVehicleInfo(Map<String, dynamic> vehicle) {
    final context = navigatorKey.currentContext!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(vehicle['prefixoVeiculo']),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Linha: ${vehicle['sinotico']?['numeroLinha'] ?? 'N/A'}'),
                Text('Velocidade: ${vehicle['velocidadeAtual']} km/h'),
                Text('Última atualização: ${vehicle['dataTransmissaoS']}'),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    try {
      if (_socket != null) {
        _socket.disconnect(); // Desconecta o socket
        _socket.dispose(); // Libera recursos do socket
      }
    } catch (e) {
      print('Erro ao desconectar o socket: $e');
    }
    super.dispose(); // Chama o dispose da superclasse
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mapa")),
      body: FlutterMap(
        options: MapOptions(initialCenter: _initialPosition, initialZoom: 14.0),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(markers: _markers.values.toList()),
          RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
        ],
      ),
    );
  }
}
