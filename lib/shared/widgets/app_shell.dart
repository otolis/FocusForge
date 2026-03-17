import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/extensions.dart';

/// The app shell wrapping authenticated routes with a persistent bottom
/// navigation bar.
///
/// Used as the `builder` of a [ShellRoute] in the GoRouter configuration.
/// The [child] parameter is the currently active route's widget.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  /// The widget for the currently active tab route.
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Maps route paths to navigation bar indices.
  static const _routes = ['/tasks', '/habits', '/planner', '/profile'];

  /// Determines the selected index from the current GoRouter location.
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _routes.indexWhere((r) => location.startsWith(r));
    return index >= 0 ? index : 0;
  }

  void _onDestinationSelected(int index) {
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: context.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          elevation: 0,
          selectedIndex: _currentIndex(context),
          onDestinationSelected: _onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline_rounded),
              selectedIcon: Icon(Icons.check_circle_rounded),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_fire_department_rounded),
              selectedIcon: Icon(Icons.local_fire_department),
              label: 'Habits',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_rounded),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Planner',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
