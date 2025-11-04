import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
// path package not required here
import 'package:logger/logger.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
// api_service and multipart uploads removed along with file sharing
import '../utils/error_tracker.dart';

/// Professional chat state management provider
class ChatProvider with ChangeNotifier {
  static final Logger _logger = Logger();

  // State variables
  List<Conversation> _conversations = [];
  Conversation? _activeConversation;
  List<Message> _messages = [];
  // Comments (replies) cache: messageId -> list of comment messages
  final Map<String, List<Message>> _messageComments = {};
  final Map<String, bool> _messageCommentsLoading = {};
  final Map<String, int> _messageCommentCounts = {};
  final Map<String, bool> _messageCommentCountLoading = {};
  final Map<int, TypingIndicator> _typingIndicators = {};
  final Map<int, bool> _userOnlineStatus = {};
  // Pending edits keyed by clientId (optimistic id) -> new content
  final Map<String, String> _pendingEdits = {};

  // Category tracking to prevent repeated loads
  String? _currentCategory;

  // Loading states
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;

  // Connection state
  bool _isConnected = false;

  // Error handling
  String? _error;

  // Stream subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _conversationSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _userStatusSubscription;

  // Getters
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  Conversation? get activeConversation => _activeConversation;
  List<Message> get messages => List.unmodifiable(_messages);
  List<Message> getCommentsFor(String messageId) =>
      List.unmodifiable(_messageComments[messageId] ?? []);

  bool isCommentsLoading(String messageId) =>
      _messageCommentsLoading[messageId] == true;
  int? getCommentCount(String messageId) => _messageCommentCounts[messageId];
  bool isCommentCountLoading(String messageId) =>
      _messageCommentCountLoading[messageId] == true;
  Map<int, bool> get userOnlineStatus => Map.unmodifiable(_userOnlineStatus);

  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSendingMessage => _isSendingMessage;
  bool get isConnected => _isConnected;
  String? get error => _error;

  /// Get typing indicators for active conversation
  List<TypingIndicator> get typingIndicators {
    if (_activeConversation == null) {
      return [];
    }

    final currentTime = DateTime.now();
    final activeIndicators = _typingIndicators.values
        .where(
          (indicator) =>
              indicator.conversationId == _activeConversation!.id &&
              indicator.userId != AuthService.getCurrentUserId() &&
              currentTime.difference(indicator.timestamp).inSeconds < 5,
        )
        .toList();

    return activeIndicators;
  }

  /// Initialize chat provider
  Future<void> init() async {
    try {
      _logger.i('Initializing ChatProvider');

      // Load cached data first
      _conversations = ChatService.getCachedConversations();
      notifyListeners();

      // Initialize chat service
      await ChatService.init();

      // Set up event listeners
      _setupEventListeners();

      // Load conversations from server
      await loadConversations();

      _logger.i('ChatProvider initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize ChatProvider: $e');
      // Show a user-friendly message instead of technical error
      _setError(
        'Chat feature is temporarily unavailable. Please check back later.',
      );
      ErrorTracker.logError(
        'Failed to initialize ChatProvider: $e',
        context: 'ChatProvider.init',
      );
    }
  }

