// Test file to debug EditUserDialog issues
import 'package:flutter/material.dart';

void main() {
  runApp(const TestEditUserDialog());
}

class TestEditUserDialog extends StatelessWidget {
  const TestEditUserDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Edit User Dialog',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Edit User Dialog')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _testEditUserDialog(context),
          child: const Text('Test Edit User Dialog'),
        ),
      ),
    );
  }

  void _testEditUserDialog(BuildContext context) {
    // Test data that mimics what comes from the API
    final testUser = {
      'id': 1,
      'name': 'Test User',
      'first_name': 'Test',
      'last_name': 'User',
      'email': 'test@example.com',
      'phone_number': '+1234567890',
      'role': 'member',
      'gender': 'male',
      'birth_date': '1990-01-01',
      'branch_id': 1,
      'mc_id': null,
      'created_at': '2024-01-01T00:00:00.000000Z',
      'updated_at': '2024-01-01T00:00:00.000000Z',
    };

    // print('Testing EditUserDialog with user data: $testUser');

    try {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Test Dialog',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                Text('User ID: ${testUser['id']}'),
                Text('Name: ${testUser['name']}'),
                Text('Email: ${testUser['email']}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // print('ERROR creating test dialog: $e');
      // print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
