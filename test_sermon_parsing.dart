import 'dart:convert';
import 'dart:io';

// Simple Dart script to test the sermon loading logic like Flutter would do
class MockSermon {
  final int id;
  final String title;
  final String youtubeUrl;
  final String? speaker;
  final bool isFeatured;
  final bool isActive;

  MockSermon({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    this.speaker,
    required this.isFeatured,
    required this.isActive,
  });

  factory MockSermon.fromJson(Map<String, dynamic> json) {
    return MockSermon(
      id: json['id'] as int,
      title: json['title'] as String,
      youtubeUrl: json['youtube_url'] as String,
      speaker: json['speaker'] as String?,
      isFeatured: _parseBool(json['is_featured']) ?? false,
      isActive: _parseBool(json['is_active']) ?? true,
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }

  @override
  String toString() {
    return 'Sermon(id: $id, title: "$title", speaker: "$speaker", youtubeUrl: "$youtubeUrl", isFeatured: $isFeatured, isActive: $isActive)';
  }
}

void main() async {
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) => true;

  try {
    print('🔐 Testing Flutter-style sermon loading...');

    // Login first
    final loginRequest = await client.postUrl(
      Uri.parse('http://192.168.42.54:8000/api/auth/login'),
    );
    loginRequest.headers.set('Content-Type', 'application/json');
    loginRequest.write(
      jsonEncode({
        'email': 'admin@divinelifechurch.org',
        'password': 'password123',
      }),
    );

    final loginResponse = await loginRequest.close();
    final loginBody = await utf8.decodeStream(loginResponse);
    final loginData = jsonDecode(loginBody);

    if (loginData['access_token'] == null) {
      print('❌ Login failed: $loginBody');
      return;
    }

    final token = loginData['access_token'];
    print('✅ Login successful');

    // Test sermon loading exactly like Flutter app does
    final sermonsRequest = await client.getUrl(
      Uri.parse('http://192.168.42.54:8000/api/sermons?page=1&per_page=10'),
    );
    sermonsRequest.headers.set('Authorization', 'Bearer $token');
    sermonsRequest.headers.set('Accept', 'application/json');

    final sermonsResponse = await sermonsRequest.close();
    final sermonsBody = await utf8.decodeStream(sermonsResponse);
    final sermonsData = jsonDecode(sermonsBody);

    print('\n📊 Processing sermon data like Flutter app...');

    if (sermonsData is Map && sermonsData.containsKey('data')) {
      final sermonsList = sermonsData['data'] as List;
      print('✅ Found ${sermonsList.length} sermons in API response');

      // Try to parse each sermon like Flutter would
      final List<MockSermon> parsedSermons = [];

      for (int i = 0; i < sermonsList.length; i++) {
        try {
          final sermonJson = sermonsList[i] as Map<String, dynamic>;
          print('\n🔍 Parsing sermon $i: ${sermonJson['title']}');

          final sermon = MockSermon.fromJson(sermonJson);
          parsedSermons.add(sermon);
          print('✅ Successfully parsed: $sermon');
        } catch (e) {
          print('❌ Error parsing sermon $i: $e');
          print('   Raw data: ${sermonsList[i]}');
        }
      }

      print('\n📈 FINAL RESULTS:');
      print('================');
      print('API returned: ${sermonsList.length} sermons');
      print('Successfully parsed: ${parsedSermons.length} sermons');

      if (parsedSermons.isNotEmpty) {
        print('\n📋 Parsed Sermons:');
        for (final sermon in parsedSermons) {
          print(
            '  • ${sermon.title} by ${sermon.speaker ?? "Unknown"} - ${sermon.youtubeUrl}',
          );
        }
      } else {
        print('❌ NO SERMONS WERE SUCCESSFULLY PARSED!');
      }
    } else {
      print('❌ API response does not contain expected "data" field');
      print('Response: $sermonsBody');
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.close();
  }
}
