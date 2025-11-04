import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/pdf_service.dart';
import 'create_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _myReports = [];
  List<Map<String, dynamic>> _pendingReports = [];
  List<Map<String, dynamic>> _filteredMyReports = [];
  List<Map<String, dynamic>> _filteredPendingReports = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _errorMessage;

  // Filter state
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _tabController = TabController(
      length: authProvider.canApproveReports ? 2 : 1,
      vsync: this,
    );
    _loadReports();
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Load user's reports
      final myReportsResponse = await ApiService.getReports();
      _myReports = List<Map<String, dynamic>>.from(
        myReportsResponse['reports'] ?? [],
      );

      // Load pending reports if user can approve
      if (authProvider.canApproveReports) {
        final pendingReportsResponse = await ApiService.get('/reports/pending');
        _pendingReports = List<Map<String, dynamic>>.from(
          pendingReportsResponse['pending_reports'] ?? [],
        );
      }

      _applyFilters();

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

  Future<void> _loadStatistics() async {
    try {
      final response = await ApiService.getReportStatistics();
      setState(() {
        _statistics = response['statistics'];
      });
    } catch (e) {
      // Don't show error for statistics as it's not critical
      // Statistics will remain null and won't be displayed
    }
  }

  void _applyFilters() {
    _filteredMyReports = _filterReports(_myReports);
    _filteredPendingReports = _filterReports(_pendingReports);
  }

  List<Map<String, dynamic>> _filterReports(
    List<Map<String, dynamic>> reports,
  ) {
    return reports.where((report) {
      // Filter by status
      if (_selectedStatus != 'all' && report['status'] != _selectedStatus) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final weekRange = _getWeekDateRange(
          report['week_ending'],
        ).toLowerCase();
        final submitter = (report['submitted_by']?['name'] ?? '')
            .toString()
            .toLowerCase();

        if (!weekRange.contains(query) && !submitter.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: authProvider.canApproveReports
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    text: 'My Reports (${_filteredMyReports.length})',
                    icon: const Icon(Icons.assignment),
                  ),
                  Tab(
                    text: 'Pending (${_filteredPendingReports.length})',
                    icon: const Icon(Icons.pending_actions),
                  ),
                ],
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          if (authProvider.canApproveReports)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'export_monthly') {
                  _showMonthlyExportDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export_monthly',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf),
                    title: Text('Export Monthly PDF'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Fixed top section with search and statistics
          Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search reports...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
              ),

              // Statistics Section
              if (_statistics != null) _buildStatisticsSection(),
            ],
          ),

          // Error Message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadReports,
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : authProvider.canApproveReports
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReportsList(_filteredMyReports, false),
                      _buildReportsList(_filteredPendingReports, true),
                    ],
                  )
                : _buildReportsList(_filteredMyReports, false),
          ),
        ],
      ),
      floatingActionButton: context.read<AuthProvider>().canCreateReports
          ? FloatingActionButton.extended(
              onPressed: _showCreateReportDialog,
              icon: const Icon(Icons.add_chart),
              label: Text(_getCreateButtonLabel()),
            )
          : null,
    );
  }

  Widget _buildReportsList(List<Map<String, dynamic>> reports, bool isPending) {
    if (reports.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPending ? Icons.pending_actions : Icons.assessment_outlined,
                size: 48, // Reduced from 64
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(height: 12), // Reduced from 16
              Text(
                isPending ? 'No pending reports' : 'No reports yet',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6), // Reduced from 8
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  isPending
                      ? 'Reports awaiting approval will appear here'
                      : 'Start by creating your first report',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildReportCard(report, isPending);
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, bool isPending) {
    final status = report['status'] ?? '';
    final submittedBy = report['submitted_by']?['name'] ?? 'Unknown';
    final weekEnding = report['week_ending'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(_getStatusIcon(status), color: Colors.white),
        ),
        title: Text(
          'Weekly Report - ${_getWeekDateRange(weekEnding)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submitted by: $submittedBy'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleReportAction(value, report),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View Details'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (isPending) ...[
              const PopupMenuItem(
                value: 'approve',
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Approve'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'reject',
                child: ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('Reject'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ] else ...[
              if (_canEditReport(report))
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (_canDeleteReport(report))
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'draft':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      case 'draft':
        return Icons.edit;
      default:
        return Icons.assessment;
    }
  }

  String _getWeekDateRange(String? weekEndingStr) {
    if (weekEndingStr == null || weekEndingStr.isEmpty) {
      return 'Date range not available';
    }

    try {
      DateTime weekEnding = DateTime.parse(weekEndingStr);

      // Calculate Monday of that week
      // weekEnding should be a Sunday, so subtract 6 days to get Monday
      DateTime monday = weekEnding.subtract(Duration(days: 6));

      // Format the date range
      String mondayStr = '${monday.day}/${monday.month}/${monday.year}';
      String sundayStr =
          '${weekEnding.day}/${weekEnding.month}/${weekEnding.year}';

      return '$mondayStr - $sundayStr';
    } catch (e) {
      return 'Invalid date';
    }
  }

  bool _canEditReport(Map<String, dynamic> report) {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    final userBranchId = authProvider.userBranchId;

    if (userId == null) return false;

    // Report must be in pending status to be edited
    if (report['status'] != 'pending') return false;

    // Super admins can edit any report
    if (authProvider.isSuperAdmin) return true;

    // Branch admins can edit reports from their branch
    if (authProvider.isBranchAdmin && userBranchId != null) {
      final reportMC = report['mc'];
      if (reportMC != null && reportMC['branch_id'] == userBranchId) {
        return true;
      }
    }

    // MC leaders can edit their own MC reports
    if (authProvider.isMCLeader) {
      final reportMC = report['mc'];
      if (reportMC != null && reportMC['leader_id'] == userId) {
        return true;
      }
    }

    return false;
  }

  bool _canDeleteReport(Map<String, dynamic> report) {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    final userBranchId = authProvider.userBranchId;

    if (userId == null) return false;

    // Report must be in pending status to be deleted
    if (report['status'] != 'pending') return false;

    // Super admins can delete any report
    if (authProvider.isSuperAdmin) return true;

    // Branch admins can delete reports from their branch
    if (authProvider.isBranchAdmin && userBranchId != null) {
      final reportMC = report['mc'];
      if (reportMC != null && reportMC['branch_id'] == userBranchId) {
        return true;
      }
    }

    // MC leaders can delete their own MC reports
    if (authProvider.isMCLeader) {
      final reportMC = report['mc'];
      if (reportMC != null && reportMC['leader_id'] == userId) {
        return true;
      }
    }

    return false;
  }

  void _handleReportAction(String action, Map<String, dynamic> report) {
    switch (action) {
      case 'view':
        _showReportDetails(report);
        break;
      case 'edit':
        _showEditReportDialog(report);
        break;
      case 'delete':
        _showDeleteDialog(report);
        break;
      case 'approve':
        _approveReport(report['id']);
        break;
      case 'reject':
        _showRejectDialog(report);
        break;
      case 'export':
        _exportReport(report);
        break;
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Weekly Report - ${_getWeekDateRange(report['week_ending'])}',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${report['status']?.toUpperCase() ?? 'N/A'}'),
              Text('Members Met: ${report['members_met'] ?? 'N/A'}'),
              Text('New Members: ${report['new_members'] ?? 'N/A'}'),
              Text('Anagkazo: ${report['anagkazo'] ?? 'N/A'}'),
              Text('Salvations: ${report['salvations'] ?? 'N/A'}'),
              Text('Offerings: UGX ${report['offerings'] ?? 'N/A'}'),
              const SizedBox(height: 12),
              if (_hasValue(report['comments'])) ...[
                const Text(
                  'General Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(report['comments']?.toString() ?? ''),
                const SizedBox(height: 8),
              ],
              if (report['submitted_at'] != null)
                Text(
                  'Submitted: ${report['submitted_at']?.toString() ?? 'N/A'}',
                ),
            ],
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

  String _getCreateButtonLabel() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isMCLeader) {
      return 'New MC Report';
    } else if (authProvider.isBranchAdmin) {
      return 'New Branch Report';
    } else {
      return 'New Report';
    }
  }

  void _showCreateReportDialog() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CreateReportScreen()));
    if (result == true) {
      _loadReports(); // Refresh the reports list
    }
  }

  void _showEditReportDialog(Map<String, dynamic> report) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CreateReportScreen(existingReport: report, isEditing: true),
      ),
    );
    if (result == true) {
      _loadReports(); // Refresh the reports list
    }
  }

  Future<void> _approveReport(int reportId) async {
    try {
      await ApiService.post('/reports/$reportId/approve');
      _loadReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving report: $e')));
      }
    }
  }

  Future<void> _deleteReport(int reportId) async {
    try {
      await ApiService.deleteReport(reportId);
      _loadReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting report: $e')));
      }
    }
  }

  void _showDeleteDialog(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text(
          'Are you sure you want to delete the weekly report for ${_getWeekDateRange(report['week_ending'])}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteReport(report['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> report) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this report:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectReport(report['id'], reasonController.text);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectReport(int reportId, String reason) async {
    try {
      await ApiService.post(
        '/reports/$reportId/reject',
        data: {'reason': reason},
      );
      _loadReports();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting report: $e')));
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reports'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Search by date range or submitter...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = 'all';
                _searchQuery = '';
                _applyFilters();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _applyFilters();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _exportReport(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share as Text'),
              subtitle: const Text('Share report data as formatted text'),
              onTap: () {
                Navigator.pop(context);
                _shareReportAsText(report);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy to Clipboard'),
              subtitle: const Text('Copy report data to clipboard'),
              onTap: () {
                Navigator.pop(context);
                _copyReportToClipboard(report);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              subtitle: const Text('Generate PDF document'),
              onTap: () {
                Navigator.pop(context);
                _exportReportAsPDF(report);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareReportAsText(Map<String, dynamic> report) {
    // You would use share_plus package here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality requires share_plus package'),
      ),
    );
  }

  void _copyReportToClipboard(Map<String, dynamic> report) {
    // You would use flutter/services Clipboard here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report data copied to clipboard')),
    );
  }

  Future<void> _exportReportAsPDF(Map<String, dynamic> report) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Generating PDF...'),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Determine report type
      String reportType = 'Weekly';
      if (report['month'] != null && report['year'] != null) {
        reportType = 'Monthly';
      }

      // Generate PDF
      await PDFService.generateReportPDF(
        report: report,
        reportType: reportType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showMonthlyExportDialog() {
    showDialog(
      context: context,
      builder: (context) => _MonthlyExportDialog(
        onExport: (month, year) => _exportMonthlyPDF(month, year),
      ),
    );
  }

  Future<void> _exportMonthlyPDF(int month, int year) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Generating monthly PDF...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Fetch monthly reports
      final response = await ApiService.get(
        '/reports',
        queryParameters: {'month': month.toString(), 'year': year.toString()},
      );

      final reports = List<Map<String, dynamic>>.from(response['data'] ?? []);
      final monthName = _getMonthName(month);

      // Generate monthly PDF
      await PDFService.generateMonthlyReportPDF(
        reports: reports,
        month: monthName,
        year: year.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monthly PDF generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating monthly PDF: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is num) return true;
    return value.toString().trim().isNotEmpty;
  }

  Widget _buildStatisticsSection() {
    final authProvider = context.read<AuthProvider>();
    final stats = _statistics!;

    String title = 'Statistics';
    if (authProvider.isSuperAdmin) {
      title = 'Global Church Statistics';
    } else if (authProvider.isBranchAdmin) {
      title = 'Branch Statistics';
    } else if (authProvider.isMCLeader) {
      title = 'MC Statistics';
    }

    // Add week period information if available
    String? periodText = stats['period']?['display_text'];
    String subtitle = periodText ?? 'Current Period';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Reports',
                  (stats['total_reports'] ?? 0).toString(),
                  Icons.assignment,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Members Met',
                  (stats['totals']?['total_members_met'] ?? 0).toString(),
                  Icons.people,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'New Members',
                  (stats['totals']?['total_new_members'] ?? 0).toString(),
                  Icons.person_add,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Salvations',
                  (stats['totals']?['total_salvations'] ?? 0).toString(),
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Anagkazo',
                  (stats['totals']?['total_anagkazo'] ?? 0).toString(),
                  Icons.water_drop,
                  Colors.cyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Offerings',
                  'UGX ${(stats['totals']?['total_offerings'] ?? 0.0).toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green.shade700,
                ),
              ),
            ],
          ),
          if (authProvider.canApproveReports) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              'Report Status',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildStatusChip(
                    'Pending',
                    (stats['by_status']?['pending'] ?? 0).toString(),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusChip(
                    'Approved',
                    (stats['by_status']?['approved'] ?? 0).toString(),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusChip(
                    'Rejected',
                    (stats['by_status']?['rejected'] ?? 0).toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyExportDialog extends StatefulWidget {
  final Function(int month, int year) onExport;

  const _MonthlyExportDialog({required this.onExport});

  @override
  State<_MonthlyExportDialog> createState() => _MonthlyExportDialogState();
}

class _MonthlyExportDialogState extends State<_MonthlyExportDialog> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Monthly Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Month',
              border: OutlineInputBorder(),
            ),
            items: List.generate(
              12,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text(_months[index]),
              ),
            ),
            onChanged: (value) => setState(() => _selectedMonth = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedYear,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
            items: List.generate(5, (index) {
              final year = DateTime.now().year - 2 + index;
              return DropdownMenuItem(
                value: year,
                child: Text(year.toString()),
              );
            }),
            onChanged: (value) => setState(() => _selectedYear = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onExport(_selectedMonth, _selectedYear);
          },
          child: const Text('Export PDF'),
        ),
      ],
    );
  }
}
