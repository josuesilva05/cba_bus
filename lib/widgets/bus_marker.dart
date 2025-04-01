import 'package:flutter/material.dart';
import 'dart:math' as math;

class BusMarker extends StatelessWidget {
  final int status;
  final double rotation;
  final String speed;

  const BusMarker({
    Key? key,
    required this.status,
    required this.rotation,
    required this.speed,
  }) : super(key: key);

  Color _getColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final baseColor = switch (status) {
      3 => Colors.green,
      1 => Colors.orange,
      _ => Colors.blue,
    };

    return brightness == Brightness.dark
        ? baseColor.withOpacity(0.8)
        : baseColor;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Transform.rotate(
            angle: (rotation * math.pi) / 180,
            child: Icon(
              Icons.location_on,
              size: 32, // Reduzido para melhor precisão
              color: _getColor(context),
            ),
          ),
        ),
        if (speed != '0')
          Positioned(
            right: -20, // Ajustado para ficar mais próximo ao marcador
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$speed km/h',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color:
                      Colors.white, // Texto sempre branco para melhor contraste
                ),
              ),
            ),
          ),
      ],
    );
  }
}
