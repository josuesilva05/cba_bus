import 'package:flutter/material.dart';

class ItnerariosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 50),
          SizedBox(height: 20),
          Text('Itnerários', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}