  /// Set up event listeners for real-time updates
  void _setupEventListeners() {
    // Listen to new messages
    _messageSubscription = ChatService.messageStream.listen(
      (message) {
        _handleNewMessage(message);
      },
      onError: (error) {
        _logger.e('Message stream error: $error');
        ErrorTracker.logError(
          'Message stream error: $error',
          context: 'ChatProvider.messageStream',
        );
      },
    );

    // Listen to conversation updates
    _conversationSubscription = ChatService.conversationStream.listen(
      (conversation) {
        _handleConversationUpdate(conversation);
      },
      onError: (error) {
        _logger.e('Conversation stream error: $error');
        ErrorTracker.logError(
          'Conversation stream error: $error',
          context: 'ChatProvider.conversationStream',
        );
      },
    );

    // Listen to typing indicators
    _typingSubscription = ChatService.typingStream.listen(
      (typing) {
        _handleTypingIndicator(typing);
      },
      onError: (error) {
        _logger.e('Typing stream error: $error');
      },
    );

    // Listen to connection status
    _connectionSubscription = ChatService.connectionStream.listen(
      (connected) {
        _isConnected = connected;
        if (!connected) {
          _setError('Connection lost. Messages will be sent when reconnected.');
        } else {
          _clearError();
        }
        notifyListeners();
      },
      onError: (error) {
        _logger.e('Connection stream error: $error');
      },
    );

    // Listen to user status updates
    _userStatusSubscription = ChatService.userStatusStream.listen(
      (statusData) {
        final userId = statusData['user_id'] as int?;
        final isOnline = statusData['is_online'] as bool?;

        if (userId != null && isOnline != null) {
          _userOnlineStatus[userId] = isOnline;
          notifyListeners();
        }
      },
      onError: (error) {
        _logger.e('User status stream error: $error');
      },
    );
  }

  /// Load conversations from server
  Future<void> loadConversations() async {
    if (_isLoadingConversations) return;

    _setLoadingConversations(true);
    _clearError();

    try {
      _logger.d('Loading conversations');
      final conversations = await ChatService.getConversations();

      _conversations = conversations;
      notifyListeners();

      _logger.i('Loaded ${conversations.length} conversations');
    } catch (e) {
      _logger.e('Failed to load conversations: $e');
      _setError(
        'Chat feature is temporarily unavailable. Please check back later.',
      );
      ErrorTracker.logError(
        'Failed to load conversations: $e',
        context: 'ChatProvider.loadConversations',
      );
    } finally {
      _setLoadingConversations(false);
    }
  }

  /// Load conversations by category (All, Groups, MC, Branch)
  Future<void> loadConversationsByCategory(String category) async {
    if (_isLoadingConversations) return;

    // Check if we're already loading or have loaded this category
    if (_currentCategory == category && _conversations.isNotEmpty) {
      _logger.d('Conversations for category $category already loaded');
      return;
    }

    _setLoadingConversations(true);
    _clearError();

    try {
      _logger.d('Loading conversations for category: $category');
      final conversations = await ChatService.getConversationsByCategory(
        category,
      );

      // Ensure we don't keep duplicates if the service returned items that
      // accidentally contain repeated entries. Normalize by id to preserve
      // insertion order from the server while removing duplicates.
      final unique = <int, Conversation>{};
      for (final c in conversations) {
        unique[c.id] = c;
      }
      _conversations = unique.values.toList();
      _currentCategory = category;
      notifyListeners();

      _logger.i(
        'Loaded ${conversations.length} conversations for category $category',
      );
    } catch (e) {
      _logger.e('Failed to load conversations for category $category: $e');
      _setError('Unable to load $category conversations. Please try again.');
      ErrorTracker.logError(
        'Failed to load conversations for category $category: $e',
        context: 'ChatProvider.loadConversationsByCategory',
      );
    } finally {
      _setLoadingConversations(false);
    }
  }

  /// Reset category to force reload when switching tabs
  void resetCategory() {
    _currentCategory = null;
    _conversations.clear();
    notifyListeners();
  }

