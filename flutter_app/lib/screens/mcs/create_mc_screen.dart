import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../core/services/api_service.dart';

class CreateMCScreen extends StatefulWidget {
  final Map<String, dynamic>? existingMC;
  final bool isEditing;

  const CreateMCScreen({super.key, this.existingMC, this.isEditing = false});

  @override
  State<CreateMCScreen> createState() => _CreateMCScreenState();
}

class _CreateMCScreenState extends State<CreateMCScreen> {
  static final Logger _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _visionController;
  late final TextEditingController _goalsController;
  late final TextEditingController _purposeController;
  late final TextEditingController _locationController;
  late final TextEditingController _leaderPhoneController;

  // Form values
  bool _isActive = true;
  int? _selectedBranchId;
  int? _selectedLeaderId;
  List<Map<String, dynamic>> _availableBranches = [];
  List<Map<String, dynamic>> _availableUsers = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _visionController = TextEditingController();
    _goalsController = TextEditingController();
    _purposeController = TextEditingController();
    _locationController = TextEditingController();
    _leaderPhoneController = TextEditingController();
  }

  void _loadExistingMC() {
    final mc = widget.existingMC!;
    _nameController.text = mc['name'] ?? '';
    _visionController.text = mc['vision'] ?? '';
    _goalsController.text = mc['goals'] ?? '';
    _purposeController.text = mc['purpose'] ?? '';
    _locationController.text = mc['location'] ?? '';
    _leaderPhoneController.text = mc['leader_phone'] ?? '';
    _isActive = mc['is_active'] ?? true;

    // Handle both String and int types for IDs
    final branchId = mc['branch_id'];
    _selectedBranchId = branchId is int
        ? branchId
        : int.tryParse(branchId?.toString() ?? '');

    final leaderId = mc['leader_id'];
    _selectedLeaderId = leaderId is int
        ? leaderId
        : int.tryParse(leaderId?.toString() ?? '');

    // If we have branch data in the MC object, ensure it's available in the branches list
    final mcBranch = mc['branch'];
    if (mcBranch != null && _selectedBranchId != null) {
      // Check if the MC's branch is already in our branches list
      final branchExists = _availableBranches.any((branch) {
        final id = branch['id'] is int
            ? branch['id']
            : int.tryParse(branch['id']?.toString() ?? '');
        return id == _selectedBranchId;
      });

      // If the branch doesn't exist in our list, add it
      if (!branchExists && mcBranch is Map<String, dynamic>) {
        setState(() {
          _availableBranches.add({
            'id': _selectedBranchId,
            'name': mcBranch['name'] ?? 'Unknown Branch',
            'is_active': mcBranch['is_active'] ?? true,
          });
        });
      }
    }
  }

  Future<void> _loadData() async {
    // Load branches first, then users (branches loading will handle existing MC data)
    await _loadBranches();
    await _loadAvailableUsers();
  }

  Future<void> _loadBranches() async {
    try {
      final response = await ApiService.get('/branches');
      setState(() {
        _availableBranches = List<Map<String, dynamic>>.from(
          response['branches'] ?? [],
        );
      });

      // Handle default branch selection for new MCs
      if (!widget.isEditing &&
          _selectedBranchId == null &&
          _availableBranches.isNotEmpty) {
        // Find "Divine Life- HQ" branch and set as default
        final hqBranch = _availableBranches.firstWhere(
          (branch) =>
              branch['name']?.toString().contains('Divine Life- HQ') == true,
          orElse: () => _availableBranches
              .first, // Fallback to first branch if HQ not found
        );

        final branchId = hqBranch['id'];
        setState(() {
          _selectedBranchId = branchId is int
              ? branchId
              : int.tryParse(branchId?.toString() ?? '');
        });

        // Load users for the default branch
        _loadAvailableUsers();
      }
      // For editing, ensure the MC's current branch is available and properly selected
      else if (widget.isEditing && widget.existingMC != null) {
        _loadExistingMC(); // Reload existing MC data to ensure branch is properly set
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _loadAvailableUsers() async {
    try {
      final response = await ApiService.get('/users');
      final users = List<Map<String, dynamic>>.from(response['users'] ?? []);

      _logger.d('=== Loading available users ===');
      _logger.d(
        'Selected branch ID: $_selectedBranchId (type: ${_selectedBranchId.runtimeType})',
      );
      _logger.d('Total users loaded: ${users.length}');

      // Filter users who belong to selected branch (any user can become MC leader)
      setState(() {
        _availableUsers = users.where((user) {
          final role = user['role'];
          final userBranchId = user['branch_id'];

          // If no branch selected, show no users (branch must be selected first)
          if (_selectedBranchId == null) return false;

          // If branch selected, show all users from that branch
          // Handle both string and integer comparisons for branch_id
          bool belongsToSelectedBranch = false;
          if (userBranchId != null && _selectedBranchId != null) {
            if (userBranchId is int && _selectedBranchId is int) {
              belongsToSelectedBranch = userBranchId == _selectedBranchId;
            } else {
              // Convert both to strings for comparison
              belongsToSelectedBranch =
                  userBranchId.toString() == _selectedBranchId.toString();
            }
          }

          final result = belongsToSelectedBranch;

          // Debug logging for first few users
          if (users.indexOf(user) < 3) {
            _logger.d('User: ${user['first_name']} ${user['last_name']}');
            _logger.d('  Role: $role');
            _logger.d(
              '  Branch ID: $userBranchId (type: ${userBranchId.runtimeType})',
            );
            _logger.d('  Belongs to selected branch: $belongsToSelectedBranch');
            _logger.d('  Final result: $result');
            _logger.d('---');
          }

          return result;
        }).toList();

        _logger.d('Filtered available users: ${_availableUsers.length}');
        _logger.d('===========================');
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _visionController.dispose();
    _goalsController.dispose();
    _purposeController.dispose();
    _locationController.dispose();
    _leaderPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit MC' : 'Create MC'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveMC,
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
                        labelText: 'MC Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                        helperText: 'Enter the name of the Missional Community',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'MC name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'MC name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Branch *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                        helperText: 'Select the branch this MC belongs to',
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a branch';
                        }
                        return null;
                      },
                      items: _availableBranches.map((branch) {
                        final branchId = branch['id'];
                        final id = branchId is int
                            ? branchId
                            : int.tryParse(branchId.toString());
                        return DropdownMenuItem<int>(
                          value: id,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 220,
                              maxHeight: 30,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                branch['name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBranchId = value;
                          _selectedLeaderId =
                              null; // Reset leader when branch changes
                        });
                        // Reload users for the selected branch
                        _loadAvailableUsers();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                        helperText: 'Meeting location or area of focus',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Vision & Purpose Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vision & Purpose',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _visionController,
                      decoration: const InputDecoration(
                        labelText: 'Vision Statement',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        helperText: 'What is the vision for this MC?',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _purposeController,
                      decoration: const InputDecoration(
                        labelText: 'Purpose',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        helperText: 'What is the main purpose of this MC?',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _goalsController,
                      decoration: const InputDecoration(
                        labelText: 'Goals',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        helperText: 'What are the specific goals?',
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
                        labelText: 'MC Leader',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                        helperText: _selectedBranchId != null
                            ? '${_availableUsers.length} users available (role will be updated)'
                            : 'Select branch first',
                      ),
                      items: [
                        DropdownMenuItem<int>(
                          value: null,
                          child: Text(
                            _availableUsers.isEmpty && _selectedBranchId != null
                                ? 'No users in branch'
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _leaderPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Leader Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        helperText: 'Contact phone for the MC leader',
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
                      title: const Text('Active MC'),
                      subtitle: Text(
                        _isActive
                            ? 'This MC is active and operational'
                            : 'This MC is inactive',
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
                    onPressed: _isLoading ? null : _saveMC,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isEditing ? 'Update MC' : 'Create MC'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMC() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final mcData = {
        'name': _nameController.text.trim(),
        'vision': _visionController.text.trim().isEmpty
            ? null
            : _visionController.text.trim(),
        'goals': _goalsController.text.trim().isEmpty
            ? null
            : _goalsController.text.trim(),
        'purpose': _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'leader_phone': _leaderPhoneController.text.trim().isEmpty
            ? null
            : _leaderPhoneController.text.trim(),
        'branch_id': _selectedBranchId,
        'leader_id': _selectedLeaderId,
        'is_active': _isActive,
      };

      // Update the selected user's role to mc_leader if a leader is selected
      if (_selectedLeaderId != null) {
        try {
          await ApiService.put(
            '/users/$_selectedLeaderId',
            data: {'role': 'mc_leader'},
          );
        } catch (e) {
          // Log the error but don't fail the MC creation/update
          _logger.w('Warning: Could not update user role to mc_leader: $e');
        }
      }

      if (widget.isEditing) {
        await ApiService.put('/mcs/${widget.existingMC!['id']}', data: mcData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MC updated successfully')),
          );
        }
      } else {
        await ApiService.post('/mcs', data: mcData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MC created successfully')),
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
            content: Text('Error saving MC: $e'),
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
