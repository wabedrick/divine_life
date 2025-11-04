import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/api_service.dart';

class BranchAdminReportsWidget extends StatefulWidget {
  const BranchAdminReportsWidget({super.key});

  @override
  State<BranchAdminReportsWidget> createState() =>
      _BranchAdminReportsWidgetState();
}

class _BranchAdminReportsWidgetState extends State<BranchAdminReportsWidget> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingReports = [];

  @override
  void initState() {
    super.initState();
    _loadPendingReports();
  }

  Future<void> _loadPendingReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getPendingBranchReports();
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
        _isLoading = false;
      });
    }
  }

  Future<void> _sendReportToSuperAdmin(int reportId) async {
    try {
      await ApiService.sendBranchReportToSuperAdmin(reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report sent to Super Admin successfully!'),
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
            content: Text('Failed to send report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Branch Report - Week ${_formatDate(report['week_ending'])}',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'MCs Reporting',
                '${report['total_mcs_reporting']}',
              ),
              _buildDetailRow('Members Met', '${report['total_members_met']}'),
              _buildDetailRow('New Members', '${report['total_new_members']}'),
              _buildDetailRow('Salvations', '${report['total_salvations']}'),
              _buildDetailRow('Anagkazo', '${report['total_anagkazo']}'),
              _buildDetailRow('Offerings', 'UGX ${report['total_offerings']}'),
              const SizedBox(height: 16),
              const Text(
                'Activities:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(report['branch_activities'] ?? 'N/A'),
              const SizedBox(height: 12),
              const Text(
                'Challenges:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(report['challenges'] ?? 'N/A'),
              const SizedBox(height: 12),
              const Text(
                'Prayer Requests:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(report['prayer_requests'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmSendReport(report);
            },
            icon: const Icon(Icons.send),
            label: const Text('Send to Super Admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSendReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Send Report'),
        content: Text(
          'Are you sure you want to send this branch report for week ${_formatDate(report['week_ending'])} to the Super Admin?\n\n'
          'Once sent, you cannot make changes to this report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendReportToSuperAdmin(report['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Only show to branch admins
    if (!authProvider.isBranchAdmin) {
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
                const Icon(Icons.pending_actions, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Pending Branch Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadPendingReports,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_pendingReports.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No pending reports',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'All auto-generated reports have been sent',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You have ${_pendingReports.length} auto-generated report${_pendingReports.length == 1 ? '' : 's'} '
                            'ready for review and submission to Super Admin.',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_pendingReports.length, (index) {
                    final report = _pendingReports[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(
                            Icons.description,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Week ending ${_formatDate(report['week_ending'])}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${report['total_mcs_reporting']} MCs • '
                              '${report['total_members_met']} members • '
                              'UGX ${report['total_offerings']}',
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'AUTO-GENERATED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showReportDetails(report),
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text('Review'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _confirmSendReport(report),
                              icon: const Icon(Icons.send, size: 16),
                              label: const Text('Send'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
