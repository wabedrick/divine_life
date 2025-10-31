import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getAnnouncements();
      setState(() {
        _announcements = List<Map<String, dynamic>>.from(
          response['announcements'] ?? [],
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredAnnouncements {
    if (_searchQuery.isEmpty) return _announcements;
    return _announcements.where((announcement) {
      final title = (announcement['title'] ?? '').toLowerCase();
      final content = (announcement['content'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || content.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search announcements...',
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
      floatingActionButton: authProvider.canManageAnnouncements
          ? FloatingActionButton(
              onPressed: _showCreateAnnouncementDialog,
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
              'Error loading announcements',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnnouncements,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredAnnouncements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              _announcements.isEmpty
                  ? 'No announcements found'
                  : 'No announcements match your search',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _announcements.isEmpty
                  ? 'Announcements will appear here when created'
                  : 'Try adjusting your search criteria',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredAnnouncements.length,
        itemBuilder: (context, index) {
          final announcement = _filteredAnnouncements[index];
          return _buildAnnouncementCard(announcement, authProvider);
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(
    Map<String, dynamic> announcement,
    AuthProvider authProvider,
  ) {
    final createdAt = DateTime.tryParse(announcement['created_at'] ?? '');
    final priority = announcement['priority'] ?? 'medium';

    Color priorityColor;
    IconData priorityIcon;

    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityIcon = Icons.info;
        break;
      case 'low':
      default:
        priorityColor = Colors.green;
        priorityIcon = Icons.info_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAnnouncementDetails(announcement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(priorityIcon, color: priorityColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      announcement['title'] ?? 'No Title',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (authProvider.canManageAnnouncements) ...[
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditAnnouncementDialog(announcement);
                            break;
                          case 'delete':
                            _showDeleteAnnouncementDialog(announcement);
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
              if (announcement['content'] != null) ...[
                Text(
                  announcement['content'],
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: priorityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (createdAt != null) ...[
                    Text(
                      '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
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

  void _showAnnouncementDetails(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement['title'] ?? 'Announcement Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (announcement['content'] != null) ...[
                const Text(
                  'Content:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(announcement['content']),
                const SizedBox(height: 16),
              ],
              if (announcement['priority'] != null) ...[
                const Text(
                  'Priority:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(announcement['priority'].toString().toUpperCase()),
                const SizedBox(height: 16),
              ],
              if (announcement['target_audience'] != null) ...[
                const Text(
                  'Target Audience:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(announcement['target_audience']),
                const SizedBox(height: 16),
              ],
              if (announcement['created_by_name'] != null) ...[
                const Text(
                  'Created by:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(announcement['created_by_name']),
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

  void _showCreateAnnouncementDialog() {
    showDialog(
      context: context,
      builder: (context) => _AnnouncementFormDialog(
        onAnnouncementSaved: () => _loadAnnouncements(),
      ),
    );
  }

  void _showEditAnnouncementDialog(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => _AnnouncementFormDialog(
        announcement: announcement,
        onAnnouncementSaved: () => _loadAnnouncements(),
      ),
    );
  }

  void _showDeleteAnnouncementDialog(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text(
          'Are you sure you want to delete "${announcement['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAnnouncement(announcement['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnouncement(int announcementId) async {
    try {
      await ApiService.delete('/announcements/$announcementId');
      _loadAnnouncements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting announcement: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _AnnouncementFormDialog extends StatefulWidget {
  final Map<String, dynamic>? announcement;
  final VoidCallback onAnnouncementSaved;

  const _AnnouncementFormDialog({
    this.announcement,
    required this.onAnnouncementSaved,
  });

  @override
  State<_AnnouncementFormDialog> createState() =>
      _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<_AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  String _priority = 'normal';
  String _visibility = 'all';
  int? _selectedBranchId;
  int? _selectedMCId;

  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _mcs = [];

  bool _isLoading = false;

  final List<String> _priorityOptions = ['low', 'normal', 'high', 'urgent'];
  final List<String> _visibilityOptions = ['all', 'branch', 'mc'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadBranches();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(
      text: widget.announcement?['title'] ?? '',
    );
    _contentController = TextEditingController(
      text: widget.announcement?['content'] ?? '',
    );

    if (widget.announcement != null) {
      _priority = widget.announcement!['priority'] ?? 'normal';
      _visibility = widget.announcement!['visibility'] ?? 'all';
      _selectedBranchId = widget.announcement!['branch_id'] as int?;
      _selectedMCId = widget.announcement!['mc_id'] as int?;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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
      final response = await ApiService.getMCs(branchId: _selectedBranchId);
      setState(() {
        _mcs = List<Map<String, dynamic>>.from(response['mcs'] ?? []);
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final announcementData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'priority': _priority,
        'visibility': _visibility,
        'branch_id': _visibility == 'branch' ? _selectedBranchId : null,
        'mc_id': _visibility == 'mc' ? _selectedMCId : null,
      };

      if (widget.announcement != null) {
        // Update existing announcement
        await ApiService.put(
          '/announcements/${widget.announcement!['id']}',
          data: announcementData,
        );
      } else {
        // Create new announcement
        await ApiService.post('/announcements', data: announcementData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Announcement ${widget.announcement != null ? 'updated' : 'created'} successfully',
            ),
          ),
        );
        widget.onAnnouncementSaved();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${widget.announcement != null ? 'updating' : 'creating'} announcement: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getPriorityDisplayName(String priority) {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'normal':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
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
    final isEditing = widget.announcement != null;

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
                    isEditing ? Icons.edit : Icons.campaign,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Announcement' : 'Create Announcement',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                          labelText: 'Announcement Title *',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter announcement title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Content Field
                      TextFormField(
                        controller: _contentController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Content *',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter announcement content';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Priority Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority *',
                          prefixIcon: Icon(Icons.flag),
                          border: OutlineInputBorder(),
                        ),
                        items: _priorityOptions
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(priority),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_getPriorityDisplayName(priority)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _priority = value!),
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
                      onPressed: _isLoading ? null : _saveAnnouncement,
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEditing
                                  ? 'Update Announcement'
                                  : 'Create Announcement',
                            ),
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
