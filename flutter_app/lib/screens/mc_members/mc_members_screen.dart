import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class MCMembersScreen extends StatefulWidget {
  const MCMembersScreen({super.key});

  @override
  State<MCMembersScreen> createState() => _MCMembersScreenState();
}

class _MCMembersScreenState extends State<MCMembersScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _mcData;

  @override
  void initState() {
    super.initState();
    _loadMCMembers();
  }

  Future<void> _loadMCMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final mcId = authProvider.userMCId;

      if (mcId != null) {
        final response = await ApiService.getMC(mcId);
        final mcData = response['mc'];

        setState(() {
          _mcData = mcData;
          _members = List<Map<String, dynamic>>.from(mcData['members'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'You are not assigned to any Missional Community';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addMember() async {
    final emailController = TextEditingController();
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add MC Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the email address of the user you want to add to this MC:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'user@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (emailController.text.trim().isEmpty) {
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final authProvider = context.read<AuthProvider>();
                        final mcId = authProvider.userMCId!;

                        await ApiService.post(
                          '/mcs/$mcId/members',
                          data: {'email': emailController.text.trim()},
                        );

                        Navigator.of(context).pop(true);
                      } catch (e) {
                        String errorMessage = 'Failed to add member: $e';

                        // Check if it's an email validation error
                        if (e.toString().contains(
                              'selected email is invalid',
                            ) ||
                            e.toString().contains('email') &&
                                e.toString().contains('422')) {
                          errorMessage =
                              'User with email "${emailController.text.trim()}" is not registered in the system. Please ask them to register first or verify the email address.';
                        } else if (e.toString().contains('already assigned')) {
                          errorMessage =
                              'This user is already assigned to another MC.';
                        } else if (e.toString().contains('same branch')) {
                          errorMessage =
                              'User must belong to the same branch as this MC.';
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadMCMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member['name']} from this MC?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authProvider = context.read<AuthProvider>();
        final mcId = authProvider.userMCId!;

        await ApiService.delete('/mcs/$mcId/members/${member['id']}');

        _loadMCMembers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _mcData != null ? '${_mcData!['name']} Members' : 'MC Members',
        ),
        elevation: 0,
      ),
      body: _buildBody(),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Only MC Leaders can add members
          if (authProvider.isMCLeader) {
            return FloatingActionButton(
              onPressed: _addMember,
              child: const Icon(Icons.person_add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMCMembers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No members found in this MC',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Members will appear here once they are added to the MC',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMCMembers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          return _buildMemberCard(member);
        },
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isCurrentUser = member['id'] == authProvider.userId;
        final canRemove = authProvider.isMCLeader && !isCurrentUser;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                member['name']?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              member['name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['email'] ?? ''),
                if (member['role'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Role: ${member['role']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                if (isCurrentUser) ...[
                  const SizedBox(height: 2),
                  Text(
                    'You',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            trailing: canRemove
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                    onPressed: () => _removeMember(member),
                    tooltip: 'Remove from MC',
                  )
                : null,
          ),
        );
      },
    );
  }
}
