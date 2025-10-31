import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class MCMembersDialog extends StatefulWidget {
  final Map<String, dynamic> mc;

  const MCMembersDialog({super.key, required this.mc});

  @override
  State<MCMembersDialog> createState() => _MCMembersDialogState();
}

class _MCMembersDialogState extends State<MCMembersDialog> {
  // ApiService is static, no need to instantiate
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _availableUsers = [];
  Map<String, dynamic>? _selectedUser;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMCData();
  }

  Future<void> _loadMCData() async {
    try {
      // Load MC members
      final membersResponse = await ApiService.get(
        '/mcs/${widget.mc['id']}/members',
      );

      // Load available users (users not in this MC)
      final usersResponse = await ApiService.get('/users');

      if (membersResponse['success'] == true &&
          usersResponse['success'] == true) {
        final allUsers = List<Map<String, dynamic>>.from(
          usersResponse['data'] ?? [],
        );
        final mcMembers = List<Map<String, dynamic>>.from(
          membersResponse['data'] ?? [],
        );

        // Filter available users (exclude current MC members)
        final memberIds = mcMembers.map((member) => member['id']).toSet();
        final availableUsers = allUsers
            .where((user) => !memberIds.contains(user['id']))
            .toList();

        setState(() {
          _members = mcMembers;
          _availableUsers = availableUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading MC data: $e')));
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addUserToMC() async {
    if (_selectedUser == null) return;

    try {
      final response = await ApiService.post(
        '/mcs/${widget.mc['id']}/add-member',
        data: {'user_id': _selectedUser!['id']},
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User added to MC successfully')),
          );
          _loadMCData(); // Refresh the data
          setState(() {
            _selectedUser = null;
          });
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to add user to MC');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding user: $e')));
      }
    }
  }

  Future<void> _removeUserFromMC(Map<String, dynamic> user) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Remove'),
        content: Text(
          'Are you sure you want to remove ${user['name']} from this MC?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.post(
        '/mcs/${widget.mc['id']}/remove-member',
        data: {'user_id': user['id']},
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User removed from MC successfully')),
          );
          _loadMCData(); // Refresh the data
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to remove user from MC');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing user: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;
    return _members.where((member) {
      final name = member['name']?.toString().toLowerCase() ?? '';
      final email = member['email']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredAvailableUsers {
    if (_searchQuery.isEmpty) return _availableUsers;
    return _availableUsers.where((user) {
      final name = user['name']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.group, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Manage MC Members',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'MC: ${widget.mc['name']}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const Divider(),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else ...[
              // Add member section
              if (authProvider.canManageMCs) ...[
                Text(
                  'Add Member',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Map<String, dynamic>>(
                        initialValue: _selectedUser,
                        hint: const Text('Select a user to add'),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _filteredAvailableUsers.map((user) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: user,
                            child: Text('${user['name']} (${user['email']})'),
                          );
                        }).toList(),
                        onChanged: (user) {
                          setState(() {
                            _selectedUser = user;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectedUser != null ? _addUserToMC : null,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
              ],

              // Search bar
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search members...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Members list
              Text(
                'Current Members (${_members.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No members in this MC yet'
                                  : 'No members found matching "$_searchQuery"',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                child: Text(
                                  member['name']
                                          ?.toString()
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(member['name'] ?? 'Unknown'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member['email'] ?? ''),
                                  if (member['role'] != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(member['role']),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        member['role']
                                                ?.toString()
                                                .toUpperCase() ??
                                            '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: authProvider.canManageMCs
                                  ? IconButton(
                                      onPressed: () =>
                                          _removeUserFromMC(member),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Remove from MC',
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ),

              // Close button
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'super_admin':
        return Colors.purple;
      case 'branch_admin':
        return Colors.blue;
      case 'mc_leader':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
