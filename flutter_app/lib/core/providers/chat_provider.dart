import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
// path package not required here
import 'package:logger/logger.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/error_tracker.dart';

/// Professional chat state management provider
class ChatProvider with ChangeNotifier {
  static final Logger _logger = Logger();

  // State variables
  List<Conversation> _conversations = [];
  Conversation? _activeConversation;
  List<Message> _messages = [];
  final Map<int, TypingIndicator> _typingIndicators = {};
  final Map<int, bool> _userOnlineStatus = {};

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
  Map<int, bool> get userOnlineStatus => Map.unmodifiable(_userOnlineStatus);

  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSendingMessage => _isSendingMessage;
  bool get isConnected => _isConnected;
  String? get error => _error;

  /// Get typing indicators for active conversation
  List<TypingIndicator> get typingIndicators {
    if (_activeConversation == null) return [];

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

      _conversations = conversations;
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

      final lastMessageId = loadMore && _messages.isNotEmpty
          ? int.tryParse(_messages.last.id)
          : null;

      final messages = await ChatService.getMessages(
        conversationId: conversationId,
        lastMessageId: lastMessageId,
      );

      if (loadMore) {
        _messages.addAll(messages);
      } else {
        _messages = messages;
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

      final message = await ChatService.sendMessage(
        conversationId: _activeConversation!.id,
        content: content.trim(),
        replyToId: replyToId,
      );

      _logger.i('Message sent successfully');
      return message;
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

  /// Send a file message
  Future<Message?> sendFileMessage({
    required String filePath,
    required String fileName,
    required MessageType type,
    String? content,
  }) async {
    if (_activeConversation == null) {
      _setError('No active conversation');
      return null;
    }

    _setSendingMessage(true);
    _clearError();

    try {
      _logger.d(
        'Sending file message to conversation ${_activeConversation!.id}',
      );

      // Upload file to server and obtain a public URL. The backend may
      // expose an uploads/files endpoint that accepts multipart form-data.
      String? fileUrl;
      try {
        final file = await MultipartFile.fromFile(filePath, filename: fileName);

        final formData = FormData();
        // Use key 'file' - adjust if backend expects a different key
        formData.files.add(MapEntry('file', file));

        final uploadResp = await ApiService.post('/files', data: formData);

        // Attempt to locate the returned URL from common response shapes

        if (uploadResp['url'] != null) {
          fileUrl = uploadResp['url'] as String?;
        } else if (uploadResp['file_url'] != null) {
          fileUrl = uploadResp['file_url'] as String?;
        } else if (uploadResp['data'] is Map &&
            uploadResp['data']['url'] != null) {
          fileUrl = uploadResp['data']['url'] as String?;
        } else if (uploadResp['data'] is Map &&
            uploadResp['data']['file_url'] != null) {
          fileUrl = uploadResp['data']['file_url'] as String?;
        }
      } catch (e) {
        _logger.w('File upload failed: $e - falling back to local file name');
      }

      // If upload didn't return a URL, we'll still send the message with the
      // fileName so the server/client can handle it or the backend can accept
      // the file via another flow. Prefer to include fileUrl when available.
      final message = await ChatService.sendMessage(
        conversationId: _activeConversation!.id,
        content: content ?? fileName,
        type: type,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: File(filePath).existsSync()
            ? File(filePath).lengthSync()
            : null,
      );

      _logger.i('File message sent successfully');
      return message;
    } catch (e) {
      _logger.e('Failed to send file message: $e');
      _setError('Failed to send file: ${e.toString()}');
      ErrorTracker.logError(
        'Failed to send file message: $e',
        context: 'ChatProvider.sendFileMessage',
      );
      return null;
    } finally {
      _setSendingMessage(false);
    }
  }

  /// Create new conversation
  Future<Conversation?> createConversation({
    required String name,
    required List<int> participantIds,
    ConversationType type = ConversationType.group,
    String? description,
  }) async {
    _clearError();

    try {
      _logger.d('💡 Attempting to create conversation: $name');

      final conversation = await ChatService.createConversation(
        name: name,
        participantIds: participantIds,
        type: type,
        description: description,
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

      // Remove from local messages
      _messages.removeWhere((m) => m.id == messageId);

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

    notifyListeners();
  }

  /// Handle conversation update from stream
  void _handleConversationUpdate(Conversation conversation) {
    _logger.d('Handling conversation update: ${conversation.id}');

    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      _conversations[index] = conversation;
    } else {
      _conversations.insert(0, conversation);
    }

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
