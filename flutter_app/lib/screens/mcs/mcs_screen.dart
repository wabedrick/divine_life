import 'package:flutter/material.dart';
import 'mc_management_screen.dart';

// Legacy alias for compatibility with router
class MCsScreen extends StatelessWidget {
  const MCsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MCManagementScreen();
  }
}