  /// Load messages for a specific conversation
  Future<void> loadMessages(int conversationId, {bool loadMore = false}) async {
    if (_isLoadingMessages && !loadMore) return;

    try {
      _logger.d('Loading messages for conversation $conversationId');

      if (!loadMore) {
        _setLoadingMessages(true);
        _clearError();

        // Clear existing messages when loading new conversation
        _messages.clear();
        notifyListeners();
      }

      // Determine pagination cursor: find the last message with a numeric id.
      // Optimistic local messages may use UUIDs as ids, so int.tryParse on
      // the last element can return null and cause the server to return the
      // first page repeatedly. Scan backwards for the last numeric id.
      final lastMessageId = loadMore ? _getLastNumericMessageId() : null;

      final messages = await ChatService.getMessages(
        conversationId: conversationId,
        lastMessageId: lastMessageId,
      );

      if (loadMore) {
        // Append only messages that are not already present (dedupe by id).
        final existingIds = _messages.map((m) => m.id).toSet();
        for (final m in messages) {
          if (!existingIds.contains(m.id)) {
            _messages.add(m);
            existingIds.add(m.id);
          }
        }
      } else {
        // Replace list with server-provided messages but ensure uniqueness
        // in case the server returned duplicates.
        final unique = <String, Message>{};
        for (final m in messages) {
          unique[m.id] = m;
        }
        _messages = unique.values.toList();
      }

      // Mark messages as read
      final unreadMessageIds = _messages
          .where(
            (m) =>
                m.senderId != AuthService.getCurrentUserId() &&
                m.readAt == null,
          )
          .map((m) => m.id)
          .toList();

      if (unreadMessageIds.isNotEmpty) {
        markMessagesAsRead(conversationId, unreadMessageIds);
      }

      notifyListeners();

      _logger.i(
        'Loaded ${messages.length} messages for conversation $conversationId',
      );
    } catch (e) {
      _logger.e('Failed to load messages: $e');
      _setError('Failed to load messages: ${e.toString()}');
      ErrorTracker.logError(
        'Failed to load messages: $e',
        context: 'ChatProvider.loadMessages',
      );
    } finally {
      if (!loadMore) {
        _setLoadingMessages(false);
      }
    }
  }

  /// Set active conversation
  Future<void> setActiveConversation(Conversation conversation) async {
    _logger.d('Setting active conversation: ${conversation.name}');

    _activeConversation = conversation;
    _typingIndicators.clear();

    // Load messages for this conversation
    await loadMessages(conversation.id);
    // Clear comments cache when switching conversations
    _messageComments.clear();
    _messageCommentsLoading.clear();
  }

  /// Load comments (replies) for a specific message
  Future<void> loadCommentsForMessage(String messageId) async {
    if (_activeConversation == null) return;
    if (_messageCommentsLoading[messageId] == true) return;

    _messageCommentsLoading[messageId] = true;
    notifyListeners();

    try {
      final comments = await ChatService.getComments(
        conversationId: _activeConversation!.id,
        messageId: messageId,
      );

      // Deduplicate and store
      final unique = <String, Message>{};
      for (final c in comments) {
        unique[c.id] = c;
      }
      _messageComments[messageId] = unique.values.toList();
      // Update cached count
      _messageCommentCounts[messageId] = _messageComments[messageId]!.length;
    } catch (e) {
      _logger.e('Failed to load comments for $messageId: $e');
    } finally {
      _messageCommentsLoading[messageId] = false;
      notifyListeners();
    }
  }

  /// Load only the comment count for a message. Uses a lightweight API if
  /// available; falls back to fetching the full comment list.
  Future<void> loadCommentCount(String messageId) async {
    if (_activeConversation == null) return;
    if (_messageCommentCountLoading[messageId] == true) return;

    _messageCommentCountLoading[messageId] = true;
    notifyListeners();

    try {
      final count = await ChatService.getCommentCount(
        conversationId: _activeConversation!.id,
        messageId: messageId,
      );
      _messageCommentCounts[messageId] = count;
    } catch (e) {
      _logger.e('Failed to load comment count for $messageId: $e');
    } finally {
      _messageCommentCountLoading[messageId] = false;
      notifyListeners();
    }
  }

