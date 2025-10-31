import 'dart:io';
import 'dart:convert';

void main() async {
  // print('Testing connection to 192.168.42.54:8000...');

  try {
    final client = HttpClient();
    client.connectionTimeout = Duration(seconds: 30);

    final uri = Uri.parse('http://192.168.42.54:8000/api/test');
    final request = await client.getUrl(uri);
    request.headers.add('Accept', 'application/json');

    final response = await request.close();
    await response.transform(utf8.decoder).join();

    // print('Status: ${response.statusCode}');
    // print('Response: $responseBody');

    client.close();

    if (response.statusCode == 200) {
      // print('✅ Connection successful!');
    } else {
      // print('❌ Connection failed with status ${response.statusCode}');
    }
  } catch (e) {
    // print('❌ Connection error: $e');
  }
}
