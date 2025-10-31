// Test script to verify mock data is working
import 'package:divine_life_church/core/services/api_service.dart';

void main() async {
  // Initialize API service
  ApiService.init();

  // print('Testing Mock API Service...');

  try {
    // Test connection
    await ApiService.testConnection();
    // print('✅ Connection test: ${connectionTest['message']}');

    // Test login
    await ApiService.login('admin@test.com', 'password');
    // print(
    //   '✅ Login test: ${loginTest['access_token'] != null ? 'Success' : 'Failed'}',
    // );

    // Test statistics
    await ApiService.getUserStatistics();
    // print('✅ User statistics: ${userStats['data']['total_users']} total users');

    await ApiService.getReportStatistics();
    // print(
    //   '✅ Report statistics: ${reportStats['data']['total_reports']} total reports',
    // );

    // Test other endpoints
    await ApiService.getBranches();
    // print('✅ Branches: ${branches['data'].length} branches found');

    await ApiService.getMCs();
    // print('✅ MCs: ${mcs['data'].length} MCs found');

    await ApiService.getEvents();
    // print('✅ Events: ${events['data'].length} events found');

    // print('\n🎉 All mock data tests passed!');
  } catch (e) {
    // print('❌ Test failed: $e');
  }
}
