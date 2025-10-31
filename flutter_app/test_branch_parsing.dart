import 'dart:convert';
import 'lib/core/models/branch_model.dart';

void main() {
  // Test parsing the branch data from the API
  final testResponse = '''
  {
    "branches": [
      {
        "id": 3,
        "name": "Divine Life - Luwafu",
        "location": "Luwafu, Salama road",
        "description": "ghujh",
        "address": null,
        "phone_number": null,
        "email": null,
        "admin_id": 3,
        "is_active": true,
        "created_at": "2025-10-28T21:55:34.000000Z",
        "updated_at": "2025-10-28T22:02:48.000000Z"
      }
    ]
  }
  ''';

  try {
    final data = jsonDecode(testResponse);
    final branchesData = data['branches'] as List;

    for (var json in branchesData) {
      // print('Parsing: $json');
      BranchModel.fromJson(json);
      // print('Success: ${branch.name}');
    }
  } catch (e) {
    // print('Error: $e');
    // print('Stack: $stackTrace');
  }
}