  /// Send a text message
  Future<Message?> sendMessage({
    required String content,
    String? replyToId,
  }) async {
    if (_activeConversation == null) {
      _setError('No active conversation');
      return null;
    }

    if (content.trim().isEmpty) {
      _setError('Message cannot be empty');
      return null;
    }

    _setSendingMessage(true);
    _clearError();

    try {
      _logger.d('Sending message to conversation ${_activeConversation!.id}');

      // Optimistic UI: create a client-generated id (UUID) and insert a
      // temporary local message so the chat stays responsive while the
      // network call completes. Using UUID lets us reconcile with the server
      // response using the same id as a deduplication key.
      final clientId = const Uuid().v4();
      final currentUserId = AuthService.getCurrentUserId() ?? 0;
      final currentUser = AuthService.getCurrentUser();
      final localSenderName = currentUser != null ? currentUser['name'] : null;

      final tempMessage = Message(
        id: clientId,
        conversationId: _activeConversation!.id,
        senderId: currentUserId,
        senderName: localSenderName,
        content: content.trim(),
        status: MessageStatus.sending,
        createdAt: DateTime.now(),
      );

      // Append locally and update conversation preview
      _messages.add(tempMessage);
      _activeConversation = _activeConversation!.copyWith(
        lastMessage: tempMessage,
      );
      final convIndex = _conversations.indexWhere(
        (c) => c.id == _activeConversation!.id,
      );
      if (convIndex != -1) {
        _conversations[convIndex] = _activeConversation!;
      }
      notifyListeners();

      // Send to server
      final serverMessage = await ChatService.sendMessage(
        conversationId: _activeConversation!.id,
        content: content.trim(),
        replyToId: replyToId,
        clientId: clientId,
      );

      // Replace temp message with server message if temp still present
      final tempIndex = _messages.indexWhere((m) => m.id == clientId);
      final existingServerIndex = _messages.indexWhere(
        (m) => m.id == serverMessage.id,
      );

      if (existingServerIndex != -1) {
        // Server message already present (e.g., via socket); remove temp
        if (tempIndex != -1) {
          _messages.removeAt(tempIndex);
        }
      } else if (tempIndex != -1) {
        _messages[tempIndex] = serverMessage;
      } else {
        // Fallback: append server message
        _messages.add(serverMessage);
      }

      // Update conversation preview to server message
      _activeConversation = _activeConversation!.copyWith(
        lastMessage: serverMessage,
      );
      if (convIndex != -1) {
        _conversations[convIndex] = _activeConversation!;
      }

      notifyListeners();

      _logger.i('Message sent successfully');
      return serverMessage;
    } catch (e) {
      _logger.e('Failed to send message: $e');
      _setError('Failed to send message: ${e.toString()}');
      ErrorTracker.logError(
        'Failed to send message: $e',
        context: 'ChatProvider.sendMessage',
      );
      return null;
    } finally {
      _setSendingMessage(false);
    }
  }

  /// Retry sending a failed message.
  Future<bool> retrySend(String messageId) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return false;

    final msg = _messages[idx];
    // mark sending
    _messages[idx] = msg.copyWith(status: MessageStatus.sending);
    notifyListeners();

    try {
      final serverMessage = await ChatService.sendMessage(
        conversationId: msg.conversationId,
        content: msg.content,
        replyToId: msg.replyToId,
        clientId: msg.clientId ?? msg.id,
      );

      // Replace local entry
      final newIdx = _messages.indexWhere((m) => m.id == msg.id);
      if (newIdx != -1) {
        _messages[newIdx] = serverMessage;
      } else {
        _messages.add(serverMessage);
      }

      // Update conversation preview
      if (_activeConversation != null &&
          _activeConversation!.id == serverMessage.conversationId) {
        _activeConversation = _activeConversation!.copyWith(
          lastMessage: serverMessage,
        );
        final convIndex = _conversations.indexWhere(
          (c) => c.id == _activeConversation!.id,
        );
        if (convIndex != -1) _conversations[convIndex] = _activeConversation!;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Retry send failed: $e');
      // mark failed
      final failedIdx = _messages.indexWhere((m) => m.id == messageId);
      if (failedIdx != -1) {
        _messages[failedIdx] = _messages[failedIdx].copyWith(
          status: MessageStatus.failed,
        );
        notifyListeners();
      }
      return false;
    }
  }

  /// Send a file message
  Future<Message?> sendFileMessage({
    required String filePath,
    required String fileName,
    required MessageType type,
    String? content,
  }) async {
    // File sharing is temporarily disabled in this branch. Return null and
    // set a user-facing error so the UI can show a message if needed.
    _setError('File sharing is temporarily disabled.');
    return null;
  }

