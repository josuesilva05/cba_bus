import 'package:flutter/material.dart';

class BusDetailScreen extends StatelessWidget {
  final String busId;
  final String nomeLinha;

  BusDetailScreen({required this.busId, required this.nomeLinha});

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text("Detalhes da Linha")),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bus, size: 50, color: Colors.blue),

              SizedBox(height: 16),
              Text(
                "ID: $busId",
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
