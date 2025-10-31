import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// Voice recording is intentionally disabled in this branch to avoid
// native plugin and build issues. To enable voice messages restore the
// `record` package imports and implement platform permission handling.
import 'package:go_router/go_router.dart';
// file_picker and dart:io are not needed after audio removal
import '../../core/models/chat_models.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/utils/message_list_diff.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart' as custom;

/// Professional individual chat screen with Material Design 3
class ChatScreen extends StatefulWidget {
  final int conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();
  List<String> _messageIdsSnapshot = [];
  // Keep a local animated item count so we avoid aggressive resyncs
  int _animatedItemCount = 0;

  // Audio/voice messaging has been removed — fields related to recording/playback omitted.

  late final AnimationController _typingAnimationController;
  Timer? _typingTimer;
  bool _isComposing = false;
  String? _replyToMessageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onMessageChanged);

    // Load conversation and messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingAnimationController.dispose();
    _typingTimer?.cancel();
    // audio removed: no audio player/subscriptions to cancel
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markVisibleMessagesAsRead();
    }
  }

  void _loadConversation() {
    final chatProvider = context.read<ChatProvider>();
    final conversation = chatProvider.getConversationById(
      widget.conversationId,
    );

    if (conversation != null) {
      chatProvider.setActiveConversation(conversation);
    } else {
      // Handle conversation not found
      context.pop();
    }
  }

  void _syncAnimatedListItems(List<Message> messages) {
    // Compute diffs between _messageIdsSnapshot and current messages
    // Normalize IDs to strings so comparisons are consistent
    final currentIds = messages.map((m) => m.id.toString()).toList();

    // Use the diff util to compute inserts/removes
    final diffs = MessageListDiff.computeDiffs(_messageIdsSnapshot, currentIds);
    final removes = diffs['removes']!;
    final inserts = diffs['inserts']!;

    // If the change is small (single insert or remove), animate it. Otherwise resync snapshot.
    if (removes.length <= 1 && inserts.length <= 1) {
      // Apply removals (from highest index to lowest to preserve indices)
      removes.sort((a, b) => b.compareTo(a));
      for (final removeIndex in removes) {
        if (removeIndex >= 0 && removeIndex < _messageIdsSnapshot.length) {
          _messageIdsSnapshot.removeAt(removeIndex);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              _animatedListKey.currentState?.removeItem(
                removeIndex,
                (context, animation) => SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: 0.0,
                  child: Container(),
                ),
                duration: const Duration(milliseconds: 300),
              );
              _animatedItemCount = (_animatedItemCount - 1).clamp(0, 100000);
            } catch (e) {
              debugPrint('AnimatedList.removeItem failed: $e');
              _messageIdsSnapshot = List<String>.from(currentIds);
              if (mounted) setState(() {});
            }
          });
        }
      }

      // Apply inserts
      for (final insertIndex in inserts) {
        if (insertIndex >= 0 && insertIndex <= _messageIdsSnapshot.length) {
          _messageIdsSnapshot.insert(insertIndex, currentIds[insertIndex]);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              _animatedListKey.currentState?.insertItem(
                insertIndex,
                duration: const Duration(milliseconds: 300),
              );
              _animatedItemCount += 1;
            } catch (e) {
              debugPrint('AnimatedList.insertItem failed: $e');
              _messageIdsSnapshot = List<String>.from(currentIds);
              if (mounted) setState(() {});
            }
          });
        }
      }
    } else {
      // Large change - resync without animation to avoid index issues
      _messageIdsSnapshot = List<String>.from(currentIds);
      _animatedItemCount = _messageIdsSnapshot.length;
      if (mounted) setState(() {});
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      // Load more messages when near bottom
      final chatProvider = context.read<ChatProvider>();
      chatProvider.loadMessages(widget.conversationId, loadMore: true);
    }
  }

  void _onMessageChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;

    if (hasText != _isComposing) {
      setState(() {
        _isComposing = hasText;
      });
    }

    if (hasText) {
      _sendTypingIndicator();
    }
  }

  void _sendTypingIndicator() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendTypingIndicator();

    // Cancel previous timer and set new one
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      // Typing indicator will expire on server side
    });
  }

  void _markVisibleMessagesAsRead() {
    final chatProvider = context.read<ChatProvider>();
    final messages = chatProvider.messages;
    final currentUserId = context.read<AuthProvider>().currentUser?['id'];

    final unreadMessageIds = messages
        .where((m) => m.senderId != currentUserId && m.readAt == null)
        .map((m) => m.id)
        .toList();

    if (unreadMessageIds.isNotEmpty) {
      chatProvider.markMessagesAsRead(widget.conversationId, unreadMessageIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final conversation = chatProvider.activeConversation;

        if (conversation == null) {
          return const Scaffold(
            body: LoadingWidget(message: 'Loading conversation...'),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(conversation, chatProvider),
          body: Column(
            children: [
              Expanded(child: _buildMessagesList(chatProvider)),
              if (_replyToMessageId != null) _buildReplyPreview(chatProvider),
              _buildTypingIndicators(chatProvider),
              _buildMessageInput(chatProvider),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    Conversation conversation,
    ChatProvider chatProvider,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          chatProvider.clearActiveConversation();
          context.pop();
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conversation.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (conversation.type != ConversationType.individual)
            Text(
              '${conversation.participantCount} participants',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
        ],
      ),
      actions: [
        Consumer<ChatProvider>(
          builder: (context, provider, child) {
            return Icon(
              provider.isConnected ? Icons.circle : Icons.circle_outlined,
              size: 12,
              color: provider.isConnected ? Colors.green : Colors.orange,
            );
          },
        ),
        const SizedBox(width: 8),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'info',
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Chat Info'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'search',
              child: ListTile(
                leading: Icon(Icons.search),
                title: Text('Search'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: ListTile(
                leading: Icon(Icons.notifications_off_outlined),
                title: Text('Mute'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: (value) =>
              _handleMenuAction(value.toString(), conversation),
        ),
      ],
    );
  }

  Widget _buildMessagesList(ChatProvider chatProvider) {
    if (chatProvider.isLoadingMessages) {
      return const LoadingWidget(message: 'Loading messages...');
    }

    if (chatProvider.error != null) {
      return custom.ErrorWidget(
        error: chatProvider.error!,
        onRetry: () => chatProvider.loadMessages(widget.conversationId),
      );
    }

    final messages = chatProvider.messages;

    // Sync AnimatedList with provider messages (inserts/removals)
    // Normalize ids to strings for consistent comparison with snapshot
    final currentIds = messages.map((m) => m.id.toString()).toList();
    if (_messageIdsSnapshot.isEmpty) {
      // Initialize snapshot on first build to avoid animating the initial load
      _messageIdsSnapshot = List<String>.from(currentIds);
    } else {
      _syncAnimatedListItems(messages);
    }

    if (messages.isEmpty) {
      return _buildEmptyMessagesState();
    }

    return AnimatedList(
      key: _animatedListKey,
      controller: _scrollController,
      reverse: false,
      padding: const EdgeInsets.all(16),
      initialItemCount: messages.length,
      itemBuilder: (context, index, animation) {
        // Defensive: AnimatedList may call with an index that's out-of-sync briefly.
        if (index < 0 || index >= messages.length) {
          return const SizedBox.shrink();
        }

        final message = messages[index];
        final previousMessage = index < messages.length - 1
            ? messages[index + 1]
            : null;
        final nextMessage = index > 0 ? messages[index - 1] : null;

        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: 0.0,
          child: _buildMessageBubble(
            message,
            previousMessage,
            nextMessage,
            chatProvider,
          ),
        );
      },
    );
  }

  Widget _buildEmptyMessagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Message message,
    Message? previousMessage,
    Message? nextMessage,
    ChatProvider chatProvider,
  ) {
    final currentUserId = context.read<AuthProvider>().currentUser?['id'];
    final isOwnMessage = message.senderId == currentUserId;

    // Determine if we should show sender info
    final shouldShowSender =
        previousMessage?.senderId != message.senderId ||
        (previousMessage != null &&
            message.createdAt.difference(previousMessage.createdAt).inMinutes >
                5);

    final shouldShowTimestamp =
        nextMessage?.senderId != message.senderId ||
        (nextMessage != null &&
            nextMessage.createdAt.difference(message.createdAt).inMinutes > 5);

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Container(
        margin: EdgeInsets.only(
          bottom: shouldShowTimestamp ? 16 : 4,
          top: shouldShowSender ? 16 : 0,
        ),
        child: Column(
          crossAxisAlignment: isOwnMessage
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (shouldShowSender && !isOwnMessage)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                  message.senderName ?? 'Unknown',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: isOwnMessage
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isOwnMessage && shouldShowSender) ...[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(
                      (message.senderName ?? 'U').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (!isOwnMessage) ...[
                  const SizedBox(width: 32),
                ],
                Flexible(
                  child: _buildMessageContent(
                    message,
                    isOwnMessage,
                    chatProvider,
                  ),
                ),
              ],
            ),
            if (shouldShowTimestamp)
              Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  left: isOwnMessage ? 0 : 40,
                  right: isOwnMessage ? 0 : 0,
                ),
                child: Row(
                  mainAxisAlignment: isOwnMessage
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(message.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    if (isOwnMessage) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _getMessageStatusIcon(message.status),
                        size: 12,
                        color: _getMessageStatusColor(message.status),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(
    Message message,
    bool isOwnMessage,
    ChatProvider chatProvider,
  ) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOwnMessage
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isOwnMessage ? 18 : 4),
          bottomRight: Radius.circular(isOwnMessage ? 4 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.replyToId != null)
            _buildReplyContent(message, chatProvider),
          _buildMessageTypeContent(message, isOwnMessage),
        ],
      ),
    );
  }

  Widget _buildMessageTypeContent(Message message, bool isOwnMessage) {
    final textColor = isOwnMessage
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    switch (message.type) {
      case MessageType.text:
        return SelectableText(
          message.content,
          style: TextStyle(color: textColor, fontSize: 16),
        );

      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.fileUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.fileUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 200,
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Icon(
                      Icons.broken_image,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                message.content,
                style: TextStyle(color: textColor),
              ),
            ],
          ],
        );

      case MessageType.audio:
        // Audio playback removed: show a neutral file-like preview
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.audiotrack, color: textColor, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'Audio',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (message.fileSize != null)
                    Text(
                      _formatFileSize(message.fileSize!),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.attach_file, color: textColor, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'File',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (message.fileSize != null)
                    Text(
                      _formatFileSize(message.fileSize!),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

      default:
        return SelectableText(
          message.content,
          style: TextStyle(color: textColor),
        );
    }
  }

  Widget _buildReplyContent(Message message, ChatProvider chatProvider) {
    final replied = chatProvider.messages.firstWhere(
      (m) => m.id == message.replyToId,
      orElse: () => Message(
        id: message.replyToId ?? '',
        conversationId: message.conversationId,
        senderId: 0,
        senderName: 'Unknown',
        content: 'Original message not available',
        createdAt: DateTime.now(),
      ),
    );

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replied.senderName ?? 'Unknown',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _replyPreviewText(replied),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _replyPreviewText(Message m) {
    switch (m.type) {
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
        return m.content;
    }
  }
  // Duration formatter removed — audio playback not used in this branch.

  // Audio helpers removed. Caching and seek logic are not needed when audio is disabled.

  Widget _buildReplyPreview(ChatProvider chatProvider) {
    // TODO: Implement reply preview
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 16),
          const SizedBox(width: 8),
          const Expanded(child: Text('Replying to message...')),
          IconButton(
            onPressed: () {
              setState(() {
                _replyToMessageId = null;
              });
            },
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicators(ChatProvider chatProvider) {
    final typingIndicators = chatProvider.typingIndicators;

    if (typingIndicators.isEmpty) {
      return const SizedBox.shrink();
    }

    final names = typingIndicators.map((t) => t.userName).join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: TypingIndicatorPainter(
                    _typingAnimationController.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$names ${typingIndicators.length == 1 ? 'is' : 'are'} typing...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showAttachmentOptions(),
            icon: const Icon(Icons.add),
            tooltip: 'Attach file',
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(chatProvider),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isComposing
                ? IconButton(
                    key: const ValueKey('send'),
                    onPressed: chatProvider.isSendingMessage
                        ? null
                        : () => _sendMessage(chatProvider),
                    icon: chatProvider.isSendingMessage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    tooltip: 'Send message',
                  )
                : IconButton(
                    key: const ValueKey('attachQuick'),
                    onPressed: () => _showAttachmentOptions(),
                    icon: const Icon(Icons.attach_file),
                    tooltip: 'Attach file',
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(ChatProvider chatProvider) async {
    if (!_isComposing || chatProvider.isSendingMessage) return;

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _messageFocusNode.requestFocus();

    await chatProvider.sendMessage(
      content: content,
      replyToId: _replyToMessageId,
    );

    // Clear reply if any
    if (_replyToMessageId != null) {
      setState(() {
        _replyToMessageId = null;
      });
    }

    // Scroll to bottom
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessageOptions(Message message) {
    final currentUserId = context.read<AuthProvider>().currentUser?['id'];
    final isOwnMessage = message.senderId == currentUserId;
    final parentContext =
        context; // Use parent context when showing dialogs/snackbars
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    // Determine whether current user can delete this message
    bool canDelete = false;

    if (isOwnMessage) {
      canDelete = true;
    } else if (authProvider.isSuperAdmin) {
      canDelete = true;
    } else {
      // Try to resolve sender participant details from active conversation
      final participant = chatProvider.activeConversation?.participants
          .firstWhere(
            (p) => p.id == message.senderId,
            orElse: () => ChatUser(
              id: message.senderId,
              name: message.senderName ?? 'User',
              email: '',
              avatar: null,
              role: 'member',
            ),
          );

      // MC leader can delete messages sent by users in their MC
      if (authProvider.isMCLeader &&
          participant != null &&
          participant.mcId != null &&
          authProvider.userMCId != null &&
          participant.mcId == authProvider.userMCId) {
        canDelete = true;
      }

      // Branch admin can delete messages sent by users in their branch
      if (authProvider.isBranchAdmin &&
          participant != null &&
          participant.branchId != null &&
          authProvider.userBranchId != null &&
          participant.branchId == authProvider.userBranchId) {
        canDelete = true;
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _replyToMessageId = message.id;
              });
              _messageFocusNode.requestFocus();
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy'),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: message.content));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Message copied')));
            },
          ),
          if (canDelete) ...[
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(context);

                if (!mounted) return;

                final scaffoldMessenger = ScaffoldMessenger.of(parentContext);
                final confirmed = await showDialog<bool>(
                  context: parentContext,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete message'),
                    content: const Text(
                      'Are you sure you want to delete this message? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(parentContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(parentContext).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (!mounted) return;

                if (confirmed == true) {
                  final success = await chatProvider.deleteMessage(message.id);
                  if (!mounted) return;
                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Message deleted')),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          chatProvider.error ?? 'Failed to delete message',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Audio option removed: voice messages are disabled in this branch.
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Photo'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement photo selection
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Video'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement video selection
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: const Text('File'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement file selection
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Location'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement location sharing
            },
          ),
        ],
      ),
    );
  }

  // Voice recording removed: related state and helpers were intentionally removed
  // to disable audio/voice messages in this branch.

  void _handleMenuAction(String action, Conversation conversation) {
    switch (action) {
      case 'info':
        // TODO: Show conversation info
        break;
      case 'search':
        // TODO: Implement message search
        break;
      case 'mute':
        // TODO: Implement conversation muting
        break;
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      // Today: show time
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Older: show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  IconData _getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.done;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _getMessageStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.grey;
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
    }
  }
}

/// Custom painter for typing indicator animation
class TypingIndicatorPainter extends CustomPainter {
  final double animation;

  TypingIndicatorPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;

    final radius = size.width / 8;
    final centerY = size.height / 2;

    // Draw three bouncing dots
    for (int i = 0; i < 3; i++) {
      final progress = (animation + i * 0.2) % 1.0;
      final bounce = (1 - (progress * 2 - 1).abs()) * 3;

      canvas.drawCircle(
        Offset(radius + i * radius * 2.5, centerY - bounce),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TypingIndicatorPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
