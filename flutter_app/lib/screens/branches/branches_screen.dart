import 'package:flutter/material.dart';
import 'branch_management_screen.dart';

// Legacy alias for compatibility with router
class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BranchManagementScreen();
  }
}