  /// Create new conversation
  Future<Conversation?> createConversation({
    required String name,
    List<int>? participantIds,
    ConversationType type = ConversationType.group,
    String? description,
    int? branchId,
    int? mcId,
  }) async {
    _clearError();

    try {
      _logger.d('💡 Attempting to create conversation: $name');

      final conversation = await ChatService.createConversation(
        name: name,
        participantIds: participantIds,
        type: type,
        description: description,
        branchId: branchId,
        mcId: mcId,
      );

      // Add to conversations list
      _conversations.insert(0, conversation);
      notifyListeners();

      _logger.i('Conversation created successfully: ${conversation.id}');
      return conversation;
    } catch (e) {
      // Check if it's the expected "unavailable" error
      if (e.toString().contains('temporarily unavailable') ||
          e.toString().contains('not implemented')) {
        _logger.i('💡 Chat creation temporarily disabled');
        _setError(
          'Chat feature is temporarily unavailable. Please check back later.',
        );
      } else {
        _logger.e('❌ Unexpected error creating conversation: $e');
        _setError('Unable to create conversation at this time.');
      }

      // Don't log to error tracker for expected unavailable errors
      if (!e.toString().contains('temporarily unavailable') &&
          !e.toString().contains('not implemented')) {
        ErrorTracker.logError(
          'Unexpected chat creation error: $e',
          context: 'ChatProvider.createConversation',
        );
      }
      return null;
    }
  }

  /// Get or create category-based conversation (Branch/MC)
  Future<Conversation?> getOrCreateCategoryConversation({
    required ConversationType type,
    required int categoryId,
  }) async {
    _clearError();

    try {
      _logger.d(
        'Getting/creating category conversation: $type, ID: $categoryId',
      );

      final conversation = await ChatService.getOrCreateCategoryConversation(
        type: type,
        categoryId: categoryId,
      );

      // Check if conversation already exists in the list
      final existingIndex = _conversations.indexWhere(
        (c) => c.id == conversation.id,
      );
      if (existingIndex != -1) {
        // Update existing conversation
        _conversations[existingIndex] = conversation;
      } else {
        // Add new conversation to the top of the list
        _conversations.insert(0, conversation);
      }

      notifyListeners();

      _logger.i('Category conversation ready: ${conversation.id}');
      return conversation;
    } catch (e) {
      _logger.e('Failed to get/create category conversation: $e');
      _setError('Unable to access ${type.name} chat at this time.');
      ErrorTracker.logError(
        'Failed to get/create category conversation: $e',
        context: 'ChatProvider.getOrCreateCategoryConversation',
      );
      return null;
    }
  }

