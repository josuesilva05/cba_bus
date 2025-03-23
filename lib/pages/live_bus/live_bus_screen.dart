import 'package:cba_bus/pages/live_bus/map_view.dart';
import 'package:flutter/material.dart';
import 'map_view.dart';
import 'bus_detail_screen.dart';
import '../../locator.dart';
import '../../services/live_bus_service.dart';

class LiveBusScreen extends StatefulWidget {
  @override
  _LiveBusScreenState createState() => _LiveBusScreenState();
}

class _LiveBusScreenState extends State<LiveBusScreen> {
  final LiveBusService _apiService = locator<LiveBusService>();
  late Future<List<Map<String, String>>> _busLinesFuture;
  List<Map<String, String>> _busLines = [];
  List<Map<String, String>> _filteredBusLines = [];
  TextEditingController _searchController = TextEditingController();
  Set<String> _selectedBusIds = {};
  bool _isMultiSelectActive = false; // Para controlar a seleção múltipla

  @override
  void initState() {
    super.initState();
    _busLinesFuture = _fetchBusLines();
    _searchController.addListener(_filterBusLines);
  }

  Future<List<Map<String, String>>> _fetchBusLines() async {
    try {
      List<Map<String, String>> lines = await _apiService.fetchBusLines();
      if (lines.isEmpty) throw Exception("Nenhuma linha encontrada");
      setState(() {
        _busLines = lines;
        _filteredBusLines = lines;
      });
      return lines;
    } catch (e) {
      return []; // Retorna uma lista vazia para evitar erro
    }
  }

  void _filterBusLines() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBusLines =
          _busLines
              .where(
                (bus) =>
                    (bus["numero"] ?? "").toLowerCase().contains(query) ||
                    (bus["descricao"] ?? "").toLowerCase().contains(query),
              )
              .toList();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedBusIds.contains(id)) {
        _selectedBusIds.remove(id);
      } else {
        _selectedBusIds.add(id);
      }
      // Ativa a seleção múltipla se pelo menos um item for selecionado
      _isMultiSelectActive = _selectedBusIds.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedBusIds.clear();
      _isMultiSelectActive = false; // Desativa a seleção múltipla
    });
  }

  void _consultSelectedLines() {
    if (_selectedBusIds.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Você pode selecionar no máximo 5 linhas.")),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MapView(selectedBusIds: _selectedBusIds.toList()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(9.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: "Busque uma linha...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Mostrador de linhas selecionadas
              if (_isMultiSelectActive) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 5.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8.0,
                          children:
                              _selectedBusIds.map((id) {
                                final bus = _busLines.firstWhere(
                                  (bus) => bus["id"] == id,
                                );
                                return Chip(
                                  label: Text(
                                    bus["numero"] ?? "N/A",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    37,
                                    129,
                                    204,
                                  ),
                                  onDeleted: () => _toggleSelection(id),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Expanded(
                child: FutureBuilder<List<Map<String, String>>>(
                  future: _busLinesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || snapshot.data == null) {
                      return Center(child: Text("Erro ao carregar as linhas"));
                    } else if (_filteredBusLines.isEmpty) {
                      return Center(child: Text("Nenhuma linha encontrada"));
                    }

                    return Scrollbar(
                      child: ListView.builder(
                        itemCount: _filteredBusLines.length,
                        itemBuilder: (context, index) {
                          final bus = _filteredBusLines[index];
                          final String numero = bus["numero"] ?? "N/A";
                          final String descricao =
                              bus["descricao"] ?? "Descrição não disponível";
                          final String? id = bus["id"];

                          final isSelected = _selectedBusIds.contains(id);

                          return GestureDetector(
                            onLongPress: () {
                              // Ativa a seleção múltipla ao pressionar e segurar
                              _toggleSelection(id!);
                            },
                            onTap:
                                _isMultiSelectActive
                                    ? () => _toggleSelection(id!)
                                    : () => _navigateToDetails(id, descricao),

                            child: Container(
                              margin: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.blueAccent.withOpacity(0.5)
                                        : (isDarkMode
                                            ? Color.fromRGBO(38, 52, 73, 1)
                                            : Colors.grey[300]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        78,
                                        175,
                                        255,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.directions_bus,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          numero,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      descricao,
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Botões de ação soltos na tela
          if (_isMultiSelectActive) ...[
            Positioned(
              bottom: 20, // Distância do fundo da tela
              right: 25, // Distância da borda direita
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    onPressed: _clearSelection,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.cancel),
                    tooltip: "Limpar Seleção",
                  ),
                  SizedBox(height: 16), // Espaçamento entre os botões
                  FloatingActionButton(
                    onPressed: _consultSelectedLines,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check),
                    tooltip: "Consultar Linhas",
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToDetails(String? id, String? nomeLinha) {
    if (id == null || nomeLinha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar detalhes da linha")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapView(selectedBusIds: [id]), // Passando apenas um ID
      ),
    );
  }
}
