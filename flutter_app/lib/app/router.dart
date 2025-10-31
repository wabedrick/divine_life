import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_layout.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/users/users_screen.dart';
import '../screens/branches/branches_screen.dart';
import '../screens/mcs/mcs_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/announcements/announcements_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/sermons/sermons_screen.dart';
import '../screens/online/online_services_screen.dart';
import '../screens/giving/giving_screen.dart';

class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final location = state.uri.path;

        // If not initialized yet, stay on splash
        if (!authProvider.isAuthenticated &&
            location != '/splash' &&
            location != '/login' &&
            location != '/register') {
          if (location == '/') return '/splash';
        }

        // If authenticated and trying to access auth screens, redirect to dashboard
        if (authProvider.isAuthenticated &&
            (location == '/login' ||
                location == '/register' ||
                location == '/splash')) {
          return '/dashboard';
        }

        // If not authenticated and trying to access protected routes, redirect to login
        if (!authProvider.isAuthenticated && _isProtectedRoute(location)) {
          return '/login';
        }

        // Role-based route protection
        if (authProvider.isAuthenticated) {
          // Only MC Leaders, Branch Admins, and Super Admins can access reports
          if (location.startsWith('/reports') &&
              !authProvider.canCreateReports) {
            return '/dashboard';
          }
        }

        return null; // No redirect needed
      },
      routes: [
        // Splash Screen
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Authentication Routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Main App Routes with Shell
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            // Dashboard
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),

            // Users Management
            GoRoute(
              path: '/users',
              name: 'users',
              builder: (context, state) => const UsersScreen(),
            ),

            // Branches Management
            GoRoute(
              path: '/branches',
              name: 'branches',
              builder: (context, state) => const BranchesScreen(),
            ),

            // MCs Management
            GoRoute(
              path: '/mcs',
              name: 'mcs',
              builder: (context, state) => const MCsScreen(),
            ),

            // Reports
            GoRoute(
              path: '/reports',
              name: 'reports',
              builder: (context, state) => const ReportsScreen(),
            ),

            // Events
            GoRoute(
              path: '/events',
              name: 'events',
              builder: (context, state) => const EventsScreen(),
            ),

            // Announcements
            GoRoute(
              path: '/announcements',
              name: 'announcements',
              builder: (context, state) => const AnnouncementsScreen(),
            ),

            // Sermons
            GoRoute(
              path: '/sermons',
              name: 'sermons',
              builder: (context, state) => const SermonsScreen(),
            ),

            // Online Services
            GoRoute(
              path: '/online',
              name: 'online',
              builder: (context, state) => const OnlineServicesScreen(),
            ),

            // Giving
            GoRoute(
              path: '/giving',
              name: 'giving',
              builder: (context, state) => const GivingScreen(),
            ),

            // Profile
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),

            // Chat Routes
            GoRoute(
              path: '/chat',
              name: 'chat',
              builder: (context, state) => const ChatListScreen(),
              routes: [
                GoRoute(
                  path: '/:conversationId',
                  name: 'chat_conversation',
                  builder: (context, state) {
                    final conversationId = int.parse(
                      state.pathParameters['conversationId']!,
                    );
                    return ChatScreen(conversationId: conversationId);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Check if route requires authentication
  static bool _isProtectedRoute(String location) {
    const protectedRoutes = [
      '/dashboard',
      '/users',
      '/branches',
      '/mcs',
      '/reports',
      '/events',
      '/announcements',
      '/sermons',
      '/profile',
      '/chat',
    ];

    return protectedRoutes.any((route) => location.startsWith(route));
  }

  // Navigation helper methods
  static void goToDashboard(BuildContext context) {
    context.goNamed('dashboard');
  }

  static void goToLogin(BuildContext context) {
    context.goNamed('login');
  }

  static void goToRegister(BuildContext context) {
    context.goNamed('register');
  }

  static void goToUsers(BuildContext context) {
    context.goNamed('users');
  }

  static void goToBranches(BuildContext context) {
    context.goNamed('branches');
  }

  static void goToMCs(BuildContext context) {
    context.goNamed('mcs');
  }

  static void goToReports(BuildContext context) {
    context.goNamed('reports');
  }

  static void goToEvents(BuildContext context) {
    context.goNamed('events');
  }

  static void goToAnnouncements(BuildContext context) {
    context.goNamed('announcements');
  }

  static void goToProfile(BuildContext context) {
    context.goNamed('profile');
  }
}
