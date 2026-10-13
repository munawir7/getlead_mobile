import 'package:flutter/material.dart';

import '../leads/lead_list_screen.dart';
import '../deals/deal_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const Color backgroundColor = Color(0xFFFAF8F4);
  static const Color redColor = Color(0xFFE52529);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      const LeadListScreen(),
      const DealListScreen(),
      const TasksScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: redColor.withValues(alpha: 0.12),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Leads',
          ),

          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: 'Deals',
          ),

          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TASKS SCREEN
// ============================================================

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  static const Color backgroundColor = Color(0xFFFAF8F4);
  static const Color darkText = Color(0xFF181818);
  static const Color secondaryText = Color(0xFF77736E);
  static const Color redColor = Color(0xFFE52529);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Tasks',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_outlined,
              size: 70,
              color: redColor,
            ),

            SizedBox(height: 16),

            Text(
              'Tasks',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Your tasks will appear here.',
              style: TextStyle(
                color: secondaryText,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}