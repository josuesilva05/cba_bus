import 'dart:convert';
import 'package:cba_bus/main.dart';
import 'package:cba_bus/widgets/bus_marker.dart';
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
        LatLng(coords[1].toDouble(), coords[0].toDouble()), // Correção aqui
        vehicle as Map<String, dynamic>,
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
    });
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
        LatLng(coords[1].toDouble(), coords[0].toDouble()), // Já estava correto
        vehicle as Map<String, dynamic>,
      );
    });
  }

  Marker _createMarker(LatLng position, Map<String, dynamic> vehicle) {
    return Marker(
      point: position,
      width: 60, // Reduzido para melhor precisão
      height: 40,
      child: GestureDetector(
        onTap: () => _showVehicleInfo(vehicle),
        child: BusMarker(
          status: vehicle['sinotico']?['estadoViagem'] ?? 0,
          rotation: vehicle['direcao']?.toDouble() ?? 0,
          speed: vehicle['velocidadeAtual']?.toString() ?? '0',
        ),
      ),
    );
  }

  Color _getVehicleColor(Map<String, dynamic> vehicle) {
    final status = vehicle['sinotico']?['estadoViagem'] ?? 0;
    switch (status) {
      case 1: // Em movimento
        return Colors.green;
      case 2: // Parado
        return Colors.orange;
      default: // Status desconhecido
        return Colors.blue;
    }
  }

  void _showVehicleInfo(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getVehicleColor(vehicle).withOpacity(0.2),
                    child: Icon(
                      Icons.directions_bus,
                      color: _getVehicleColor(vehicle),
                      size: 35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ônibus ${vehicle['prefixoVeiculo']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.route,
                    'Linha',
                    '${vehicle['sinotico']?['numeroLinha'] ?? 'N/A'}',
                  ),
                  _infoRow(
                    Icons.speed,
                    'Velocidade',
                    '${vehicle['velocidadeAtual']} km/h',
                  ),
                  _infoRow(
                    Icons.access_time,
                    'Última atualização',
                    vehicle['dataTransmissaoS'],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Mapa como fundo
          FlutterMap(
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 14.0,
              minZoom: 12.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    isDark
                        ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(markers: _markers.values.toList()),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // Dashboard overlay
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.grey[900]!.withOpacity(0.9)
                            : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monitoramento em Tempo Real',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ônibus ativos: ${_markers.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom panel
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.grey[900]!.withOpacity(0.9)
                            : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statusIndicator(
                            Colors.green,
                            "Em movimento",
                            "${_countBusesByStatus(3)}",
                          ),
                          _statusIndicator(
                            Colors.orange,
                            "Parado",
                            "${_countBusesByStatus(1)}",
                          ),
                          _statusIndicator(
                            Colors.blue,
                            "Desconhecido",
                            "${_countBusesByStatus(0)}",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _mapButton(Icons.add),
                const SizedBox(height: 8),
                _mapButton(Icons.remove),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: () {
          // Implementar zoom
        },
      ),
    );
  }

  Widget _statusIndicator(Color color, String label, String count) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                count,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  int _countBusesByStatus(int status) {
    return _markers.values.where((marker) {
      final vehicle = (marker.child as GestureDetector).child as BusMarker;
      return vehicle.status == status;
    }).length;
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
}