  /// Delete a message by id. Permission checks should be done in the UI layer.
  Future<bool> deleteMessage(String messageId) async {
    if (_activeConversation == null) {
      _setError('No active conversation');
      return false;
    }

    try {
      await ChatService.deleteMessage(messageId: messageId);

      // Instead of removing the message from the list, mark it as deleted
      // and replace it with a placeholder so the chat keeps its position.
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        final orig = _messages[idx];
        final placeholder = orig.copyWith(
          content: '',
          type: MessageType.system,
          metadata: (orig.metadata ?? {})..addAll({'deleted': true}),
          isEncrypted: false,
          isDeleted: true,
        );
        _messages[idx] = placeholder;
      }

      // If this was the last message for the conversation, update conversation preview
      if (_activeConversation != null &&
          _activeConversation!.lastMessage?.id == messageId) {
        final newLast = _messages.isNotEmpty ? _messages.first : null;
        _activeConversation = _activeConversation!.copyWith(
          lastMessage: newLast,
        );
        final convIndex = _conversations.indexWhere(
          (c) => c.id == _activeConversation!.id,
        );
        if (convIndex != -1) {
          _conversations[convIndex] = _activeConversation!;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Failed to delete message: $e');
      _setError('Failed to delete message. Please try again.');
      return false;
    }
  }

  /// Edit an existing message's content. Only allowed if the message was sent
  /// less than 2 minutes ago (client-side enforcement). Returns the updated
  /// message on success, or null on failure.
  Future<Message?> editMessage(String messageId, String newContent) async {
    if (_activeConversation == null) {
      _setError('No active conversation');
      return null;
    }

    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) {
      _setError('Message not found');
      return null;
    }

    final message = _messages[idx];

    // Check 2-minute window
    final now = DateTime.now();
    final age = now.difference(message.createdAt).inSeconds;
    if (age > 120) {
      _setError('Edit window has expired');
      return null;
    }

    // If the message is still in 'sending' state (optimistic local message),
    // queue the edit and auto-apply it when the authoritative message arrives.
    if (message.status == MessageStatus.sending) {
      if (message.clientId != null && message.clientId!.isNotEmpty) {
        _pendingEdits[message.clientId!] = newContent;
        _setError('Edit queued and will be applied when message is confirmed');
        return null;
      }

      // If no clientId is available, fall back to informing the user.
      _setError('Message is still sending. Please try editing again shortly.');
      return null;
    }

    _setSendingMessage(true);
    _clearError();

    try {
      final updated = await ChatService.editMessage(
        messageId: messageId,
        content: newContent,
      );

      // Update in local message list
      final mIdx = _messages.indexWhere((m) => m.id == updated.id);
      if (mIdx != -1) {
        _messages[mIdx] = updated;
      }

      // Update cached conversation last message if applicable
      if (_activeConversation != null &&
          _activeConversation!.lastMessage?.id == updated.id) {
        _activeConversation = _activeConversation!.copyWith(
          lastMessage: updated,
        );
        final convIndex = _conversations.indexWhere(
          (c) => c.id == _activeConversation!.id,
        );
        if (convIndex != -1) _conversations[convIndex] = _activeConversation!;
      }

      notifyListeners();
      return updated;
    } catch (e) {
      _setError('Failed to edit message: ${e.toString()}');
      return null;
    } finally {
      _setSendingMessage(false);
    }
  }

