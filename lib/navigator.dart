import 'package:flutter/material.dart';

class CustomNavigator extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavigator({
    required this.selectedIndex,
    required this.onItemTapped,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 65,
      backgroundColor: Color.fromRGBO(30, 41, 59, 1),
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemTapped,
      indicatorColor: const Color.fromARGB(
        255,
        73,
        82,
        95,
      ), // Cor do indicador (opcional)
      destinations: const <Widget>[
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.directions_bus),
          icon: Icon(Icons.directions_bus_outlined),
          label: 'Live bus',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.flag),
          icon: Icon(Icons.flag_outlined),
          label: 'Pontos',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.departure_board),
          icon: Icon(Icons.departure_board_outlined),
          label: 'Itinerários',
        ),
      ],
    );
  }
}
