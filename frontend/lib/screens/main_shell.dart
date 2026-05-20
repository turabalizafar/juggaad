import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'booking_history_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingHistoryScreen(),
    const Scaffold(body: Center(child: Text('Profile WIP'))),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.outline,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
