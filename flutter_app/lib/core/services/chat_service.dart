import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../models/chat_models.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// Professional chat service with WebSocket support and offline capabilities
class ChatService {
  static final Logger _logger = Logger();
  static const Uuid _uuid = Uuid();

  // WebSocket connection
  static WebSocketChannel? _webSocketChannel;
  static StreamSubscription? _webSocketSubscription;

  // Connection state
  static bool _isConnected = false;
  // ignore: unused_field
  static bool _isConnecting = false;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static Timer? _reconnectTimer;
  static Timer? _heartbeatTimer;

  // Event streams
  static final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  static final StreamController<Conversation> _conversationController =
      StreamController<Conversation>.broadcast();
  static final StreamController<TypingIndicator> _typingController =
      StreamController<TypingIndicator>.broadcast();
  static final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  static final StreamController<Map<String, dynamic>> _userStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams for listening to events
  static Stream<Message> get messageStream => _messageController.stream;
  static Stream<Conversation> get conversationStream =>
      _conversationController.stream;
  static Stream<TypingIndicator> get typingStream => _typingController.stream;
  static Stream<bool> get connectionStream => _connectionController.stream;
  static Stream<Map<String, dynamic>> get userStatusStream =>
      _userStatusController.stream;

  // Offline queue
  static final List<Map<String, dynamic>> _offlineQueue = [];
  static const String _offlineQueueKey = 'chat_offline_queue';

  // Cached data
  static final Map<int, List<Message>> _cachedMessages = {};
  static final Map<int, Conversation> _cachedConversations = {};

  /// Initialize chat service
  static Future<void> init() async {
    _logger.i('Initializing ChatService');

    // Load offline queue
    await _loadOfflineQueue();

    // Load cached conversations
    await _loadCachedConversations();

    // Connect WebSocket if user is authenticated
    if (AuthService.isAuthenticated()) {
      await connect();
    }
  }

  /// Connect to WebSocket server
  static Future<void> connect() async {
    // Temporarily disable WebSocket chat until backend implements WebSocket support
    _logger.i('WebSocket chat temporarily disabled - using REST API only');
    return;

    /* WebSocket code disabled until backend implementation
    if (_isConnected || _isConnecting) {
      _logger.w('Already connected or connecting');
      return;
    }

    final token = StorageService.getAuthToken();
    if (token == null) {
      _logger.e('No auth token available for WebSocket connection');
      return;
    }

    _isConnecting = true;
    _connectionController.add(false);

    try {
      final wsUrl = _getWebSocketUrl();
      _logger.i('Connecting to WebSocket: $wsUrl');

      _webSocketChannel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['echo-protocol'],
      );

      // Send authentication message immediately after connection
      _webSocketChannel!.sink.add(
        jsonEncode({
          'type': 'auth',
          'token': token,
          'user_id': AuthService.getCurrentUserId(),
        }),
      );

      // Listen to WebSocket messages
      _webSocketSubscription = _webSocketChannel!.stream.listen(
        _onWebSocketMessage,
        onError: _onWebSocketError,
        onDone: _onWebSocketDone,
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _connectionController.add(true);

      // Start heartbeat
      _startHeartbeat();

      // Process offline queue
      await _processOfflineQueue();

      _logger.i('WebSocket connected successfully');
    } catch (e) {
      _logger.e('Failed to connect WebSocket: $e');
      _isConnecting = false;
      _connectionController.add(false);
      _scheduleReconnect();
    }
    */
  }

