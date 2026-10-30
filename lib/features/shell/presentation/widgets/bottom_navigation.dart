import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;

  final ValueChanged<int> onChanged;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,

      onDestinationSelected: onChanged,

      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,

      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.public_outlined),
          selectedIcon: Icon(Icons.public),
          label: '',
        ),

        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '',
        ),

        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: '',
        ),

        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '',
        ),
      ],
    );
  }
}
