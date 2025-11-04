import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../widgets/birthday_notifications_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    await dashboardProvider.loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Divine Life Church'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'profile':
                      context.goNamed('profile');
                      break;
                    case 'logout':
                      final goRouter = GoRouter.of(context);
                      await authProvider.logout();
                      if (mounted) {
                        goRouter.goNamed('login');
                      }
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      title: Text(
                        'Profile',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.logout,
                        color: Theme.of(context).colorScheme.error,
                        size: 24,
                      ),
                      title: Text(
                        'Logout',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      authProvider.userName.isNotEmpty
                          ? authProvider.userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer3<AuthProvider, AppStateProvider, DashboardProvider>(
        builder: (context, authProvider, appStateProvider, dashboardProvider, child) {
          if (!appStateProvider.isOnline) {
            return _buildOfflineIndicator(context);
          }

          if (dashboardProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading Divine Life Church...'),
                ],
              ),
            );
          }

          if (dashboardProvider.errorMessage != null) {
            return _buildErrorMessage(context, dashboardProvider);
          }

          return RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section removed for all user dashboards per request
                  _buildStatsCards(context, authProvider, dashboardProvider),
                  const SizedBox(height: 24),

                  // Birthday notifications for leaders
                  const BirthdayNotificationsWidget(),

                  _buildQuickActions(context, authProvider),
                  const SizedBox(height: 24),
                  _buildLatestAnnouncements(context, dashboardProvider),
                  const SizedBox(height: 24),
                  _buildLatestSermons(context, dashboardProvider),
                  const SizedBox(height: 24),
                  _buildLatestTikTokPost(context, dashboardProvider),
                  // Only show Recent Activities to Super Admins and Branch Admins
                  if (authProvider.isSuperAdmin ||
                      authProvider.isBranchAdmin) ...[
                    const SizedBox(height: 24),
                    _buildRecentActivities(context, dashboardProvider),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflineIndicator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You\'re offline. Some features may be limited.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(
    BuildContext context,
    DashboardProvider dashboardProvider,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Error Loading Dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dashboardProvider.errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              dashboardProvider.clearError();
              _loadDashboardData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Welcome section removed — no longer used by dashboard

  Widget _buildStatsCards(
    BuildContext context,
    AuthProvider authProvider,
    DashboardProvider dashboardProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3, // Adjusted from 1.5 to prevent overflow
          children: [
            if (authProvider.canManageUsers)
              _buildStatCard(
                context,
                'Total Users',
                dashboardProvider.totalUsers.toString(),
                Icons.people,
                () => context.goNamed('users'),
              ),
            if (authProvider.canManageBranches)
              _buildStatCard(
                context,
                'Branches',
                dashboardProvider.totalBranches.toString(),
                Icons.account_tree,
                () => context.goNamed('branches'),
              ),
            if (authProvider.canManageMCs)
              _buildStatCard(
                context,
                'MCs',
                dashboardProvider.totalMCs.toString(),
                Icons.groups,
                () => context.goNamed('mcs'),
              ),
            if (authProvider.canCreateReports)
              _buildStatCardWithSubtitle(
                context,
                'Reports',
                dashboardProvider.totalReports.toString(),
                dashboardProvider.reportsPeriodText,
                Icons.assessment,
                () => context.goNamed('reports'),
              ),
            _buildStatCard(
              context,
              'Events',
              dashboardProvider.totalEvents.toString(),
              Icons.event,
              () => context.goNamed('events'),
            ),
            _buildStatCard(
              context,
              'Announcements',
              dashboardProvider.totalAnnouncements.toString(),
              Icons.announcement,
              () => context.goNamed('announcements'),
            ),
            // MC Members card for all members who belong to an MC
            if (authProvider.userMCId != null)
              _buildStatCard(
                context,
                'MC Members',
                dashboardProvider.totalMCMembers.toString(),
                Icons.group,
                () => context.goNamed('mc_members'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced from 16
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28, // Reduced from 32
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 6), // Reduced from 8
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  // Changed from headlineMedium
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCardWithSubtitle(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AuthProvider authProvider) {
    final quickActions = <Map<String, dynamic>>[
      if (authProvider.canCreateReports)
        {
          'title': 'Submit Report',
          'icon': Icons.add_chart,
          'onTap': () => context.goNamed('reports'),
        },
      if (authProvider.canManageEvents)
        {
          'title': 'Create Event',
          'icon': Icons.add_box,
          'onTap': () => context.goNamed('events'),
        },
      if (authProvider.canManageAnnouncements)
        {
          'title': 'New Announcement',
          'icon': Icons.campaign,
          'onTap': () => context.goNamed('announcements'),
        },
      if (authProvider.canManageUsers)
        {
          'title': 'Add User',
          'icon': Icons.person_add,
          'onTap': () => context.goNamed('users'),
        },
    ];

    if (quickActions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2, // Adjusted from 2.5 to prevent overflow
          ),
          itemCount: quickActions.length,
          itemBuilder: (context, index) {
            final action = quickActions[index];
            return Card(
              child: InkWell(
                onTap: action['onTap'],
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        action['icon'],
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          action['title'],
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivities(
    BuildContext context,
    DashboardProvider dashboardProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivitySummary(context, dashboardProvider),
                const SizedBox(height: 16),
                _buildRecentStats(context, dashboardProvider),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySummary(
    BuildContext context,
    DashboardProvider dashboardProvider,
  ) {
    return Row(
      children: [
        Icon(Icons.insights, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Current statistics from your church database',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        if (dashboardProvider.isLoadingStats)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildRecentStats(
    BuildContext context,
    DashboardProvider dashboardProvider,
  ) {
    return Column(
      children: [
        _buildStatRow(
          context,
          'Pending Users',
          dashboardProvider.pendingUsers.toString(),
          Icons.person_add,
          Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 8),
        _buildStatRow(
          context,
          'Recent Registrations (30 days)',
          dashboardProvider.recentRegistrations.toString(),
          Icons.trending_up,
          Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(height: 8),
        _buildStatRow(
          context,
          'Pending Reports',
          dashboardProvider.pendingReports.toString(),
          Icons.pending_actions,
          Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  Widget _buildLatestAnnouncements(
    BuildContext context,
    DashboardProvider dashboardProvider,
  ) {
    final announcements = dashboardProvider.recentAnnouncements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Announcements',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: announcements.isEmpty
                ? Column(
                    children: [
                      Text(
                        'No recent announcements',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.goNamed('announcements'),
                        child: const Text('View all announcements'),
                      ),
                    ],
                  )
                : Column(
                    children: announcements.map((a) {
                      final createdAt = a.createdAt;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: InkWell(
                          onTap: () => context.goNamed('announcements'),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.title,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatAnnouncementDate(createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestSermons(
    BuildContext context,
    DashboardProvider dashboardProvider,
  ) {
    final sermons = dashboardProvider.featuredSermons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Sermons',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: sermons.isEmpty
                ? Column(
                    children: [
                      Text(
                        'No sermons available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.goNamed('sermons'),
                        child: const Text('Browse sermons'),
                      ),
                    ],
                  )
                : SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final s = sermons[index];
                        return InkWell(
                          onTap: () => context.goNamed('sermons'),
                          child: SizedBox(
                            width: 220,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      s.youtubeThumbnail,
                                      width: 220,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, st) => Container(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        child: const Center(
                                          child: Icon(Icons.music_video),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  s.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemCount: sermons.length,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestTikTokPost(
    BuildContext context,
    DashboardProvider dashboardProvider,
  ) {
    final latestPosts = dashboardProvider.latestTikTokPosts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest TikTok Posts',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: latestPosts.isEmpty
                ? Column(
                    children: [
                      Text(
                        'No TikTok posts available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.goNamed('sermons'),
                        child: const Text('Browse posts'),
                      ),
                    ],
                  )
                : Column(
                    children: latestPosts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final post = entry.value;
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 24),
                          InkWell(
                            onTap: () async {
                              // Open TikTok URL in browser
                              final uri = Uri.parse(post.postUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: Row(
                              children: [
                                // TikTok thumbnail or icon
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: post.thumbnailUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            post.thumbnailUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, st) =>
                                                const Icon(
                                                  Icons.video_library,
                                                  color: Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.video_library,
                                          color: Colors.white,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (post.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          post.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.video_camera_front,
                                            size: 16,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Watch on TikTok',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.open_in_new,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  String _formatAnnouncementDate(DateTime date) {
    final now = DateTime.now();
    final justNow = DateTime(now.year, now.month, now.day);
    final justDate = DateTime(date.year, date.month, date.day);
    final difference = justNow.difference(justDate).inDays;

    // Today
    if (difference == 0) return 'Today';

    // Yesterday
    if (difference == 1) return 'Yesterday';

    // Within the last week - show day name
    if (difference <= 7) {
      const dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return dayNames[date.weekday - 1];
    }

    // More than a week ago - show full date in format: "12th Dec 2025"
    return _formatFullDate(date);
  }

  String _formatFullDate(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    String getDayWithSuffix(int day) {
      if (day >= 11 && day <= 13) {
        return '${day}th';
      }
      switch (day % 10) {
        case 1:
          return '${day}st';
        case 2:
          return '${day}nd';
        case 3:
          return '${day}rd';
        default:
          return '${day}th';
      }
    }

    final dayWithSuffix = getDayWithSuffix(date.day);
    final monthName = monthNames[date.month - 1];

    return '$dayWithSuffix $monthName ${date.year}';
  }

  Widget _buildStatRow(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