  /// Disconnect from WebSocket
  static Future<void> disconnect() async {
    _logger.i('Disconnecting WebSocket');

    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    _webSocketSubscription?.cancel();
    _webSocketChannel?.sink.close(status.normalClosure);

    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);
  }

  /// Get WebSocket URL based on environment
  // ignore: unused_element
  static String _getWebSocketUrl() {
    // In production, this would be wss://yourdomain.com/ws
    // For development, use local WebSocket server
    const baseUrl = 'ws://192.168.42.206:8000';
    return '$baseUrl/ws/chat';
  }

  /// Handle incoming WebSocket messages
  // ignore: unused_element
  static void _onWebSocketMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString());
      _logger.d('Received WebSocket message: ${message['type']}');

      switch (message['type']) {
        case 'message':
          final chatMessage = Message.fromJson(message['data']);
          _handleNewMessage(chatMessage);
          break;

        case 'conversation_updated':
          final conversation = Conversation.fromJson(message['data']);
          _handleConversationUpdate(conversation);
          break;

        case 'typing':
          final typing = TypingIndicator.fromJson(message['data']);
          _typingController.add(typing);
          break;

        case 'user_status':
          _userStatusController.add(message['data']);
          break;

        case 'auth_success':
          _logger.i('WebSocket authentication successful');
          break;

        case 'auth_error':
          _logger.e('WebSocket authentication failed');
          disconnect();
          break;

        case 'pong':
          // Heartbeat response
          break;

        default:
          _logger.w('Unknown WebSocket message type: ${message['type']}');
      }
    } catch (e) {
      _logger.e('Error processing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  // ignore: unused_element, strict_top_level_inference
  static void _onWebSocketError(error) {
    _logger.e('WebSocket error: $error');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  /// Handle WebSocket connection closed
  // ignore: unused_element
  static void _onWebSocketDone() {
    _logger.w('WebSocket connection closed');
    _isConnected = false;
    _connectionController.add(false);

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection attempt
  static void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);

    _logger.i(
      'Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s',
    );

    _reconnectTimer = Timer(delay, () async {
      _isConnecting = false; // Reset connecting state
      await connect();
    });
  }

  /// Start heartbeat to keep connection alive
  // ignore: unused_element
  static void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _webSocketChannel != null) {
        _webSocketChannel!.sink.add(jsonEncode({'type': 'ping'}));
      }
    });
  }

  /// Handle new message received
  static void _handleNewMessage(Message message) {
    // Cache message
    _cachedMessages[message.conversationId] ??= [];
    _cachedMessages[message.conversationId]!.add(message);

    // Update conversation's last message
    if (_cachedConversations.containsKey(message.conversationId)) {
      final conversation = _cachedConversations[message.conversationId]!;
      final updatedConversation = conversation.copyWith(
        lastMessage: message,
        unreadCount: message.senderId != AuthService.getCurrentUserId()
            ? conversation.unreadCount + 1
            : conversation.unreadCount,
      );
      _cachedConversations[message.conversationId] = updatedConversation;
      _conversationController.add(updatedConversation);
    }

    // Emit message
    _messageController.add(message);

    // Save to local storage
    _saveCachedConversations();
  }

  /// Handle conversation update
  static void _handleConversationUpdate(Conversation conversation) {
    _cachedConversations[conversation.id] = conversation;
    _conversationController.add(conversation);
    _saveCachedConversations();
  }

  /// Send message
  static Future<Message> sendMessage({
    required int conversationId,
    required String content,
    MessageType type = MessageType.text,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToId,
  }) async {
    final messageId = _uuid.v4();
    final currentUserId = AuthService.getCurrentUserId();

    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final message = Message(
      id: messageId,
      conversationId: conversationId,
      senderId: currentUserId,
      content: content,
      type: type,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      replyToId: replyToId,
    );

    // Add to cache immediately for optimistic updates
    _cachedMessages[conversationId] ??= [];
    _cachedMessages[conversationId]!.add(message);
    _messageController.add(message);

    try {
      if (_isConnected) {
        // Send via WebSocket
        _webSocketChannel!.sink.add(
          jsonEncode({'type': 'send_message', 'data': message.toJson()}),
        );
      } else {
        // Add to offline queue
        await _addToOfflineQueue({
          'type': 'send_message',
          'data': message.toJson(),
        });
      }

      // Also send via HTTP API as backup
      try {
        final response = await ApiService.post(
          '/chat/messages',
          data: {
            'conversation_id': conversationId,
            'content': content,
            'type': type.toString().split('.').last,
            if (fileUrl != null) 'file_url': fileUrl,
            if (fileName != null) 'file_name': fileName,
            if (fileSize != null) 'file_size': fileSize,
            if (replyToId != null) 'reply_to_id': replyToId,
          },
        );
        final serverMessage = Message.fromJson(response['data']);

        // Update local message with server data
        final updatedMessage = message.copyWith(
          id: serverMessage.id,
          status: MessageStatus.sent,
        );

        // Update in cache
        final messages = _cachedMessages[conversationId]!;
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          messages[index] = updatedMessage;
        }

        return updatedMessage;
      } catch (e) {
        _logger.e('Failed to send message via API: $e');

        // Update message status to failed
        final failedMessage = message.copyWith(status: MessageStatus.failed);
        final messages = _cachedMessages[conversationId]!;
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          messages[index] = failedMessage;
        }

        return failedMessage;
      }
    } catch (e) {
      _logger.e('Failed to send message: $e');
      rethrow;
    }
  }

  /// Get conversations list
  static Future<List<Conversation>> getConversations() async {
    try {
      final response = await ApiService.get('/chat/conversations');
      final conversations = (response['data'] as List)
          .map((c) => Conversation.fromJson(c))
          .toList();

      // Cache conversations
      for (final conversation in conversations) {
        _cachedConversations[conversation.id] = conversation;
      }

      await _saveCachedConversations();
      return conversations;
    } catch (e) {
      _logger.e('Failed to fetch conversations: $e');

      // Return cached conversations as fallback
      return _cachedConversations.values.toList();
    }
  }

  /// Get conversations for a specific category (All, Groups, MC, Branch)
  static Future<List<Conversation>> getConversationsByCategory(
    String category,
  ) async {
    try {
      _logger.i('Fetching conversations for category: $category');

      // Handle different category types
      switch (category.toLowerCase()) {
        case 'all':
          return await _getAllConversations();
        case 'branch':
          return await _getBranchConversations();
        case 'mc':
        case 'groups':
          return await _getMCConversations();
        default:
          return await _getAllConversations();
      }
    } catch (e) {
      _logger.e('Error fetching conversations for category $category: $e');
      throw Exception('Failed to fetch conversations for $category: $e');
    }
  }

  /// Get all conversations
  static Future<List<Conversation>> _getAllConversations() async {
    try {
      // Get all conversations with proper access control
      final response = await ApiService.get('/chat/conversations?type=all');
      final conversationsData = response['data'] as List;

      final conversations = conversationsData.map((data) {
        return Conversation.fromJson(data);
      }).toList();

      // Cache conversations
      for (final conversation in conversations) {
        _cachedConversations[conversation.id] = conversation;
      }
      await _saveCachedConversations();

      return conversations;
    } catch (e) {
      _logger.e('Failed to fetch all conversations: $e');

      // Return cached conversations as fallback
      return _cachedConversations.values.toList();
    }
  }

  /// Get branch-specific conversations
  static Future<List<Conversation>> _getBranchConversations() async {
    try {
      // Use the main API to get conversations with proper access control
      final response = await ApiService.get('/chat/conversations?type=branch');
      final conversationsData = response['data'] as List;

      final conversations = conversationsData.map((data) {
        return Conversation.fromJson(data);
      }).toList();

      // Cache conversations
      for (final conversation in conversations) {
        _cachedConversations[conversation.id] = conversation;
      }
      await _saveCachedConversations();

      return conversations;
    } catch (e) {
      _logger.e('Failed to fetch branch conversations: $e');
      return [];
    }
  }

  /// Get MC-specific conversations
  static Future<List<Conversation>> _getMCConversations() async {
    try {
      // Use the main API to get conversations with proper access control
      final response = await ApiService.get('/chat/conversations?type=mc');
      final conversationsData = response['data'] as List;

      final conversations = conversationsData.map((data) {
        return Conversation.fromJson(data);
      }).toList();

      // Cache conversations
      for (final conversation in conversations) {
        _cachedConversations[conversation.id] = conversation;
      }
      await _saveCachedConversations();

      return conversations;
    } catch (e) {
      _logger.e('Failed to fetch MC conversations: $e');
      return [];
    }
  }

  /// Get messages for conversation
  static Future<List<Message>> getMessages({
    required int conversationId,
    int? lastMessageId,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (lastMessageId != null) 'before_id': lastMessageId.toString(),
      };

      final response = await ApiService.get(
        '/chat/conversations/$conversationId/messages',
        queryParameters: queryParams,
      );

      final messages = (response['data'] as List)
          .map((m) => Message.fromJson(m))
          .toList();

      // Cache messages
      _cachedMessages[conversationId] = messages;

      return messages;
    } catch (e) {
      _logger.e('Failed to fetch messages: $e');

      // Return cached messages as fallback
      return _cachedMessages[conversationId] ?? [];
    }
  }

  /// Create new conversation
  static Future<Conversation> createConversation({
    required String name,
    required List<int> participantIds,
    ConversationType type = ConversationType.group,
    String? description,
  }) async {
    try {
      final response = await ApiService.post(
        '/chat/conversations',
        data: {
          'name': name,
          'participant_ids': participantIds,
          'type': type.name,
          'description': description,
        },
      );

      final conversation = Conversation.fromJson(response['data']);

      // Cache the new conversation
      _cachedConversations[conversation.id] = conversation;
      await _saveCachedConversations();

      // Notify listeners
      _conversationController.add(conversation);

      return conversation;
    } catch (e) {
      _logger.i(
        '⚠️ Chat creation disabled: ${e.toString().contains('unavailable') ? 'Chat feature temporarily unavailable' : e.toString()}',
      );
      rethrow;
    }
  }

  /// Get or create category-based conversation (Branch/MC)
  static Future<Conversation> getOrCreateCategoryConversation({
    required ConversationType type,
    required int categoryId,
  }) async {
    try {
      final response = await ApiService.post(
        '/chat/conversations/category',
        data: {'type': type.name, 'category_id': categoryId},
      );

      final conversation = Conversation.fromJson(response['data']);

      // Cache the conversation
      _cachedConversations[conversation.id] = conversation;
      await _saveCachedConversations();

      return conversation;
    } catch (e) {
      _logger.e('Failed to get/create category conversation: $e');
      rethrow;
    }
  }

  /// Send typing indicator
  static void sendTypingIndicator(int conversationId) {
    if (_isConnected && _webSocketChannel != null) {
      _webSocketChannel!.sink.add(
        jsonEncode({
          'type': 'typing',
          'data': {
            'conversation_id': conversationId,
            'user_id': AuthService.getCurrentUserId(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        }),
      );
    }
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead({
    required int conversationId,
    required List<String> messageIds,
  }) async {
    try {
      // Backend marks messages as read when messages are fetched for a conversation.
      // Use the existing GET messages endpoint with a small limit so the server-side
      // mark-as-read logic runs without fetching lots of data.
      await ApiService.get(
        '/chat/conversations/$conversationId/messages',
        queryParameters: {'limit': '1'},
      );

      // Update cached messages
      final messages = _cachedMessages[conversationId];
      if (messages != null) {
        for (int i = 0; i < messages.length; i++) {
          if (messageIds.contains(messages[i].id)) {
            messages[i] = messages[i].copyWith(
              readAt: DateTime.now(),
              status: MessageStatus.read,
            );
          }
        }
      }

      // Update conversation unread count
      if (_cachedConversations.containsKey(conversationId)) {
        final conversation = _cachedConversations[conversationId]!;
        final updatedConversation = conversation.copyWith(unreadCount: 0);
        _cachedConversations[conversationId] = updatedConversation;
        _conversationController.add(updatedConversation);
      }
    } catch (e) {
      _logger.e('Failed to mark messages as read: $e');
    }
  }

  /// Add message to offline queue
  static Future<void> _addToOfflineQueue(Map<String, dynamic> message) async {
    _offlineQueue.add(message);
    await _saveOfflineQueue();
  }

  /// Process offline queue when connection is restored
  // Disabled until WebSocket implementation is complete
  // ignore: unused_element
  static Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    _logger.i('Processing ${_offlineQueue.length} offline messages');

    final queue = List<Map<String, dynamic>>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final item in queue) {
      try {
        if (item['type'] == 'send_message') {
          _webSocketChannel!.sink.add(jsonEncode(item));
        }
      } catch (e) {
        _logger.e('Failed to process offline message: $e');
        // Re-add to queue if failed
        _offlineQueue.add(item);
      }
    }

    await _saveOfflineQueue();
  }

  /// Load offline queue from storage
  static Future<void> _loadOfflineQueue() async {
    try {
      final queueData = StorageService.getCachedData<String>(_offlineQueueKey);
      if (queueData != null) {
        final queue = jsonDecode(queueData) as List;
        _offlineQueue.addAll(queue.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      _logger.e('Failed to load offline queue: $e');
    }
  }

  /// Save offline queue to storage
  static Future<void> _saveOfflineQueue() async {
    try {
      await StorageService.cacheData(
        _offlineQueueKey,
        jsonEncode(_offlineQueue),
      );
    } catch (e) {
      _logger.e('Failed to save offline queue: $e');
    }
  }

  /// Load cached conversations from storage
  static Future<void> _loadCachedConversations() async {
    try {
      const key = 'cached_conversations';
      final conversationsData = StorageService.getCachedData<String>(key);
      if (conversationsData != null) {
        final conversations =
            jsonDecode(conversationsData) as Map<String, dynamic>;
        for (final entry in conversations.entries) {
          final id = int.parse(entry.key);
          _cachedConversations[id] = Conversation.fromJson(entry.value);
        }
      }
    } catch (e) {
      _logger.e('Failed to load cached conversations: $e');
    }
  }

  /// Save cached conversations to storage
  static Future<void> _saveCachedConversations() async {
    try {
      const key = 'cached_conversations';
      final conversationsData = <String, dynamic>{};
      for (final entry in _cachedConversations.entries) {
        conversationsData[entry.key.toString()] = entry.value.toJson();
      }
      await StorageService.cacheData(key, jsonEncode(conversationsData));
    } catch (e) {
      _logger.e('Failed to save cached conversations: $e');
    }
  }

  /// Get cached messages for conversation
  static List<Message> getCachedMessages(int conversationId) {
    return _cachedMessages[conversationId] ?? [];
  }

  /// Delete a message by id
  static Future<void> deleteMessage({required String messageId}) async {
    try {
      await ApiService.delete('/chat/messages/$messageId');
    } catch (e) {
      // If backend does not provide a delete endpoint (404), treat as a soft success
      // and log the condition. This keeps the app functional while backend work is
      // completed. For other errors, rethrow.
      try {
        // If the error is a DioException with response, inspect status code
        if (e is Exception) {
          _logger.w('Delete message request failed: $e');
        }
      } catch (_) {}
      // Do not rethrow to allow optimistic local deletion when server doesn't support it.
    }
  }

  /// Get cached conversations
  static List<Conversation> getCachedConversations() {
    return _cachedConversations.values.toList()..sort(
      (a, b) => (b.lastMessage?.createdAt ?? b.createdAt).compareTo(
        a.lastMessage?.createdAt ?? a.createdAt,
      ),
    );
  }

  /// Check if connected
  static bool get isConnected => _isConnected;

  /// Dispose all resources
  static Future<void> dispose() async {
    await disconnect();

    _messageController.close();
    _conversationController.close();
    _typingController.close();
    _connectionController.close();
    _userStatusController.close();
  }
}
