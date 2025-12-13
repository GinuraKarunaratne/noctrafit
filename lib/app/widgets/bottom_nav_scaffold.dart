import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';

/// Bottom navigation scaffold for 5 main tabs
/// Wraps the stateful shell navigation
class BottomNavScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content (tab screens)
          navigationShell,

          // TODO: Add ActiveSessionMiniBar (CW5) here when implemented
          // Positioned(
          //   top: 0,
          //   left: 0,
          //   right: 0,
          //   child: const ActiveSessionMiniBar(),
          // ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: Icon(TablerIcons.home),
            selectedIcon: Icon(TablerIcons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(TablerIcons.barbell),
            selectedIcon: Icon(TablerIcons.barbell),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(TablerIcons.calendar),
            selectedIcon: Icon(TablerIcons.calendar),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(TablerIcons.chart_bar),
            selectedIcon: Icon(TablerIcons.chart_bar),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(TablerIcons.user),
            selectedIcon: Icon(TablerIcons.user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
