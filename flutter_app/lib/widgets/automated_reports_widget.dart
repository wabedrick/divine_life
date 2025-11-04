import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/api_service.dart';

class AutomatedReportsWidget extends StatefulWidget {
  const AutomatedReportsWidget({super.key});

  @override
  State<AutomatedReportsWidget> createState() => _AutomatedReportsWidgetState();
}

class _AutomatedReportsWidgetState extends State<AutomatedReportsWidget> {
  bool _isGenerating = false;
  bool _isLoadingPending = false;
  List<Map<String, dynamic>> _pendingReports = [];
  Map<String, dynamic>? _lastGenerationResult;

  @override
  void initState() {
    super.initState();
    _loadPendingReports();
  }

  Future<void> _loadPendingReports() async {
    setState(() {
      _isLoadingPending = true;
    });

    try {
      final response = await ApiService.getPendingAutomatedReports();
      setState(() {
        _pendingReports = List<Map<String, dynamic>>.from(
          response['pending_reports'] ?? [],
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pending reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingPending = false;
      });
    }
  }

  Future<void> _generateAutomatedReports() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final response = await ApiService.generateAutomatedBranchReports();

      setState(() {
        _lastGenerationResult = response;
      });

      if (mounted) {
        final summary = response['summary'] as Map<String, dynamic>?;
        final successful = summary?['successful'] ?? 0;
        final total = summary?['total_branches'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generated $successful/$total branch reports successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload pending reports
      _loadPendingReports();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _markAsSent(int reportId) async {
    try {
      await ApiService.markBranchReportAsSent(reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report marked as sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload pending reports
      _loadPendingReports();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as sent: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Only show to super admins
    if (!authProvider.isSuperAdmin) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Automated Branch Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Generate Reports Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateAutomatedReports,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isGenerating
                      ? 'Generating Reports...'
                      : 'Generate Weekly Branch Reports',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Last Generation Result
            if (_lastGenerationResult != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Last Generation:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Week ending: ${_lastGenerationResult!['week_ending']}',
                    ),
                    Text(
                      'Successful: ${_lastGenerationResult!['summary']['successful']}/'
                      '${_lastGenerationResult!['summary']['total_branches']} branches',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pending Reports Section
            Row(
              children: [
                const Icon(Icons.pending_actions, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pending Reports (${_pendingReports.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isLoadingPending) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            if (_pendingReports.isEmpty && !_isLoadingPending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No pending automated reports',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...List.generate(_pendingReports.take(3).length, (index) {
                final report = _pendingReports[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report['branch']['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Week ending: ${report['week_ending']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _markAsSent(report['id']),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Mark Sent'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            if (_pendingReports.length > 3)
              TextButton(
                onPressed: () {
                  // Navigate to full pending reports list
                },
                child: Text(
                  'View all ${_pendingReports.length} pending reports',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
