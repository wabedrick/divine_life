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
  late final TextEditingController _baptismsController;
  late final TextEditingController _testimoniesController;
  late final TextEditingController _salvationsController;
  late final TextEditingController _healingsController;
  late final TextEditingController _offeringController;
  late final TextEditingController _notesController;
  late final TextEditingController _challengesController;
  late final TextEditingController _prayerRequestsController;
  late final TextEditingController _goalsController;

  // Form values
  String _reportType = 'weekly';
  DateTime _reportDate = DateTime.now();
  int _weekNumber = 1;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _calculateWeekNumber();
    if (widget.isEditing && widget.existingReport != null) {
      _loadExistingReport();
    }
  }

  void _initializeControllers() {
    _attendanceController = TextEditingController();
    _newMembersController = TextEditingController();
    _baptismsController = TextEditingController();
    _testimoniesController = TextEditingController();
    _salvationsController = TextEditingController();
    _healingsController = TextEditingController();
    _offeringController = TextEditingController();
    _notesController = TextEditingController();
    _challengesController = TextEditingController();
    _prayerRequestsController = TextEditingController();
    _goalsController = TextEditingController();
  }

  void _loadExistingReport() {
    final report = widget.existingReport!;
    _attendanceController.text = report['members_met']?.toString() ?? '';
    _newMembersController.text = report['new_members']?.toString() ?? '';
    _offeringController.text = report['offerings']?.toString() ?? '';
    _notesController.text = report['evangelism_activities'] ?? '';
    _challengesController.text = report['comments'] ?? '';

    // Initialize other fields to empty since backend doesn't support them
    _baptismsController.text = '';
    _testimoniesController.text = '';
    _salvationsController.text = '';
    _healingsController.text = '';
    _prayerRequestsController.text = '';
    _goalsController.text = '';

    if (report['week_ending'] != null) {
      _reportDate = DateTime.parse(report['week_ending']);
    }
  }

  void _calculateWeekNumber() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final daysSinceStartOfYear = now.difference(startOfYear).inDays;
    _weekNumber = (daysSinceStartOfYear / 7).ceil();
  }

  @override
  void dispose() {
    _attendanceController.dispose();
    _newMembersController.dispose();
    _baptismsController.dispose();
    _testimoniesController.dispose();
    _salvationsController.dispose();
    _healingsController.dispose();
    _offeringController.dispose();
    _notesController.dispose();
    _challengesController.dispose();
    _prayerRequestsController.dispose();
    _goalsController.dispose();
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
                              OverflowSafeRow(
                                spacing: 8.0,
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _reportType,
                                      decoration: const InputDecoration(
                                        labelText: 'Type',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12,
                                        ),
                                        isDense: true,
                                      ),
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'weekly',
                                          child: Text(
                                            'Weekly',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'monthly',
                                          child: Text(
                                            'Monthly',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'special',
                                          child: Text(
                                            'Special',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _reportType = value!;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Week #',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12,
                                        ),
                                        isDense: true,
                                      ),
                                      initialValue: _weekNumber.toString(),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        _weekNumber =
                                            int.tryParse(value) ?? _weekNumber;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () => _selectDate(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date',
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
                                  child: Text(
                                    '${_reportDate.day.toString().padLeft(2, '0')}/${_reportDate.month.toString().padLeft(2, '0')}/${_reportDate.year}',
                                    overflow: TextOverflow.ellipsis,
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
                                        labelText: 'Attendance',
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
                                      controller: _baptismsController,
                                      decoration: const InputDecoration(
                                        labelText: 'Baptisms',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(
                                          Icons.water_drop,
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
                              OverflowSafeRow(
                                spacing: 8.0,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _testimoniesController,
                                      decoration: const InputDecoration(
                                        labelText: 'Testimonies',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(
                                          Icons.record_voice_over,
                                          size: 18,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _healingsController,
                                      decoration: const InputDecoration(
                                        labelText: 'Healings',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(
                                          Icons.healing,
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
                                  labelText: 'Offering Amount',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.attach_money,
                                    size: 18,
                                  ),
                                  helperText:
                                      'Optional - financial offering received',
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
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _challengesController,
                                decoration: const InputDecoration(
                                  labelText: 'Challenges Faced',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                  helperText:
                                      'Difficulties encountered this period',
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _prayerRequestsController,
                                decoration: const InputDecoration(
                                  labelText: 'Prayer Requests',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                  helperText: 'Specific prayer needs',
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _goalsController,
                                decoration: const InputDecoration(
                                  labelText: 'Goals for Next Period',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                  helperText:
                                      'Plans and objectives for upcoming period',
                                ),
                                maxLines: 3,
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
    );
    if (picked != null && picked != _reportDate) {
      setState(() {
        _reportDate = picked;
      });
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

      final reportData = {
        'mc_id': authProvider.userMCId,
        'week_ending': _reportDate.toIso8601String().split('T')[0],
        'members_met': int.tryParse(_attendanceController.text) ?? 0,
        'new_members': int.tryParse(_newMembersController.text) ?? 0,
        'offerings': double.tryParse(_offeringController.text) ?? 0.0,
        'evangelism_activities': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'comments': _challengesController.text.trim().isEmpty
            ? null
            : _challengesController.text.trim(),
      };

      if (widget.isEditing) {
        await ApiService.put(
          '/reports/${widget.existingReport!['id']}',
          data: reportData,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report updated successfully')),
          );
        }
      } else {
        await ApiService.post('/reports', data: reportData);
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
