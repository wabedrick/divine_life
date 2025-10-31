import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/chat_models.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/auth_provider.dart';

import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart' as custom;

/// Professional chat list screen with Material Design 3
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  int _lastTabIndex = 0;
  List<String> _tabLabels = [];
  List<ConversationType?> _tabTypes = [];

  @override
  void initState() {
    super.initState();
    // Defer TabController creation until we can read AuthProvider from context.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Configure tabs: remove 'Groups' tab globally. Members see only MC & Branch.
      if (authProvider.isMember) {
        _tabLabels = ['MC', 'Branch'];
        _tabTypes = [ConversationType.mc, ConversationType.branch];
      } else {
        _tabLabels = ['All', 'MC', 'Branch'];
        _tabTypes = [null, ConversationType.mc, ConversationType.branch];
      }

      _tabController = TabController(length: _tabLabels.length, vsync: this);

      // Listen to tab changes to clear category state and load the new category once
      _tabController!.addListener(() {
        if (!(_tabController!.indexIsChanging) &&
            _tabController!.index != _lastTabIndex) {
          _lastTabIndex = _tabController!.index;
          // Reset and load the selected category
          chatProvider.resetCategory();
          final category = _categoryFromIndex(_tabController!.index);
          chatProvider.loadConversationsByCategory(category);
        }
      });

      // Initialize chat provider and load initial tab conversations
      await chatProvider.init();
      final initialCategory = _categoryFromIndex(_tabController!.index);
      await chatProvider.loadConversationsByCategory(initialCategory);
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (_tabController != null) {
      _tabController!.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          _buildTabBar(),
          Expanded(child: _buildTabBarView()),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // Helper to map tab index to category string
  String _categoryFromIndex(int index) {
    if (_tabLabels.isEmpty) return 'All';
    if (index < 0 || index >= _tabLabels.length) return 'All';
    return _tabLabels[index];
  }

  IconData _iconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'all':
        return Icons.chat_bubble_outline;
      case 'groups':
        return Icons.group_outlined;
      case 'mc':
        return Icons.church_outlined;
      case 'branch':
        return Icons.business_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF25D366), // WhatsApp green
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Divine Life Chat',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
          tooltip: _isSearching ? 'Close search' : 'Search conversations',
        ),
        Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return Badge(
              isLabelVisible: chatProvider.totalUnreadCount > 0,
              label: Text('${chatProvider.totalUnreadCount}'),
              backgroundColor: Colors.red,
              textColor: Colors.white,
              child: IconButton(
                icon: Icon(
                  chatProvider.isConnected
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                ),
                onPressed: () => _showConnectionStatus(chatProvider),
                tooltip: chatProvider.isConnected ? 'Connected' : 'Offline',
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: _tabController == null
          ? const SizedBox(height: 48)
          : TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF25D366), // WhatsApp green
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF25D366),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: _tabLabels
                  .map(
                    (label) => Tab(
                      icon: Icon(_iconForLabel(label), size: 20),
                      text: label,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildTabBarView() {
    if (_tabController == null) {
      return const Center(child: LoadingWidget(message: 'Loading chats...'));
    }

    return TabBarView(
      controller: _tabController,
      children: _tabTypes.map((t) => _buildConversationsList(type: t)).toList(),
    );
  }

  Widget _buildConversationsList({ConversationType? type}) {
    // Determine category outside of Consumer to avoid rebuild issues
    final String category = (() {
      switch (type) {
        case ConversationType.group:
          return 'Groups';
        case ConversationType.mc:
          return 'MC';
        case ConversationType.branch:
          return 'Branch';
        default:
          return 'All';
      }
    })();

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Conversations are loaded via init and tab change listener to avoid multiple calls

        if (chatProvider.isLoadingConversations) {
          return const LoadingWidget(message: 'Loading conversations...');
        }

        if (chatProvider.error != null) {
          return custom.ErrorWidget(
            error: chatProvider.error!,
            onRetry: () => chatProvider.loadConversationsByCategory(category),
          );
        }

        List<Conversation> conversations = chatProvider.conversations;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          conversations = chatProvider.searchConversations(_searchQuery);
        }

        if (conversations.isEmpty) {
          return _buildEmptyState(type);
        }

        return RefreshIndicator(
          onRefresh: () => chatProvider.loadConversationsByCategory(category),
          child: ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey[300],
              indent: 72, // Align with message content (avatar + padding)
            ),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationTile(conversation);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ConversationType? type) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        String title;
        String subtitle;
        IconData icon;

        switch (type) {
          case ConversationType.group:
            title = 'No group chats';
            subtitle =
                'Create a group chat to start messaging with multiple people';
            icon = Icons.group_add_outlined;
            break;
          case ConversationType.mc:
            if (user != null && user['mc_id'] == null) {
              title = 'No MC assigned';
              subtitle =
                  'You need to be assigned to a Missional Community to access MC chats';
            } else {
              title = 'No MC chats';
              subtitle = 'Start connecting with your Missional Community';
            }
            icon = Icons.church_outlined;
            break;
          case ConversationType.branch:
            title = 'No branch chats available';
            subtitle = user != null && user['role'] == 'member'
                ? 'You can only see chats for your own branch'
                : 'Connect with your branch community';
            icon = Icons.business_outlined;
            break;
          default:
            title = _searchQuery.isEmpty
                ? 'No conversations'
                : 'No results found';
            subtitle = _searchQuery.isEmpty
                ? 'Start a new conversation to begin messaging'
                : 'Try adjusting your search terms';
            icon = Icons.chat_bubble_outline;
        }

        return _buildEmptyStateContent(title, subtitle, icon);
      },
    );
  }

  Widget _buildEmptyStateContent(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            Tooltip(
              message: 'Chat feature is temporarily unavailable',
              child: FilledButton.icon(
                onPressed: null, // Disabled
                icon: const Icon(Icons.add),
                label: const Text('Start Conversation (Coming Soon)'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _openConversation(conversation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _buildConversationAvatar(conversation),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastMessage != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatWhatsAppTimestamp(
                            conversation.lastMessage!.createdAt,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (conversation.lastMessage != null) ...[
                        Icon(
                          _getMessageStatusIcon(
                            conversation.lastMessage!.status,
                          ),
                          size: 16,
                          color: _getMessageStatusColor(
                            conversation.lastMessage!.status,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          conversation.lastMessage != null
                              ? _formatLastMessage(conversation.lastMessage!)
                              : 'No messages yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationAvatar(Conversation conversation) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _getConversationTypeColor(conversation.type),
          child: conversation.avatar != null
              ? ClipOval(
                  child: Image.network(
                    conversation.avatar!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  _getConversationTypeIcon(conversation.type),
                  color: Colors.white,
                  size: 24,
                ),
        ),
        // Online indicator for individual conversations
        if (conversation.type == ConversationType.individual)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFAB() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Members are not allowed to create chats
    if (authProvider.isMember) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: () {
        // Temporarily disabled for non-members too (feature gated)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat creation coming soon!')),
        );
      },
      backgroundColor: const Color(0xFF25D366),
      child: const Icon(Icons.message, color: Colors.white),
    );
  }

  String _formatLastMessage(Message message) {
    switch (message.type) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.file:
        return '📎 File';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.location:
        return '📍 Location';
      default:
        return message.content;
    }
  }

  IconData _getConversationTypeIcon(ConversationType type) {
    switch (type) {
      case ConversationType.individual:
        return Icons.person;
      case ConversationType.group:
        return Icons.group;
      case ConversationType.mc:
        return Icons.church;
      case ConversationType.branch:
        return Icons.business;
      case ConversationType.announcement:
        return Icons.campaign;
    }
  }

  String _formatWhatsAppTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today: show time (e.g., "14:30")
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (messageDate.isAfter(today.subtract(const Duration(days: 7)))) {
      // This week: show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      // Older: show date (e.g., "12/31/23")
      return "${dateTime.month}/${dateTime.day}/${dateTime.year.toString().substring(2)}";
    }
  }

  Color _getConversationTypeColor(ConversationType type) {
    switch (type) {
      case ConversationType.individual:
        return Colors.blue;
      case ConversationType.group:
        return Colors.green;
      case ConversationType.mc:
        return Colors.purple;
      case ConversationType.branch:
        return Colors.orange;
      case ConversationType.announcement:
        return Colors.red;
    }
  }

  IconData _getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
      default:
        return Icons.schedule;
    }
  }

  Color _getMessageStatusColor(MessageStatus status, ThemeData theme) {
    switch (status) {
      case MessageStatus.sent:
        return theme.colorScheme.outline;
      case MessageStatus.delivered:
        return theme.colorScheme.outline;
      case MessageStatus.read:
        return const Color(0xFF25D366); // WhatsApp green for read
      case MessageStatus.failed:
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  void _openConversation(Conversation conversation) {
    context.go('/chat/${conversation.id}');
  }

  void _showConnectionStatus(ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              chatProvider.isConnected
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              color: chatProvider.isConnected ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(chatProvider.isConnected ? 'Connected' : 'Offline'),
          ],
        ),
        content: Text(
          chatProvider.isConnected
              ? 'You are connected to the chat service. Messages will be delivered in real-time.'
              : 'You are currently offline. Messages will be sent when connection is restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
