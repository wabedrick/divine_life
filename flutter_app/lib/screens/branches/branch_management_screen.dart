import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import 'create_branch_screen.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/branches');
      _branches = List<Map<String, dynamic>>.from(
        response['branches'] ?? [],
      ); // Backend returns 'branches' key
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

  List<Map<String, dynamic>> get _filteredBranches {
    if (_searchQuery.isEmpty) return _branches;

    return _branches.where((branch) {
      final name = (branch['name'] ?? '').toString().toLowerCase();
      final location = (branch['location'] ?? '').toString().toLowerCase();
      final leader = (branch['leader']?['name'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          location.contains(query) ||
          leader.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBranches),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search branches...',
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
                });
              },
            ),
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
                    onPressed: _loadBranches,
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBranchesList(),
          ),
        ],
      ),
      floatingActionButton: authProvider.canManageBranches
          ? FloatingActionButton.extended(
              onPressed: _showCreateBranchDialog,
              icon: const Icon(Icons.add_location),
              label: const Text('New Branch'),
            )
          : null,
    );
  }

  Widget _buildBranchesList() {
    if (_filteredBranches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city_outlined,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No branches found' : 'No branches yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search criteria'
                  : 'Start by creating your first branch',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBranches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredBranches.length,
        itemBuilder: (context, index) {
          final branch = _filteredBranches[index];
          return _buildBranchCard(branch);
        },
      ),
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch) {
    final name = branch['name'] ?? '';
    final location = branch['location'] ?? '';
    final leaderName = branch['leader']?['name'] ?? 'No Leader';
    final memberCount = branch['member_count'] ?? 0;
    final mcCount = branch['mc_count'] ?? 0;
    final isActive = branch['is_active'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showBranchDetails(branch),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Leader: $leaderName',
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleBranchAction(value, branch),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('View Details'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'members',
                        child: ListTile(
                          leading: Icon(Icons.people),
                          title: Text('Manage Members'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reports',
                        child: ListTile(
                          leading: Icon(Icons.analytics),
                          title: Text('View Reports'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Statistics Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.people,
                      label: 'Members',
                      value: memberCount.toString(),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.groups,
                      label: 'MCs',
                      value: mcCount.toString(),
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.calendar_today,
                      label: 'Established',
                      value: branch['created_at'] != null
                          ? DateTime.parse(branch['created_at']).year.toString()
                          : 'N/A',
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _handleBranchAction(String action, Map<String, dynamic> branch) {
    switch (action) {
      case 'view':
        _showBranchDetails(branch);
        break;
      case 'members':
        _manageBranchMembers(branch);
        break;
      case 'edit':
        _editBranch(branch);
        break;
      case 'reports':
        _viewBranchReports(branch);
        break;
    }
  }

  void _showBranchDetails(Map<String, dynamic> branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(branch['name'] ?? ''),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Location', branch['location']),
              _buildDetailRow(
                'Leader',
                branch['leader']?['name'] ?? 'No Leader',
              ),
              _buildDetailRow(
                'Phone',
                branch['leader']?['phone_number'] ?? 'N/A',
              ),
              _buildDetailRow(
                'Members',
                branch['member_count']?.toString() ?? '0',
              ),
              _buildDetailRow('MCs', branch['mc_count']?.toString() ?? '0'),
              _buildDetailRow(
                'Status',
                branch['is_active'] ? 'Active' : 'Inactive',
              ),
              if (branch['description'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(branch['description']),
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

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  void _showCreateBranchDialog() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CreateBranchScreen()));
    if (result == true) {
      _loadBranches();
    }
  }

  void _editBranch(Map<String, dynamic> branch) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CreateBranchScreen(existingBranch: branch, isEditing: true),
      ),
    );
    if (result == true) {
      _loadBranches();
    }
  }

  void _manageBranchMembers(Map<String, dynamic> branch) {
    showDialog(
      context: context,
      builder: (context) => _BranchMembersDialog(
        branch: branch,
        onMembersUpdated: () => _loadBranches(),
      ),
    );
  }

  void _viewBranchReports(Map<String, dynamic> branch) {
    // TODO: Navigate to branch reports screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing reports for ${branch['name']}')),
    );
  }
}

class _BranchMembersDialog extends StatefulWidget {
  final Map<String, dynamic> branch;
  final VoidCallback onMembersUpdated;

  const _BranchMembersDialog({
    required this.branch,
    required this.onMembersUpdated,
  });

  @override
  State<_BranchMembersDialog> createState() => _BranchMembersDialogState();
}

class _BranchMembersDialogState extends State<_BranchMembersDialog> {
  List<Map<String, dynamic>> _branchMembers = [];
  List<Map<String, dynamic>> _availableUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBranchMembers();
    _loadAvailableUsers();
  }

  Future<void> _loadBranchMembers() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(
        '/branches/${widget.branch['id']}/users',
      );
      setState(() {
        _branchMembers = List<Map<String, dynamic>>.from(
          response['data'] ?? [],
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAvailableUsers() async {
    try {
      // Load users without a branch or with different branch
      final response = await ApiService.get(
        '/users',
        queryParameters: {
          'branch_id': 'null_or_different',
          'exclude_branch': widget.branch['id'].toString(),
        },
      );
      setState(() {
        _availableUsers = List<Map<String, dynamic>>.from(
          response['data'] ?? [],
        );
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _addUserToBranch(int userId) async {
    try {
      await ApiService.put(
        '/users/$userId',
        data: {'branch_id': widget.branch['id']},
      );

      await _loadBranchMembers();
      await _loadAvailableUsers();
      widget.onMembersUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added to branch successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding user to branch: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeUserFromBranch(int userId, String userName) async {
    try {
      await ApiService.put(
        '/users/$userId',
        data: {
          'branch_id': null,
          'mc_id': null, // Also remove from MC when removing from branch
        },
      );

      await _loadBranchMembers();
      await _loadAvailableUsers();
      widget.onMembersUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName removed from branch')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing user from branch: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showRemoveConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${user['name']} from ${widget.branch['name']}? This will also remove them from any MC in this branch.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeUserFromBranch(user['id'], user['name']);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    if (_availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available users to add')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _getFilteredAvailableUsers().length,
                  itemBuilder: (context, index) {
                    final user = _getFilteredAvailableUsers()[index];
                    return ListTile(
                      title: Text(user['name'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'] ?? ''),
                          Text(
                            'Role: ${user['role']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'N/A'}',
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _addUserToBranch(user['id']);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredAvailableUsers() {
    if (_searchQuery.isEmpty) return _availableUsers;

    return _availableUsers.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || email.contains(query);
    }).toList();
  }

  String _getRoleDisplayName(String? role) {
    if (role == null) return 'Member';
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
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
                    Icons.people,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Branch Members',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          widget.branch['name'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
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

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Add Member Button
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showAddMemberDialog,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Member'),
                            ),
                          ),
                        ),

                        // Members List
                        Expanded(
                          child: _branchMembers.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text('No members in this branch'),
                                      Text('Add members to get started'),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: _branchMembers.length,
                                  itemBuilder: (context, index) {
                                    final member = _branchMembers[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          child: Text(
                                            (member['name'] ?? '?')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(member['name'] ?? ''),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(member['email'] ?? ''),
                                            Text(
                                              'Role: ${_getRoleDisplayName(member['role'])}',
                                            ),
                                            if (member['mc'] != null)
                                              Text(
                                                'MC: ${member['mc']['name'] ?? 'N/A'}',
                                              ),
                                          ],
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'remove') {
                                              _showRemoveConfirmation(member);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'remove',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.remove_circle,
                                                  color: Colors.red,
                                                ),
                                                title: Text(
                                                  'Remove from Branch',
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Total Members: ${_branchMembers.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
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
