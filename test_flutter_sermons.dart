import 'dart:convert';
import 'dart:io';

// Simple test to check what the Flutter SermonService is receiving
void main() async {
  // Simulate the API call
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) => true;

  try {
    print('🔍 Testing Flutter API connection...');

    // Test login first
    final loginRequest = await client.postUrl(
      Uri.parse('http://192.168.42.54:8000/api/auth/login'),
    );
    loginRequest.headers.set('Content-Type', 'application/json');
    loginRequest.write(
      jsonEncode({'email': 'admin@test.com', 'password': 'password'}),
    );

    final loginResponse = await loginRequest.close();
    final loginBody = await utf8.decodeStream(loginResponse);
    final loginData = jsonDecode(loginBody);

    if (loginData['access_token'] != null) {
      print('✅ Login successful');
      final token = loginData['access_token'];

      // Now test sermons endpoint
      final sermonsRequest = await client.getUrl(
        Uri.parse('http://192.168.42.54:8000/api/sermons'),
      );
      sermonsRequest.headers.set('Authorization', 'Bearer $token');
      sermonsRequest.headers.set('Accept', 'application/json');

      final sermonsResponse = await sermonsRequest.close();
      final sermonsBody = await utf8.decodeStream(sermonsResponse);

      print('📋 Raw Sermons Response:');
      print(sermonsBody);

      final sermonsData = jsonDecode(sermonsBody);
      print('\n📊 Parsed Data Structure:');
      print('Response Keys: ${sermonsData.keys.toList()}');

      if (sermonsData.containsKey('data')) {
        final sermons = sermonsData['data'];
        print('Sermons Count: ${sermons.length}');
        if (sermons.isNotEmpty) {
          print('First Sermon: ${sermons[0]}');
        }
      }

      if (sermonsData.containsKey('sermons')) {
        final sermons = sermonsData['sermons'];
        print('Sermons Count: ${sermons.length}');
        if (sermons.isNotEmpty) {
          print('First Sermon: ${sermons[0]}');
        }
      }
    } else {
      print('❌ Login failed: $loginBody');
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.close();
  }
}