  /// Send typing indicator
  void sendTypingIndicator() {
    if (_activeConversation != null) {
      ChatService.sendTypingIndicator(_activeConversation!.id);
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(
    int conversationId,
    List<String> messageIds,
  ) async {
    try {
      await ChatService.markMessagesAsRead(
        conversationId: conversationId,
        messageIds: messageIds,
      );

      // Update local messages
      for (int i = 0; i < _messages.length; i++) {
        if (messageIds.contains(_messages[i].id)) {
          _messages[i] = _messages[i].copyWith(
            readAt: DateTime.now(),
            status: MessageStatus.read,
          );
        }
      }

      notifyListeners();
    } catch (e) {
      _logger.e('Failed to mark messages as read: $e');
    }
  }

  /// Handle new message from stream
  void _handleNewMessage(Message message) {
    _logger.d('Handling new message: ${message.id}');

    // Update conversation in list
    final conversationIndex = _conversations.indexWhere(
      (c) => c.id == message.conversationId,
    );
    if (conversationIndex != -1) {
      final conversation = _conversations[conversationIndex];
      final updatedConversation = conversation.copyWith(
        lastMessage: message,
        unreadCount: message.senderId != AuthService.getCurrentUserId()
            ? conversation.unreadCount + 1
            : conversation.unreadCount,
      );

      _conversations[conversationIndex] = updatedConversation;

      // Move conversation to top
      _conversations.removeAt(conversationIndex);
      _conversations.insert(0, updatedConversation);
    }

    // Add to messages if it's for active conversation
    if (_activeConversation?.id == message.conversationId) {
      final existingIndex = _messages.indexWhere((m) => m.id == message.id);
      if (existingIndex == -1) {
        // Append new messages to the end so newest appears at bottom
        _messages.add(message);
      } else {
        _messages[existingIndex] = message;
      }
    }

    // If this message has a clientId and there is a pending edit for it,
    // perform the edit now on the authoritative server id.
    if (message.clientId != null &&
        _pendingEdits.containsKey(message.clientId!)) {
      final newContent = _pendingEdits.remove(message.clientId!);
      if (newContent != null) {
        // Fire-and-forget the edit; update local message when server responds
        ChatService.editMessage(messageId: message.id, content: newContent)
            .then((updated) {
              // Replace or update local cache
              final idx = _messages.indexWhere((m) => m.id == updated.id);
              if (idx != -1) {
                _messages[idx] = updated;
              }

              // Update conversation preview if needed
              if (_activeConversation != null &&
                  _activeConversation!.lastMessage?.id == updated.id) {
                _activeConversation = _activeConversation!.copyWith(
                  lastMessage: updated,
                );
                final convIndex = _conversations.indexWhere(
                  (c) => c.id == _activeConversation!.id,
                );
                if (convIndex != -1) {
                  _conversations[convIndex] = _activeConversation!;
                }
              }
              notifyListeners();
            })
            .catchError((e) {
              // If edit failed, optionally enqueue or notify user. For now, set error.
              _setError('Auto-applied edit failed: $e');
            });
      }
    }

    notifyListeners();
  }

  /// Handle conversation update from stream
  void _handleConversationUpdate(Conversation conversation) {
    _logger.d('Handling conversation update: ${conversation.id}');

    // Remove any existing occurrences to avoid duplicates, then insert the
    // updated conversation at the top so it appears first in the list.
    _conversations.removeWhere((c) => c.id == conversation.id);
    _conversations.insert(0, conversation);

    if (_activeConversation?.id == conversation.id) {
      _activeConversation = conversation;
    }

    notifyListeners();
  }

  /// Handle typing indicator from stream
  void _handleTypingIndicator(TypingIndicator typing) {
    if (typing.userId == AuthService.getCurrentUserId()) {
      return; // Ignore our own typing
    }

    _typingIndicators[typing.userId] = typing;

    // Remove typing indicator after 5 seconds
    Timer(const Duration(seconds: 5), () {
      _typingIndicators.remove(typing.userId);
      notifyListeners();
    });

    notifyListeners();
  }

  /// Clear active conversation
  void clearActiveConversation() {
    _activeConversation = null;
    _messages.clear();
    _typingIndicators.clear();
    notifyListeners();
  }

  /// Refresh conversations
  Future<void> refresh() async {
    await loadConversations();
    if (_activeConversation != null) {
      await loadMessages(_activeConversation!.id);
    }
  }

  /// Get conversation by ID
  Conversation? getConversationById(int id) {
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Find the last numeric message id in the current message list.
  ///
  /// Optimistic messages use UUIDs which can't be parsed to int. When
  /// paginating we must pass a numeric `before_id` cursor to the API, so
  /// scan from the end for the most recent numeric id.
  int? _getLastNumericMessageId() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      final idStr = _messages[i].id;
      final parsed = int.tryParse(idStr);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Get unread message count for all conversations
  int get totalUnreadCount {
    return _conversations.fold(
      0,
      (sum, conversation) => sum + conversation.unreadCount,
    );
  }

  /// Search conversations
  List<Conversation> searchConversations(String query) {
    if (query.isEmpty) return _conversations;

    final lowercaseQuery = query.toLowerCase();
    return _conversations.where((conversation) {
      return conversation.name.toLowerCase().contains(lowercaseQuery) ||
          (conversation.description?.toLowerCase().contains(lowercaseQuery) ??
              false);
    }).toList();
  }

  // State management helpers
  void _setLoadingConversations(bool loading) {
    _isLoadingConversations = loading;
    notifyListeners();
  }

  void _setLoadingMessages(bool loading) {
    _isLoadingMessages = loading;
    notifyListeners();
  }

  void _setSendingMessage(bool sending) {
    _isSendingMessage = sending;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _logger.i('Disposing ChatProvider');

    // Cancel all subscriptions
    _messageSubscription?.cancel();
    _conversationSubscription?.cancel();
    _typingSubscription?.cancel();
    _connectionSubscription?.cancel();
    _userStatusSubscription?.cancel();

    super.dispose();
  }
}
