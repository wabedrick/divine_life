import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/error_tracker.dart';
import 'create_mc_screen.dart';
import 'mc_members_dialog.dart';

class MCManagementScreen extends StatefulWidget {
  const MCManagementScreen({super.key});

  @override
  State<MCManagementScreen> createState() => _MCManagementScreenState();
}

class _MCManagementScreenState extends State<MCManagementScreen> {
  List<Map<String, dynamic>> _mcs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedBranch = 'all';
  List<Map<String, dynamic>> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadMCs(), _loadBranches()]);
  }

  Future<void> _loadMCs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/mcs');
      final rawData = response['mcs']; // Backend returns 'mcs' key, not 'data'

      // COMPREHENSIVE DATA VALIDATION AND SANITIZATION
      final List<Map<String, dynamic>> sanitizedMCs = [];

      if (rawData is List) {
        for (int i = 0; i < rawData.length; i++) {
          try {
            final rawMC = rawData[i];
            if (rawMC is Map) {
              // Create a completely sanitized MC object
              final sanitizedMC = <String, dynamic>{
                'id': _sanitizeId(rawMC['id']),
                'name': _sanitizeString(rawMC['name']),
                'branch_id': _sanitizeId(rawMC['branch_id']),
                'branch': _sanitizeBranch(
                  rawMC['branch'],
                ), // Include branch info
                'leader': _sanitizeLeader(rawMC['leader']),
                'location': _sanitizeString(rawMC['location']),
                'meeting_day': _sanitizeString(rawMC['meeting_day']),
                'meeting_time': _sanitizeString(rawMC['meeting_time']),
                'total_members': _sanitizeNumber(rawMC['total_members']),
                'active_members': _sanitizeNumber(rawMC['active_members']),
                'goals': _sanitizeString(rawMC['goals']),
                'vision': _sanitizeString(rawMC['vision']), // Add vision
                'purpose': _sanitizeString(rawMC['purpose']), // Add purpose
                'status': _sanitizeString(rawMC['status']),
                'created_at': _sanitizeString(rawMC['created_at']),
                'updated_at': _sanitizeString(rawMC['updated_at']),
              };

              // Only add if essential fields are present
              if (sanitizedMC['id'] != null && sanitizedMC['name'].isNotEmpty) {
                sanitizedMCs.add(sanitizedMC);
              }
            }
          } catch (mcError) {
            ErrorTracker.logError(
              'Error sanitizing MC at index $i: $mcError',
              context: '_loadMCs MC sanitization',
              data: {'mcIndex': i, 'rawMC': rawData[i]},
            );
            // Skip problematic MC but continue processing others
          }
        }
      }

      _mcs = sanitizedMCs;
      setState(() {
        _isLoading = false;
      });

      ErrorTracker.logError(
        'MCs loaded and sanitized successfully',
        context: '_loadMCs success',
        data: {
          'originalCount': (rawData as List?)?.length ?? 0,
          'sanitizedCount': sanitizedMCs.length,
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      ErrorTracker.logError(
        'Failed to load MCs: $e',
        context: '_loadMCs error',
        data: {'error': e.toString()},
      );
    }
  }

  // BULLETPROOF DATA SANITIZATION METHODS

  int? _sanitizeId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.round();
    return null;
  }

  String _sanitizeString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  int _sanitizeNumber(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.round();
    return 0;
  }

  Map<String, dynamic>? _sanitizeLeader(dynamic value) {
    if (value == null) return null;
    if (value is! Map) return null;

    return {
      'id': _sanitizeId(value['id']),
      'name': _sanitizeString(value['name']),
      'email': _sanitizeString(value['email']),
    };
  }

  Map<String, dynamic>? _sanitizeBranch(dynamic value) {
    if (value == null) return null;
    if (value is! Map) return null;

    return {
      'id': _sanitizeId(value['id']),
      'name': _sanitizeString(value['name']),
      'location': _sanitizeString(value['location']),
      'description': _sanitizeString(value['description']),
    };
  }

  Future<void> _loadBranches() async {
    try {
      final response = await ApiService.get('/branches');
      _branches = List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      // Handle error silently
    }
  }

  List<Map<String, dynamic>> get _filteredMCs {
    // BULLETPROOF IMPLEMENTATION - NO EXCEPTIONS ALLOWED
    try {
      // Validate input data first
      if (_mcs.isEmpty) {
        return <Map<String, dynamic>>[];
      }

      // Create a completely new list to avoid any reference issues
      final List<Map<String, dynamic>> result = [];

      // Process each MC individually with full validation
      for (int i = 0; i < _mcs.length; i++) {
        try {
          final originalMC = _mcs[i];

          // Validate MC is not null and has required structure
          if (originalMC.isEmpty) {
            continue; // Skip invalid MCs
          }

          // Branch filtering with bulletproof type safety
          bool passesBranchFilter = true;
          if (_selectedBranch != 'all' && _selectedBranch.isNotEmpty) {
            // Convert selected branch to int safely
            final selectedBranchInt = int.tryParse(_selectedBranch.toString());
            if (selectedBranchInt != null) {
              // Convert MC branch_id to int safely
              final mcBranchIdRaw = originalMC['branch_id'];
              int? mcBranchIdInt;

              if (mcBranchIdRaw is int) {
                mcBranchIdInt = mcBranchIdRaw;
              } else if (mcBranchIdRaw is String) {
                mcBranchIdInt = int.tryParse(mcBranchIdRaw);
              } else if (mcBranchIdRaw != null) {
                mcBranchIdInt = int.tryParse(mcBranchIdRaw.toString());
              }

              // Only include if branch IDs match
              passesBranchFilter = (mcBranchIdInt == selectedBranchInt);
            }
          }

          // Search filtering with bulletproof string handling
          bool passesSearchFilter = true;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();

            // Safe string extraction
            final name = (originalMC['name']?.toString() ?? '').toLowerCase();
            final leaderName = (originalMC['leader']?['name']?.toString() ?? '')
                .toLowerCase();
            final location = (originalMC['location']?.toString() ?? '')
                .toLowerCase();

            passesSearchFilter =
                name.contains(query) ||
                leaderName.contains(query) ||
                location.contains(query);
          }

          // Add to result if passes all filters
          if (passesBranchFilter && passesSearchFilter) {
            // Create a clean copy to avoid any reference issues
            final cleanMC = Map<String, dynamic>.from(originalMC);
            result.add(cleanMC);
          }
        } catch (mcError) {
          // Log individual MC processing error but continue
          ErrorTracker.logError(
            'Error processing MC at index $i: $mcError',
            context: '_filteredMCs individual MC error',
            data: {'mcIndex': i, 'error': mcError.toString()},
          );
          continue; // Skip problematic MC
        }
      }

      return result;
    } catch (e, stackTrace) {
      // Ultimate fallback - return empty list
      ErrorTracker.logError(
        'CRITICAL ERROR in _filteredMCs: $e',
        context: '_filteredMCs critical failure',
        data: {
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
          'selectedBranch': _selectedBranch,
          'searchQuery': _searchQuery,
          'mcsLength': _mcs.length,
        },
      );

      return <Map<String, dynamic>>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MC Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMCs),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search MCs...',
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

          // Branch Filter Chips
          if (_branches.isNotEmpty)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('All Branches', 'all'),
                  ..._branches.map(
                    (branch) => _buildFilterChip(
                      branch['name'],
                      branch['id'].toString(),
                    ),
                  ),
                ],
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
                    onPressed: _loadMCs,
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMCsList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Debug info button (only when errors exist and not in production)
          if (ErrorTracker.hasErrorPattern('MC') &&
              const bool.fromEnvironment('dart.vm.product') != true)
            FloatingActionButton.small(
              heroTag: "debug_mc",
              onPressed: _showDebugInfo,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.bug_report, size: 16),
            ),
          if (ErrorTracker.hasErrorPattern('MC')) const SizedBox(height: 8),
          // Add MC button
          if (authProvider.canManageMCs)
            FloatingActionButton.extended(
              heroTag: "add_mc",
              onPressed: _showCreateMCDialog,
              icon: const Icon(Icons.add_business),
              label: const Text('New MC'),
            ),
        ],
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: ErrorTracker.getAllErrors()
                .where((error) => error.contains('MC'))
                .map(
                  (error) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ErrorTracker.clearErrors();
              Navigator.pop(context);
            },
            child: const Text('Clear Errors'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedBranch == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedBranch = selected ? value : 'all';
          });
        },
      ),
    );
  }

  Widget _buildMCsList() {
    if (_filteredMCs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No MCs found' : 'No MCs yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search criteria'
                  : 'Start by creating your first MC',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMCs,
      child: Builder(
        builder: (context) {
          // BULLETPROOF ListView Implementation
          final filteredMCs = _filteredMCs;

          // Handle empty state
          if (filteredMCs.isEmpty) {
            return const Center(child: Text('No MCs found'));
          }

          // Build list using safe iteration
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredMCs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) {
              // BULLETPROOF: Multiple safety checks

              // 1. Validate index bounds (index is guaranteed to be int by Flutter)
              if (index < 0 || index >= filteredMCs.length) {
                return _buildErrorCard('Index out of bounds: $index');
              }

              // 2. Safe MC access
              Map<String, dynamic> mc;
              try {
                mc = filteredMCs[index];
              } catch (e) {
                return _buildErrorCard('List access error: $e');
              }

              // 3. Validate MC data structure
              if (mc.isEmpty) {
                return _buildErrorCard('Empty MC data at index $index');
              }

              // 4. Build card with final safety wrapper
              try {
                return _buildMCCard(mc);
              } catch (e) {
                return _buildErrorCard('Card build error: $e');
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMCCard(Map<String, dynamic> mc) {
    final name = mc['name'] ?? '';
    final leaderName = mc['leader']?['name'] ?? 'No Leader';
    final branchName = mc['branch']?['name'] ?? 'No Branch';
    final memberCount = mc['member_count'] ?? 0;
    final location = mc['location'] ?? '';
    final isActive = mc['is_active'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMCDetails(mc),
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
                            const Icon(Icons.location_city, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              branchName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        if (location.isNotEmpty) ...[
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
                        ],
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
                    onSelected: (value) => _handleMCAction(value, mc),
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

              // Statistics and Vision Preview
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$memberCount Members',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (mc['vision'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            mc['vision'],
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (mc['goals'] != null)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Goals',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mc['goals'],
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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

  Widget _buildErrorCard(String errorMessage) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error Loading MC',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter MCs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedBranch,
              decoration: const InputDecoration(
                labelText: 'Branch',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('All Branches'),
                ),
                ..._branches.map((branch) {
                  return DropdownMenuItem(
                    value: branch['id'].toString(),
                    child: Text(branch['name']),
                  );
                }),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedBranch = value;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedBranch = 'all';
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _handleMCAction(String action, Map<String, dynamic> mc) {
    switch (action) {
      case 'view':
        _showMCDetails(mc);
        break;
      case 'members':
        _manageMCMembers(mc);
        break;
      case 'edit':
        _editMC(mc);
        break;
      case 'reports':
        _viewMCReports(mc);
        break;
    }
  }

  void _showMCDetails(Map<String, dynamic> mc) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.groups,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mc['name'] ?? 'Unknown MC',
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
                              color: _getMCStatusColor(mc['is_active'] == true),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              mc['is_active'] == true ? 'Active' : 'Inactive',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMCDetailRow(
                        'Branch',
                        mc['branch']?['name'] ?? mc['branch_name'] ?? 'N/A',
                        Icons.location_city_outlined,
                      ),
                      _buildMCDetailRow(
                        'Leader',
                        mc['leader']?['name'] ??
                            mc['leader_name'] ??
                            'No Leader Assigned',
                        Icons.person_outline,
                      ),
                      _buildMCDetailRow(
                        'Location',
                        mc['location'] ?? 'N/A',
                        Icons.place_outlined,
                      ),
                      _buildMCDetailRow(
                        'Members',
                        '${mc['member_count'] ?? 0} members',
                        Icons.group_outlined,
                      ),
                      _buildMCDetailRow(
                        'Meeting Day',
                        mc['meeting_day'] ?? 'N/A',
                        Icons.calendar_today_outlined,
                      ),
                      _buildMCDetailRow(
                        'Meeting Time',
                        mc['meeting_time'] ?? 'N/A',
                        Icons.access_time_outlined,
                      ),
                      _buildMCDetailRow(
                        'Contact Phone',
                        mc['leader_phone'] ?? 'N/A',
                        Icons.phone_outlined,
                      ),
                      if (mc['vision'] != null &&
                          mc['vision'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildMCSectionHeader(
                          'Vision',
                          Icons.visibility_outlined,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            mc['vision'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      if (mc['goals'] != null &&
                          mc['goals'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildMCSectionHeader('Goals', Icons.flag_outlined),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            mc['goals'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      if (mc['purpose'] != null &&
                          mc['purpose'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildMCSectionHeader(
                          'Purpose',
                          Icons.lightbulb_outline,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            mc['purpose'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Action buttons row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _editMC(mc);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit MC'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _manageMCMembers(mc);
                            },
                            icon: const Icon(Icons.people_outlined),
                            label: const Text('Members'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Reports and Close buttons row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _viewMCReports(mc);
                            },
                            icon: const Icon(Icons.analytics_outlined),
                            label: const Text('Reports'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
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

  Widget _buildMCDetailRow(String label, String value, IconData icon) {
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

  Widget _buildMCSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Color _getMCStatusColor(bool isActive) {
    return isActive ? Colors.green : Colors.red;
  }

  void _showCreateMCDialog() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CreateMCScreen()));
    if (result == true) {
      _loadMCs();
    }
  }

  void _editMC(Map<String, dynamic> mc) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateMCScreen(existingMC: mc, isEditing: true),
      ),
    );
    if (result == true) {
      _loadMCs();
    }
  }

  void _manageMCMembers(Map<String, dynamic> mc) {
    showDialog(
      context: context,
      builder: (context) => MCMembersDialog(mc: mc),
    );
  }

  void _viewMCReports(Map<String, dynamic> mc) {
    // TODO: Navigate to MC reports screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing reports for ${mc['name']}')),
    );
  }
}
