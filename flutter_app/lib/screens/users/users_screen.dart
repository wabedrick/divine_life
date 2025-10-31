import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Helper function to get user's full name from different field structures
  String _getUserName(Map<String, dynamic> user) {
    // Backend returns single 'name' field
    if (user['name'] != null && user['name'].toString().isNotEmpty) {
      return user['name'].toString();
    }
    // Fallback for separate first_name/last_name fields
    final firstName = user['first_name']?.toString() ?? '';
    final lastName = user['last_name']?.toString() ?? '';
    return '$firstName $lastName'.trim();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all users
      final allUsersResponse = await ApiService.getUsers();
      // Load pending users
      final pendingUsersResponse = await ApiService.get('/users/pending');

      setState(() {
        _allUsers = List<Map<String, dynamic>>.from(
          allUsersResponse['users'] ??
              [], // Backend returns 'users' key, not 'data'
        );
        _pendingUsers = List<Map<String, dynamic>>.from(
          pendingUsersResponse['pending_users'] ??
              [], // Backend returns 'pending_users' key
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

  List<Map<String, dynamic>> _getFilteredUsers(
    List<Map<String, dynamic>> users,
  ) {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      final name = _getUserName(user).toLowerCase();
      final email = (user['email'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.canManageUsers) {
      return Scaffold(
        appBar: AppBar(title: const Text('Users')),
        body: const Center(
          child: Text('You do not have permission to manage users.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'All Users (${_allUsers.length})',
              icon: const Icon(Icons.people),
            ),
            Tab(
              text: 'Pending (${_pendingUsers.length})',
              icon: const Icon(Icons.pending_actions),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
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
                    onPressed: _loadUsers,
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUsersList(_getFilteredUsers(_allUsers), false),
                      _buildUsersList(_getFilteredUsers(_pendingUsers), true),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }

  Widget _buildUsersList(List<Map<String, dynamic>> users, bool isPending) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.pending_actions : Icons.people_outline,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending users' : 'No users found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'New user registrations will appear here'
                  : 'Start by adding your first user',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user, isPending);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isPending) {
    final name = _getUserName(user);
    final email = user['email'] ?? '';
    final role = user['role'] ?? '';
    final status = user['status'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleDisplayName(role),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getRoleColor(role),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
          onSelected: (value) => _handleUserAction(value, user),
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
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (status == 'active')
                const PopupMenuItem(
                  value: 'deactivate',
                  child: ListTile(
                    leading: Icon(Icons.block, color: Colors.orange),
                    title: Text('Deactivate'),
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'activate',
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Activate'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'branch_admin':
        return Colors.blue;
      case 'mc_leader':
        return Colors.green;
      case 'member':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'branch_admin':
        return 'Branch Admin';
      case 'mc_leader':
        return 'MC Leader';
      case 'member':
        return 'Member';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _handleUserAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'approve':
        _approveUser(user['id']);
        break;
      case 'reject':
        _rejectUser(user['id']);
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserStatus(user['id'], action == 'activate');
        break;
      case 'delete':
        _showDeleteConfirmation(user);
        break;
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        _getUserInitials(user),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getUserName(user),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user['role'] ?? 'member'),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleDisplayName(user['role']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          'Email',
                          user['email'] ?? 'N/A',
                          Icons.email_outlined,
                        ),
                        _buildDetailRow(
                          'Phone Number',
                          user['phone'] ?? user['phone_number'] ?? 'N/A',
                          Icons.phone_outlined,
                        ),
                        _buildDetailRow(
                          'Role',
                          _getRoleDisplayName(user['role']),
                          Icons.person_outline,
                        ),
                        _buildDetailRow(
                          'Status',
                          (user['status']?.toString().toUpperCase() ?? 'N/A'),
                          Icons.info_outline,
                        ),
                        _buildDetailRow(
                          'Branch Name',
                          user['branch_name'] ??
                              user['branch']?['name'] ??
                              'N/A',
                          Icons.location_city_outlined,
                        ),
                        _buildDetailRow(
                          'MC Name',
                          user['mc_name'] ?? user['mc']?['name'] ?? 'N/A',
                          Icons.group_outlined,
                        ),
                        _buildDetailRow(
                          'Gender',
                          user['gender']?.toString().toUpperCase() ?? 'N/A',
                          Icons.person_4_outlined,
                        ),
                        _buildDetailRow(
                          'Birth Date',
                          _formatBirthDate(user['birth_date']),
                          Icons.cake_outlined,
                        ),
                        _buildDetailRow(
                          'Date Joined',
                          _formatDate(user['created_at']),
                          Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Action buttons row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showEditUserDialog(user);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showDeleteConfirmation(user);
                            },
                            icon: const Icon(Icons.person_remove_outlined),
                            label: const Text('Deactivate'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getUserInitials(Map<String, dynamic> user) {
    String name = _getUserName(user);
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatBirthDate(dynamic birthDate) {
    if (birthDate == null) return 'N/A';

    try {
      DateTime date = DateTime.parse(birthDate.toString());
      List<String> months = [
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
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return birthDate.toString();
    }
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'N/A';

    try {
      DateTime date = DateTime.parse(dateString.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString.toString();
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddUserDialog(onUserCreated: () => _loadUsers()),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) async {
    try {
      // Validate user data before opening dialog
      if (user.isEmpty || user['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid user data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            _EditUserDialog(user: user, onUserUpdated: () => _loadUsers()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening edit dialog: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveUser(int userId) async {
    try {
      await ApiService.put(
        '/users/$userId/approval-status',
        data: {'is_approved': true},
      );
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving user: $e')));
      }
    }
  }

  Future<void> _rejectUser(int userId) async {
    try {
      await ApiService.put(
        '/users/$userId/approval-status',
        data: {
          'is_approved': false,
          'rejection_reason': 'Application rejected by administrator',
        },
      );
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting user: $e')));
      }
    }
  }

  Future<void> _toggleUserStatus(int userId, bool activate) async {
    try {
      await ApiService.put(
        '/users/$userId/approval-status',
        data: {'is_approved': activate},
      );
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${activate ? 'activated' : 'deactivated'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user status: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text(
          'Are you sure you want to deactivate ${_getUserName(user)}? The user will be marked as inactive but can be reactivated later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _softDeleteUser(user['id']);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  Future<void> _softDeleteUser(int userId) async {
    try {
      // Soft delete by setting approved to false
      await ApiService.put(
        '/users/$userId/approval-status',
        data: {
          'is_approved': false,
          'rejection_reason': 'Account deactivated by administrator',
        },
      );
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deactivated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deactivating user: $e')));
      }
    }
  }
}

class _AddUserDialog extends StatefulWidget {
  final VoidCallback onUserCreated;

  const _AddUserDialog({required this.onUserCreated});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'member';
  int? _selectedBranchId;
  int? _selectedMCId;
  String? _selectedGender;
  DateTime? _birthDate;

  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _mcs = [];

  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _roles = [
    'member',
    'mc_leader',
    'branch_admin',
    'super_admin',
  ];
  final List<String> _genders = ['male', 'female'];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final response = await ApiService.get('/branches');
      setState(() {
        _branches = List<Map<String, dynamic>>.from(response['data'] ?? []);
      });
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
        _selectedMCId = null; // Reset MC selection
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phone_number': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'role': _selectedRole,
        'branch_id': _selectedBranchId,
        'mc_id': _selectedMCId,
        'gender': _selectedGender,
        'birth_date': _birthDate?.toIso8601String().split('T')[0],
      };

      await ApiService.post('/users', data: userData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
        widget.onUserCreated();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'branch_admin':
        return 'Branch Admin';
      case 'mc_leader':
        return 'MC Leader';
      case 'member':
        return 'Member';
      default:
        return role
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                    Icons.person_add,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add New User',
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
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the full name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an email address';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Role Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role *',
                          prefixIcon: Icon(Icons.admin_panel_settings),
                          border: OutlineInputBorder(),
                        ),
                        items: _roles
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(_getRoleDisplayName(role)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedRole = value!),
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Select Gender'),
                          ),
                          ..._genders.map(
                            (gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(
                                gender[0].toUpperCase() + gender.substring(1),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                      ),
                      const SizedBox(height: 16),

                      // Birth Date Field
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(
                              const Duration(days: 365 * 18),
                            ),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _birthDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Birth Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _birthDate != null
                                ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                : 'Select birth date',
                            style: TextStyle(
                              color: _birthDate != null
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Branch Dropdown
                      DropdownButtonFormField<int>(
                        initialValue: _selectedBranchId,
                        decoration: const InputDecoration(
                          labelText: 'Branch',
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
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 210,
                                ),
                                child: Text(
                                  branch['name'] ?? 'Unknown Branch',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
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
                      ),
                      const SizedBox(height: 16),

                      // MC Dropdown
                      DropdownButtonFormField<int>(
                        initialValue: _selectedMCId,
                        decoration: const InputDecoration(
                          labelText: 'Missional Community',
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
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 210,
                                ),
                                child: Text(
                                  mc['name'] ?? 'Unknown MC',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: _selectedBranchId == null
                            ? null
                            : (value) => setState(() => _selectedMCId = value),
                      ),
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
                      onPressed: _isLoading ? null : _createUser,
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create User'),
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

class _EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onUserUpdated;

  const _EditUserDialog({required this.user, required this.onUserUpdated});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  static final Logger _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  late String _selectedRole;
  int? _selectedBranchId;
  int? _selectedMCId;
  String? _selectedGender;
  DateTime? _birthDate;

  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _mcs = [];

  bool _isLoading = false;

  final List<String> _roles = [
    'member',
    'mc_leader',
    'branch_admin',
    'super_admin',
  ];
  final List<String> _genders = ['male', 'female'];

  @override
  void initState() {
    super.initState();
    try {
      _initializeControllers();
      _loadBranches();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing dialog: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initializeControllers() {
    try {
      // Handle both 'name' field and 'first_name'/'last_name' fields
      String fullName = '';
      if (widget.user['name'] != null &&
          widget.user['name'].toString().isNotEmpty) {
        fullName = widget.user['name'].toString();
      } else if (widget.user['first_name'] != null ||
          widget.user['last_name'] != null) {
        fullName =
            '${widget.user['first_name']?.toString() ?? ''} ${widget.user['last_name']?.toString() ?? ''}'
                .trim();
      }

      _nameController = TextEditingController(text: fullName);
      _emailController = TextEditingController(
        text: widget.user['email']?.toString() ?? '',
      );
      _phoneController = TextEditingController(
        text:
            widget.user['phone_number']?.toString() ??
            widget.user['phone']?.toString() ??
            '',
      );

      _selectedRole = widget.user['role']?.toString() ?? 'member';

      // Safe casting for branch_id
      final branchIdValue = widget.user['branch_id'];
      if (branchIdValue != null) {
        if (branchIdValue is int) {
          _selectedBranchId = branchIdValue;
        } else if (branchIdValue is String) {
          _selectedBranchId = int.tryParse(branchIdValue);
        }
      }

      // Safe casting for mc_id
      final mcIdValue = widget.user['mc_id'];
      if (mcIdValue != null) {
        if (mcIdValue is int) {
          _selectedMCId = mcIdValue;
        } else if (mcIdValue is String) {
          _selectedMCId = int.tryParse(mcIdValue);
        }
      }

      _selectedGender = widget.user['gender']?.toString();

      if (widget.user['birth_date'] != null) {
        try {
          final birthDateString = widget.user['birth_date'].toString();
          if (birthDateString.isNotEmpty) {
            _birthDate = DateTime.parse(birthDateString);
          }
        } catch (e) {
          _logger.e('Error parsing birth date: $e');
          _birthDate = null;
        }
      }
    } catch (e) {
      _logger.e('Error initializing controllers: $e');
      // Initialize with safe defaults
      _nameController = TextEditingController(text: '');
      _emailController = TextEditingController(text: '');
      _phoneController = TextEditingController(text: '');
      _selectedRole = 'member';
      _selectedBranchId = null;
      _selectedMCId = null;
      _selectedGender = null;
      _birthDate = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final response = await ApiService.get('/branches');
      if (mounted) {
        setState(() {
          _branches = List<Map<String, dynamic>>.from(
            response['branches'] ?? [],
          );
        });
        if (_selectedBranchId != null) {
          await _loadMCs();
        }
      }
    } catch (e) {
      _logger.e('Error loading branches: $e');
      if (mounted) {
        setState(() {
          _branches = [];
        });
      }
    }
  }

  Future<void> _loadMCs() async {
    if (_selectedBranchId == null) return;

    try {
      // Use the MCs API with branch filter instead of non-existent branches/{id}/mcs
      final response = await ApiService.getMCs(branchId: _selectedBranchId);
      if (mounted) {
        setState(() {
          _mcs = List<Map<String, dynamic>>.from(response['mcs'] ?? []);
        });
      }
    } catch (e) {
      _logger.e('Error loading MCs: $e');
      if (mounted) {
        setState(() {
          _mcs = [];
        });
      }
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'role': _selectedRole,
        'branch_id': _selectedBranchId,
        'mc_id': _selectedMCId,
        'gender': _selectedGender,
        'birth_date': _birthDate?.toIso8601String().split('T')[0],
      };

      await ApiService.put('/users/${widget.user['id']}', data: userData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        widget.onUserUpdated();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'branch_admin':
        return 'Branch Admin';
      case 'mc_leader':
        return 'MC Leader';
      case 'member':
        return 'Member';
      default:
        return role
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the full name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an email address';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Role Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role *',
                          prefixIcon: Icon(Icons.admin_panel_settings),
                          border: OutlineInputBorder(),
                        ),
                        items: _roles
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(_getRoleDisplayName(role)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedRole = value!),
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Select Gender'),
                          ),
                          ..._genders.map(
                            (gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(
                                gender[0].toUpperCase() + gender.substring(1),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                      ),
                      const SizedBox(height: 16),

                      // Birth Date Field
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                _birthDate ??
                                DateTime.now().subtract(
                                  const Duration(days: 365 * 18),
                                ),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _birthDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Birth Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _birthDate != null
                                ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                : 'Select birth date',
                            style: TextStyle(
                              color: _birthDate != null
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Branch Dropdown
                      DropdownButtonFormField<int>(
                        initialValue: _selectedBranchId,
                        decoration: const InputDecoration(
                          labelText: 'Branch',
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
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 210,
                                ),
                                child: Text(
                                  branch['name'] ?? 'Unknown Branch',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
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
                      ),
                      const SizedBox(height: 16),

                      // MC Dropdown
                      DropdownButtonFormField<int>(
                        initialValue: _selectedMCId,
                        decoration: const InputDecoration(
                          labelText: 'Missional Community',
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
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 210,
                                ),
                                child: Text(
                                  mc['name'] ?? 'Unknown MC',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: _selectedBranchId == null
                            ? null
                            : (value) => setState(() => _selectedMCId = value),
                      ),
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
                      onPressed: _isLoading ? null : _updateUser,
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update User'),
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
