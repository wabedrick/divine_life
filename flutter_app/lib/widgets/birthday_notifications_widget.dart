import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class BirthdayNotificationsWidget extends StatefulWidget {
  const BirthdayNotificationsWidget({super.key});

  @override
  State<BirthdayNotificationsWidget> createState() =>
      _BirthdayNotificationsWidgetState();
}

class _BirthdayNotificationsWidgetState
    extends State<BirthdayNotificationsWidget> {
  List<Map<String, dynamic>> _todaysBirthdays = [];
  List<Map<String, dynamic>> _upcomingBirthdays = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _todaysCardDismissed = false;
  bool _upcomingCardDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadBirthdayData();
  }

  Future<void> _loadBirthdayData() async {
    final authProvider = context.read<AuthProvider>();

    // Only load for MC Leaders, Branch Admins, and Super Admins
    if (!authProvider.isMCLeader &&
        !authProvider.isBranchAdmin &&
        !authProvider.isSuperAdmin) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load today's birthdays
      final todayResponse = await ApiService.get('/birthdays/notifications');
      if (todayResponse['success'] == true) {
        _todaysBirthdays = List<Map<String, dynamic>>.from(
          todayResponse['birthdays'] ?? [],
        );
      }

      // Load upcoming birthdays
      final upcomingResponse = await ApiService.get('/birthdays/upcoming');
      if (upcomingResponse['success'] == true) {
        _upcomingBirthdays = List<Map<String, dynamic>>.from(
          upcomingResponse['upcoming_birthdays'] ?? [],
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Only show for leaders
        if (!authProvider.isMCLeader &&
            !authProvider.isBranchAdmin &&
            !authProvider.isSuperAdmin) {
          return const SizedBox.shrink();
        }

        if (_isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading birthday notifications...'),
                ],
              ),
            ),
          );
        }

        if (_errorMessage != null) {
          return Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error loading birthdays: $_errorMessage',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadBirthdayData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_todaysBirthdays.isNotEmpty && !_todaysCardDismissed) ...[
              _buildTodaysBirthdays(),
              const SizedBox(height: 16),
            ],
            if (_upcomingBirthdays.isNotEmpty && !_upcomingCardDismissed) ...[
              _buildUpcomingBirthdays(),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTodaysBirthdays() {
    return Card(
      color: Colors.orange.shade100, // Slightly more prominent background
      elevation: 4, // Add elevation for visual prominence
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cake, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  '🎂 Birthdays Today!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _dismissTodaysCard(),
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.orange.shade600,
                  ),
                  tooltip: 'Dismiss birthday notification',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._todaysBirthdays.map(
              (birthday) => _buildBirthdayItem(birthday, isToday: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBirthdays() {
    // Only show next 3 upcoming birthdays on dashboard
    final upcomingToShow = _upcomingBirthdays
        .where((b) => !b['is_today'])
        .take(3)
        .toList();

    if (upcomingToShow.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.blue.shade50,
      elevation: 2, // Subtle elevation for upcoming birthdays
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Birthdays',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                const Spacer(),
                if (_upcomingBirthdays.length > 3)
                  TextButton(
                    onPressed: _showAllUpcomingBirthdays,
                    child: Text(
                      'View All (${_upcomingBirthdays.length})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () => _dismissUpcomingCard(),
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.blue.shade600,
                  ),
                  tooltip: 'Dismiss upcoming birthdays',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...upcomingToShow.map(
              (birthday) => _buildBirthdayItem(birthday, isToday: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdayItem(
    Map<String, dynamic> birthday, {
    required bool isToday,
  }) {
    final name = birthday['name'] ?? 'Unknown';
    final contextName = birthday['context_name'] ?? '';
    final daysUntil = birthday['days_until_birthday'] ?? 0;
    final age = birthday['age_turning'];

    String subtitle = contextName;
    if (!isToday && daysUntil > 0) {
      subtitle += ' • ${daysUntil} day${daysUntil == 1 ? '' : 's'}';
    }
    if (age != null) {
      subtitle += ' • Turning $age';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isToday
                ? Colors
                      .orange
                      .shade300 // More vibrant orange background
                : Colors.blue.shade200,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isToday
                    ? Colors
                          .white // White text on orange for better contrast
                    : Colors.blue.shade800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isToday ? 16 : 14,
                    color: isToday
                        ? Colors
                              .orange
                              .shade800 // Prominent orange for today's birthdays
                        : Colors
                              .blue
                              .shade800, // Clear blue for upcoming birthdays
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday
                          ? Colors
                                .orange
                                .shade600 // Softer orange for subtitle
                          : Colors.grey.shade600, // Regular gray for upcoming
                    ),
                  ),
              ],
            ),
          ),
          if (isToday)
            Icon(Icons.celebration, color: Colors.orange.shade600, size: 20),
        ],
      ),
    );
  }

  void _showAllUpcomingBirthdays() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upcoming Birthdays'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _upcomingBirthdays.length,
            itemBuilder: (context, index) {
              final birthday = _upcomingBirthdays[index];
              return _buildBirthdayItem(
                birthday,
                isToday: birthday['is_today'],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Method to dismiss today's birthday card
  void _dismissTodaysCard() {
    setState(() {
      _todaysCardDismissed = true;
    });
  }

  // Method to dismiss upcoming birthdays card
  void _dismissUpcomingCard() {
    setState(() {
      _upcomingCardDismissed = true;
    });
  }
}
