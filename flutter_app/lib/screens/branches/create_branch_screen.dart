import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../core/services/api_service.dart';

class CreateBranchScreen extends StatefulWidget {
  final Map<String, dynamic>? existingBranch;
  final bool isEditing;

  const CreateBranchScreen({
    super.key,
    this.existingBranch,
    this.isEditing = false,
  });

  @override
  State<CreateBranchScreen> createState() => _CreateBranchScreenState();
}

class _CreateBranchScreenState extends State<CreateBranchScreen> {
  static final Logger _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _contactPhoneController;

  // Form values
  bool _isActive = true;
  int? _selectedLeaderId;
  List<Map<String, dynamic>> _availableUsers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.isEditing && widget.existingBranch != null) {
      _loadExistingBranch();
    }
    _loadAvailableUsers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();
    _contactEmailController = TextEditingController();
    _contactPhoneController = TextEditingController();
  }

  void _loadExistingBranch() {
    final branch = widget.existingBranch!;
    _nameController.text = branch['name'] ?? '';
    _locationController.text = branch['location'] ?? '';
    _descriptionController.text = branch['description'] ?? '';
    _contactEmailController.text = branch['contact_email'] ?? '';
    _contactPhoneController.text = branch['contact_phone'] ?? '';
    _isActive = branch['is_active'] ?? true;
    _selectedLeaderId = branch['admin_id'];
  }

  Future<void> _loadAvailableUsers() async {
    try {
      final response = await ApiService.get('/users');
      final users = List<Map<String, dynamic>>.from(response['users'] ?? []);

      // Filter users who can be promoted to branch leaders
      // (exclude super_admin and existing branch_admin, but include current admin when editing)
      setState(() {
        _availableUsers = users.where((user) {
          final role = user['role'];
          final userId = user['id'];

          // Always exclude super_admin
          if (role == 'super_admin') return false;

          // When editing, include the current admin even if they're branch_admin
          if (widget.isEditing && _selectedLeaderId != null) {
            // Handle type conversion for comparison
            final userIdInt = userId is int
                ? userId
                : int.tryParse(userId.toString());
            final selectedIdInt = _selectedLeaderId is int
                ? _selectedLeaderId
                : int.tryParse(_selectedLeaderId.toString());
            if (userIdInt == selectedIdInt) {
              return true;
            }
          }

          // Otherwise, exclude existing branch_admin users
          return role != 'branch_admin';
        }).toList();
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Branch' : 'Create Branch'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveBranch,
            child: Text(widget.isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Branch Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                        helperText: 'Enter the name of the branch',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Branch name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Branch name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                        helperText: 'Physical location or address',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Location is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        helperText:
                            'Brief description of the branch (optional)',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Leadership Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leadership',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedLeaderId,
                      decoration: InputDecoration(
                        labelText: 'Branch Leader',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                        helperText: _availableUsers.isNotEmpty
                            ? '${_availableUsers.length} users available (role will be updated to Branch Admin)'
                            : 'No users available for branch leadership',
                      ),
                      items: [
                        DropdownMenuItem<int>(
                          value: null,
                          child: Text(
                            _availableUsers.isEmpty
                                ? 'No users available'
                                : 'No Leader Assigned',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        ..._availableUsers.map((user) {
                          final userId = user['id'];
                          final id = userId is int
                              ? userId
                              : int.tryParse(userId.toString());
                          return DropdownMenuItem<int>(
                            value: id,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 200,
                                maxHeight: 50,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user['name'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Flexible(
                                      child: Text(
                                        '${user['email']} (${user['role']})',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLeaderId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contact Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                        helperText: 'Branch contact email (optional)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        helperText: 'Branch contact phone (optional)',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active Branch'),
                      subtitle: Text(
                        _isActive
                            ? 'This branch is active and operational'
                            : 'This branch is inactive',
                      ),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveBranch,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.isEditing
                                ? 'Update Branch'
                                : 'Create Branch',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBranch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final branchData = {
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'contact_email': _contactEmailController.text.trim().isEmpty
            ? null
            : _contactEmailController.text.trim(),
        'contact_phone': _contactPhoneController.text.trim().isEmpty
            ? null
            : _contactPhoneController.text.trim(),
        'admin_id': _selectedLeaderId,
        'is_active': _isActive,
      };

      // Update the selected user's role and clear branch assignment if a leader is selected
      if (_selectedLeaderId != null) {
        try {
          await ApiService.put(
            '/users/$_selectedLeaderId',
            data: {
              'role': 'branch_admin',
              'branch_id': null, // Clear current branch assignment
            },
          );
        } catch (e) {
          // Log the error but don't fail the branch creation/update
          _logger.w('Warning: Could not update user for branch leadership: $e');
        }
      }

      if (widget.isEditing) {
        await ApiService.put(
          '/branches/${widget.existingBranch!['id']}',
          data: branchData,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Branch updated successfully')),
          );
        }
      } else {
        await ApiService.post('/branches', data: branchData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Branch created successfully')),
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
            content: Text('Error saving branch: $e'),
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
