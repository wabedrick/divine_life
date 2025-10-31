import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getEvents();
      setState(() {
        _events = List<Map<String, dynamic>>.from(response['events'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredEvents {
    if (_searchQuery.isEmpty) return _events;
    return _events.where((event) {
      final title = (event['title'] ?? '').toLowerCase();
      final description = (event['description'] ?? '').toLowerCase();
      final location = (event['location'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) ||
          description.contains(query) ||
          location.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search events...',
              leading: const Icon(Icons.search),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
        ),
      ),
      body: _buildBody(authProvider),
      floatingActionButton: authProvider.canManageEvents
          ? FloatingActionButton(
              onPressed: _showCreateEventDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(AuthProvider authProvider) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading events',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadEvents, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              _events.isEmpty
                  ? 'No events found'
                  : 'No events match your search',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _events.isEmpty
                  ? 'Events will appear here when created'
                  : 'Try adjusting your search criteria',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredEvents.length,
        itemBuilder: (context, index) {
          final event = _filteredEvents[index];
          return _buildEventCard(event, authProvider);
        },
      ),
    );
  }

  Widget _buildEventCard(
    Map<String, dynamic> event,
    AuthProvider authProvider,
  ) {
    final eventDate = DateTime.tryParse(event['event_date'] ?? '');
    final isUpcoming = eventDate?.isAfter(DateTime.now()) ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event['title'] ?? 'No Title',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isUpcoming)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Upcoming',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (authProvider.canManageEvents) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditEventDialog(event);
                            break;
                          case 'delete':
                            _showDeleteEventDialog(event);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (event['description'] != null) ...[
                Text(
                  event['description'],
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    eventDate != null
                        ? '${eventDate.day}/${eventDate.month}/${eventDate.year}'
                        : 'No date',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  if (event['location'] != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event['location'],
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event['title'] ?? 'Event Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event['description'] != null) ...[
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(event['description']),
                const SizedBox(height: 16),
              ],
              if (event['event_date'] != null) ...[
                const Text(
                  'Date:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(event['event_date']),
                const SizedBox(height: 16),
              ],
              if (event['location'] != null) ...[
                const Text(
                  'Location:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(event['location']),
                const SizedBox(height: 16),
              ],
              if (event['created_by_name'] != null) ...[
                const Text(
                  'Created by:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(event['created_by_name']),
              ],
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

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => _EventFormDialog(onEventSaved: () => _loadEvents()),
    );
  }

  void _showEditEventDialog(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) =>
          _EventFormDialog(event: event, onEventSaved: () => _loadEvents()),
    );
  }

  void _showDeleteEventDialog(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEvent(event['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(int eventId) async {
    try {
      await ApiService.delete('/events/$eventId');
      _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting event: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _EventFormDialog extends StatefulWidget {
  final Map<String, dynamic>? event;
  final VoidCallback onEventSaved;

  const _EventFormDialog({this.event, required this.onEventSaved});

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  String _visibility = 'all';
  int? _selectedBranchId;
  int? _selectedMCId;

  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _mcs = [];

  bool _isLoading = false;

  final List<String> _visibilityOptions = ['all', 'branch', 'mc'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadBranches();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(
      text: widget.event?['title'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.event?['description'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.event?['location'] ?? '',
    );

    if (widget.event != null) {
      _visibility = widget.event!['visibility'] ?? 'all';
      _selectedBranchId = widget.event!['branch_id'] as int?;
      _selectedMCId = widget.event!['mc_id'] as int?;

      if (widget.event!['start_datetime'] != null) {
        final startDateTime = DateTime.parse(widget.event!['start_datetime']);
        _startDate = startDateTime;
        _startTime = TimeOfDay.fromDateTime(startDateTime);
      }

      if (widget.event!['end_datetime'] != null) {
        final endDateTime = DateTime.parse(widget.event!['end_datetime']);
        _endDate = endDateTime;
        _endTime = TimeOfDay.fromDateTime(endDateTime);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final response = await ApiService.get('/branches');
      setState(() {
        _branches = List<Map<String, dynamic>>.from(response['data'] ?? []);
      });
      if (_selectedBranchId != null) {
        _loadMCs();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadMCs() async {
    if (_selectedBranchId == null) return;

    try {
      final response = await ApiService.get('/branches/$_selectedBranchId/mcs');
      setState(() {
        _mcs = List<Map<String, dynamic>>.from(response['data'] ?? []);
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      } else if (_endDate != null) {
        // If end date is selected but no end time, use end of day
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
        );
      } else if (_endTime != null) {
        // If end time is selected but no end date, use same date as start date
        endDateTime = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      } else {
        // If no end date/time specified, set it to same day as start date but 1 hour later
        // This handles same-day events which are most common
        endDateTime = startDateTime.add(const Duration(hours: 1));
      }

      // Ensure end date is not before start date
      if (endDateTime.isBefore(startDateTime)) {
        // If end time is earlier than start time on same day, assume it's the next day
        if (_endDate != null &&
            _endTime != null &&
            _endDate!.year == _startDate!.year &&
            _endDate!.month == _startDate!.month &&
            _endDate!.day == _startDate!.day) {
          endDateTime = endDateTime.add(const Duration(days: 1));
        } else {
          // Otherwise just add 1 hour to start time
          endDateTime = startDateTime.add(const Duration(hours: 1));
        }
      }

      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'event_date': startDateTime.toIso8601String(),
        'end_date': endDateTime.toIso8601String(),
        'visibility': _visibility,
        'branch_id': _visibility == 'branch' ? _selectedBranchId : null,
        'mc_id': _visibility == 'mc' ? _selectedMCId : null,
      };

      if (widget.event != null) {
        // Update existing event
        await ApiService.put('/events/${widget.event!['id']}', data: eventData);
      } else {
        // Create new event
        await ApiService.post('/events', data: eventData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Event ${widget.event != null ? 'updated' : 'created'} successfully',
            ),
          ),
        );
        widget.onEventSaved();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${widget.event != null ? 'updating' : 'creating'} event: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getVisibilityDisplayName(String visibility) {
    switch (visibility) {
      case 'all':
        return 'All Users';
      case 'branch':
        return 'Branch Only';
      case 'mc':
        return 'MC Only';
      default:
        return visibility;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_calendar : Icons.add_circle,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Event' : 'Create Event',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event Title *',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter event title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location Field
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Start Date and Time
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (date != null) {
                                  setState(() => _startDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date *',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                      : 'Select start date',
                                  style: TextStyle(
                                    color: _startDate != null
                                        ? Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color
                                        : Theme.of(context).hintColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _startTime ?? TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setState(() => _startTime = time);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Time *',
                                  prefixIcon: Icon(Icons.access_time),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _startTime != null
                                      ? _startTime!.format(context)
                                      : 'Select start time',
                                  style: TextStyle(
                                    color: _startTime != null
                                        ? Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color
                                        : Theme.of(context).hintColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // End Date and Time
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _endDate ?? _startDate ?? DateTime.now(),
                                  firstDate: _startDate ?? DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (date != null) {
                                  setState(() => _endDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                      : 'Select end date',
                                  style: TextStyle(
                                    color: _endDate != null
                                        ? Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color
                                        : Theme.of(context).hintColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _endTime ?? TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setState(() => _endTime = time);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Time',
                                  prefixIcon: Icon(Icons.access_time),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _endTime != null
                                      ? _endTime!.format(context)
                                      : 'Select end time',
                                  style: TextStyle(
                                    color: _endTime != null
                                        ? Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color
                                        : Theme.of(context).hintColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Visibility Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _visibility,
                        decoration: const InputDecoration(
                          labelText: 'Visibility *',
                          prefixIcon: Icon(Icons.visibility),
                          border: OutlineInputBorder(),
                        ),
                        items: _visibilityOptions
                            .map(
                              (visibility) => DropdownMenuItem(
                                value: visibility,
                                child: Text(
                                  _getVisibilityDisplayName(visibility),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _visibility = value!;
                            if (_visibility != 'branch') {
                              _selectedBranchId = null;
                            }
                            if (_visibility != 'mc') _selectedMCId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Branch Dropdown (if visibility is branch)
                      if (_visibility == 'branch') ...[
                        DropdownButtonFormField<int>(
                          initialValue: _selectedBranchId,
                          decoration: const InputDecoration(
                            labelText: 'Branch *',
                            prefixIcon: Icon(Icons.location_city),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select Branch'),
                            ),
                            ..._branches.map(
                              (branch) => DropdownMenuItem(
                                value: branch['id'] as int,
                                child: Text(branch['name'] ?? 'Unknown Branch'),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedBranchId = value),
                          validator: (value) {
                            if (_visibility == 'branch' && value == null) {
                              return 'Please select a branch';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // MC Dropdown (if visibility is mc)
                      if (_visibility == 'mc') ...[
                        DropdownButtonFormField<int>(
                          initialValue: _selectedBranchId,
                          decoration: const InputDecoration(
                            labelText: 'Branch *',
                            prefixIcon: Icon(Icons.location_city),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select Branch'),
                            ),
                            ..._branches.map(
                              (branch) => DropdownMenuItem(
                                value: branch['id'] as int,
                                child: Text(branch['name'] ?? 'Unknown Branch'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedBranchId = value;
                              _selectedMCId = null;
                            });
                            if (value != null) {
                              _loadMCs();
                            }
                          },
                          validator: (value) {
                            if (_visibility == 'mc' && value == null) {
                              return 'Please select a branch first';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedMCId,
                          decoration: const InputDecoration(
                            labelText: 'Missional Community *',
                            prefixIcon: Icon(Icons.groups),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select MC'),
                            ),
                            ..._mcs.map(
                              (mc) => DropdownMenuItem(
                                value: mc['id'] as int,
                                child: Text(mc['name'] ?? 'Unknown MC'),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedMCId = value),
                          validator: (value) {
                            if (_visibility == 'mc' && value == null) {
                              return 'Please select an MC';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveEvent,
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Update Event' : 'Create Event'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
