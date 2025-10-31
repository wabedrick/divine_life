import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/auth_provider.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _allDestinations = [
    const NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(Icons.people_outlined),
      selectedIcon: Icon(Icons.people),
      label: 'Users',
    ),
    const NavigationDestination(
      icon: Icon(Icons.account_tree_outlined),
      selectedIcon: Icon(Icons.account_tree),
      label: 'Branch',
    ),
    const NavigationDestination(
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups),
      label: 'MCs',
    ),
    const NavigationDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event),
      label: 'Event',
    ),
    const NavigationDestination(
      icon: Icon(Icons.chat_outlined),
      selectedIcon: Icon(Icons.chat),
      label: 'Chat',
    ),
    const NavigationDestination(
      icon: Icon(Icons.play_circle_outlined),
      selectedIcon: Icon(Icons.play_circle),
      label: 'Sermons',
    ),
    const NavigationDestination(
      icon: Icon(Icons.cloud_outlined),
      selectedIcon: Icon(Icons.cloud),
      label: 'Online',
    ),
    const NavigationDestination(
      icon: Icon(Icons.volunteer_activism_outlined),
      selectedIcon: Icon(Icons.volunteer_activism),
      label: 'Give',
    ),
    const NavigationDestination(
      icon: Icon(Icons.announcement_outlined),
      selectedIcon: Icon(Icons.announcement),
      label: 'News',
    ),
  ];

  final List<String> _routeNames = [
    'dashboard',
    'users',
    'branches',
    'mcs',
    'reports',
    'events',
    'chat',
    'sermons',
    'online',
    'giving',
    'announcements',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).uri.path;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navConfig = _getNavigationConfig(authProvider);
    final visibleRoutes = navConfig.map((e) => e['route'] as String).toList();
    for (int i = 0; i < visibleRoutes.length; i++) {
      if (location.contains(visibleRoutes[i])) {
        setState(() {
          _selectedIndex = i;
        });
        break;
      }
    }
  }

  List<Map<String, dynamic>> _getNavigationConfig(AuthProvider authProvider) {
    final config = <Map<String, dynamic>>[];
    // Dashboard - always visible
    config.add({'destination': _allDestinations[0], 'route': _routeNames[0]});
    // Chat - only if allowed
    final showChat =
        authProvider.isMember ||
        authProvider.canManageUsers ||
        authProvider.canManageBranches ||
        authProvider.canManageMCs;
    if (showChat) {
      // _allDestinations[5] is Chat; _routeNames[6] is 'chat'
      config.add({'destination': _allDestinations[5], 'route': _routeNames[6]});
    }
    // Sermons (_allDestinations[6]) -> routeNames[7]
    config.add({'destination': _allDestinations[6], 'route': _routeNames[7]});
    // Online (_allDestinations[7]) -> routeNames[8]
    config.add({'destination': _allDestinations[7], 'route': _routeNames[8]});
    // Giving (_allDestinations[8]) -> routeNames[9]
    config.add({'destination': _allDestinations[8], 'route': _routeNames[9]});
    // News/Announcements (_allDestinations[9]) -> routeNames[10]
    config.add({'destination': _allDestinations[9], 'route': _routeNames[10]});
    return config;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final navConfig = _getNavigationConfig(authProvider);
        final visibleDestinations = navConfig
            .map((e) => e['destination'] as NavigationDestination)
            .toList();
        final visibleRoutes = navConfig
            .map((e) => e['route'] as String)
            .toList();

        // Ensure selected index is within bounds
        if (_selectedIndex >= visibleDestinations.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          body: widget.child,
          bottomNavigationBar: visibleDestinations.length > 1
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    if (index < visibleRoutes.length) {
                      context.goNamed(visibleRoutes[index]);
                      setState(() {
                        _selectedIndex = index;
                      });
                    }
                  },
                  destinations: visibleDestinations,
                )
              : null,
        );
      },
    );
  }
}
