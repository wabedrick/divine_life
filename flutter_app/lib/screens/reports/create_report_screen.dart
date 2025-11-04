import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/overflow_safe_widgets.dart';

class CreateReportScreen extends StatefulWidget {
  final Map<String, dynamic>? existingReport;
  final bool isEditing;

  const CreateReportScreen({
    super.key,
    this.existingReport,
    this.isEditing = false,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  late final TextEditingController _attendanceController;
  late final TextEditingController _newMembersController;
  late final TextEditingController _anagkazoController;
  late final TextEditingController _salvationsController;
  late final TextEditingController _offeringController;
  late final TextEditingController _notesController;

  // Form values
  DateTime _reportDate = DateTime.now();

  /// Calculate the Sunday of the week containing the given date
  DateTime _getWeekEndingSunday(DateTime date) {
    // DateTime.weekday returns 1 for Monday, 2 for Tuesday, ..., 7 for Sunday
    int weekday = date.weekday;

    // Calculate days to add to reach Sunday
    // If today is Monday (1), add 6 days to reach Sunday
    // If today is Tuesday (2), add 5 days to reach Sunday
    // If today is Sunday (7), add 0 days (already Sunday)
    int daysToAdd = weekday == 7 ? 0 : 7 - weekday;

    return date.add(Duration(days: daysToAdd));
  }

  /// Get the week range string for display (Monday - Sunday)
  String _getWeekRangeString(DateTime weekEndingSunday) {
    // Calculate Monday of that week (subtract 6 days from Sunday)
    DateTime monday = weekEndingSunday.subtract(Duration(days: 6));

    // Format the date range
    String mondayStr = '${monday.day}/${monday.month}/${monday.year}';
    String sundayStr =
        '${weekEndingSunday.day}/${weekEndingSunday.month}/${weekEndingSunday.year}';

    return '$mondayStr - $sundayStr';
  }

  @override
  void initState() {
    super.initState();
    _reportDate = _getWeekEndingSunday(DateTime.now());
    _initializeControllers();
    if (widget.isEditing && widget.existingReport != null) {
      _loadExistingReport();
    }
  }

  void _initializeControllers() {
    _attendanceController = TextEditingController();
    _newMembersController = TextEditingController();
    _anagkazoController = TextEditingController();
    _salvationsController = TextEditingController();
    _offeringController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _loadExistingReport() {
    final report = widget.existingReport!;
    _attendanceController.text = report['members_met']?.toString() ?? '';
    _newMembersController.text = report['new_members']?.toString() ?? '';
    _anagkazoController.text = report['anagkazo']?.toString() ?? '';
    _salvationsController.text = report['salvations']?.toString() ?? '';
    _offeringController.text = report['offerings']?.toString() ?? '';

    // Use correct field based on report type
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isMCLeader) {
      _notesController.text = report['comments'] ?? '';
    } else {
      // Branch report uses branch_activities
      _notesController.text = report['branch_activities'] ?? '';
    }

    if (report['week_ending'] != null) {
      _reportDate = DateTime.parse(report['week_ending']);
    }
  }

  @override
  void dispose() {
    _attendanceController.dispose();
    _newMembersController.dispose();
    _anagkazoController.dispose();
    _salvationsController.dispose();
    _offeringController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Report' : 'Create Report',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.isEditing) ...[
            IconButton(
              onPressed: _isLoading ? null : () => _saveReport(isDraft: true),
              icon: const Icon(Icons.drafts_outlined),
              tooltip: 'Save Draft',
              iconSize: 20,
            ),
            IconButton(
              onPressed: _isLoading ? null : () => _saveReport(isDraft: false),
              icon: const Icon(Icons.save),
              tooltip: 'Update Report',
              iconSize: 20,
            ),
          ] else
            IconButton(
              onPressed: _isLoading ? null : () => _saveReport(isDraft: false),
              icon: const Icon(Icons.send),
              tooltip: 'Submit Report',
              iconSize: 20,
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // Report Type and Date Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report Information',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () => _selectDate(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Week Ending (Sunday)',
                                    helperText:
                                        'Tap to select any date in the week',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                    isDense: true,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${_reportDate.day.toString().padLeft(2, '0')}/${_reportDate.month.toString().padLeft(2, '0')}/${_reportDate.year}',
                                        style: const TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Week: ${_getWeekRangeString(_reportDate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Statistics Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ministry Statistics',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              OverflowSafeRow(
                                spacing: 8.0,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _attendanceController,
                                      decoration: const InputDecoration(
                                        labelText: 'Members Met',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(
                                          Icons.people,
                                          size: 18,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12,
                                        ),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Invalid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _newMembersController,
                                      decoration: const InputDecoration(
                                        labelText: 'New Members',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(
                                          Icons.person_add,
                                          size: 18,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12,
                                        ),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value != null &&
                                            value.isNotEmpty &&
                                            int.tryParse(value) == null) {
                                          return 'Invalid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              OverflowSafeRow(
                                spacing: 8.0,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _anagkazoController,
                                      decoration: const InputDecoration(
                                        labelText: 'Anagkazo',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(
                                          Icons.group_add,
                                          size: 18,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12,
                                        ),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _salvationsController,
                                      decoration: const InputDecoration(
                                        labelText: 'Salvations',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(
                                          Icons.favorite,
                                          size: 18,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _offeringController,
                                decoration: const InputDecoration(
                                  labelText: 'Offering Amount (UGX)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.monetization_on,
                                    size: 18,
                                  ),
                                  helperText:
                                      'Optional - financial offering received in Uganda Shillings',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notes and Comments Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Additional Information',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'General Notes',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                  helperText:
                                      'General observations and highlights',
                                ),
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      if (!widget.isEditing)
                        OverflowSafeRow(
                          spacing: 8.0,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _saveReport(isDraft: true),
                                child: const Text('Save as Draft'),
                              ),
                            ),
                            Expanded(
                              child: FilledButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _saveReport(isDraft: false),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Submit Report'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reportDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Select any date in the week',
    );
    if (picked != null) {
      // Calculate the Sunday of the week containing the picked date
      DateTime weekEndingSunday = _getWeekEndingSunday(picked);
      if (weekEndingSunday != _reportDate) {
        setState(() {
          _reportDate = weekEndingSunday;
        });
      }
    }
  }

  Future<void> _saveReport({required bool isDraft}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      Map<String, dynamic> reportData;
      String endpoint;

      // Determine report data based on user role
      if (authProvider.isMCLeader) {
        // MC Report
        reportData = {
          'mc_id': authProvider.userMCId,
          'week_ending': _reportDate.toIso8601String().split('T')[0],
          'members_met': int.tryParse(_attendanceController.text) ?? 0,
          'new_members': int.tryParse(_newMembersController.text) ?? 0,
          'anagkazo': int.tryParse(_anagkazoController.text) ?? 0,
          'salvations': int.tryParse(_salvationsController.text) ?? 0,
          'offerings': double.tryParse(_offeringController.text) ?? 0.0,
          'comments': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        };
        endpoint = '/reports';
      } else {
        // Branch Report - for Branch Admins and Super Admins
        reportData = {
          'week_ending': _reportDate.toIso8601String().split('T')[0],
          'total_mcs_reporting': int.tryParse(_attendanceController.text) ?? 0,
          'total_members_met': int.tryParse(_newMembersController.text) ?? 0,
          'total_anagkazo': int.tryParse(_anagkazoController.text) ?? 0,
          'total_salvations': int.tryParse(_salvationsController.text) ?? 0,
          'total_offerings': double.tryParse(_offeringController.text) ?? 0.0,
          'branch_activities': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        };
        endpoint = '/branch-reports';
      }

      if (widget.isEditing) {
        await ApiService.put(
          '$endpoint/${widget.existingReport!['id']}',
          data: reportData,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report updated successfully')),
          );
        }
      } else {
        await ApiService.post(endpoint, data: reportData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isDraft
                    ? 'Report saved as draft'
                    : 'Report submitted for approval',
              ),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving report: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
