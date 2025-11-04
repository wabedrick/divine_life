import 'package:equatable/equatable.dart';

/// Represents a chat user with essential information
class ChatUser extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String role;
  final int? mcId;
  final int? branchId;
  final bool isOnline;
  final DateTime? lastSeen;

  const ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.role,
    this.mcId,
    this.branchId,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return ChatUser(
      id: parseInt(json['id']),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      role: json['role'] ?? 'member',
      mcId: json['mc_id'] is int
          ? json['mc_id']
          : (json['mc_id'] is String ? int.tryParse(json['mc_id']) : null),
      branchId: json['branch_id'] is int
          ? json['branch_id']
          : (json['branch_id'] is String
                ? int.tryParse(json['branch_id'])
                : null),
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role,
      'mc_id': mcId,
      'branch_id': branchId,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  ChatUser copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    String? role,
    int? mcId,
    int? branchId,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      mcId: mcId ?? this.mcId,
      branchId: branchId ?? this.branchId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    avatar,
    role,
    mcId,
    branchId,
    isOnline,
    lastSeen,
  ];
}

/// Message status enumeration
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  String get label {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
    }
  }
}

/// Message type enumeration
enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  location,
  system;

  String get label {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.image:
        return 'Image';
      case MessageType.file:
        return 'File';
      case MessageType.audio:
        return 'Audio';
      case MessageType.video:
        return 'Video';
      case MessageType.location:
        return 'Location';
      case MessageType.system:
        return 'System';
    }
  }
}

/// Represents a chat message with comprehensive metadata
class Message extends Equatable {
  final String id;
  final int conversationId;
  final int senderId;
  final String? senderName;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? replyToId;
  final String? clientId;
  final Map<String, dynamic>? metadata;
  final bool isDeleted;
  final bool isEncrypted;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.createdAt,
    this.updatedAt,
    this.readAt,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.replyToId,
    this.clientId,
    this.metadata,
    this.isDeleted = false,
    this.isEncrypted = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: parseInt(json['conversation_id']),
      senderId: parseInt(json['sender_id']),
      senderName: json['sender_name'],
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      replyToId: json['reply_to_id']?.toString(),
      clientId: json['client_id']?.toString(),
      metadata: json['metadata'],
      isDeleted:
          (json['is_deleted'] == true) ||
          (json['deleted'] == true) ||
          (json['metadata'] is Map && json['metadata']['deleted'] == true),
      isEncrypted: json['is_encrypted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'type': type.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'reply_to_id': replyToId,
      'client_id': clientId,
      'metadata': metadata,
      'is_deleted': isDeleted,
      'is_encrypted': isEncrypted,
    };
  }

  Message copyWith({
    String? id,
    int? conversationId,
    int? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToId,
    String? clientId,
    Map<String, dynamic>? metadata,
    bool? isEncrypted,
    bool? isDeleted,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readAt: readAt ?? this.readAt,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      replyToId: replyToId ?? this.replyToId,
      clientId: clientId ?? this.clientId,
      metadata: metadata ?? this.metadata,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Check if message is from current user
  bool isFromUser(int currentUserId) => senderId == currentUserId;

  /// Check if message has been read
  bool get isRead => readAt != null;

  /// Get formatted timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${createdAt.day}/${createdAt.month}';
    } else if (difference.inHours > 0) {
      return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Whether this message has been edited after creation
  bool get isEdited {
    if (updatedAt == null) return false;
    try {
      return updatedAt!.isAfter(createdAt);
    } catch (_) {
      return true;
    }
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    senderName,
    content,
    type,
    status,
    createdAt,
    updatedAt,
    readAt,
    fileUrl,
    fileName,
    fileSize,
    replyToId,
    clientId,
    metadata,
    isEncrypted,
    isDeleted,
  ];
}

/// Conversation type enumeration
enum ConversationType {
  individual,
  group,
  mc,
  branch,
  announcement;

  String get label {
    switch (this) {
      case ConversationType.individual:
        return 'Individual';
      case ConversationType.group:
        return 'Group';
      case ConversationType.mc:
        return 'MC Chat';
      case ConversationType.branch:
        return 'Branch Chat';
      case ConversationType.announcement:
        return 'Announcements';
    }
  }
}

/// Represents a chat conversation with participants and metadata
class Conversation extends Equatable {
  final int id;
  final String name;
  final String? description;
  final ConversationType type;
  final List<ChatUser> participants;
  final Message? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final String? avatar;
  final Map<String, dynamic>? settings;

  const Conversation({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.avatar,
    this.settings,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Conversation(
      id: parseInt(json['id']),
      name: json['name'] ?? '',
      description: json['description'],
      type: ConversationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ConversationType.individual,
      ),
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map((p) => ChatUser.fromJson(p))
              .toList() ??
          [],
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      unreadCount: (json['unread_count'] is int)
          ? json['unread_count']
          : (json['unread_count'] is String
                ? int.tryParse(json['unread_count']) ?? 0
                : 0),
      isMuted: json['is_muted'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      createdBy: json['created_by'],
      avatar: json['avatar'],
      settings: json['settings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'participants': participants.map((p) => p.toJson()).toList(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'is_muted': isMuted,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'avatar': avatar,
      'settings': settings,
    };
  }

  Conversation copyWith({
    int? id,
    String? name,
    String? description,
    ConversationType? type,
    List<ChatUser>? participants,
    Message? lastMessage,
    int? unreadCount,
    bool? isMuted,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    String? avatar,
    Map<String, dynamic>? settings,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      avatar: avatar ?? this.avatar,
      settings: settings ?? this.settings,
    );
  }

  /// Get display name for conversation
  String getDisplayName(int currentUserId) {
    if (type == ConversationType.individual && participants.length == 2) {
      final otherUser = participants.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => participants.first,
      );
      return otherUser.name;
    }
    return name;
  }

  /// Get display avatar for conversation
  String? getDisplayAvatar(int currentUserId) {
    if (avatar != null) return avatar;

    if (type == ConversationType.individual && participants.length == 2) {
      final otherUser = participants.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => participants.first,
      );
      return otherUser.avatar;
    }
    return null;
  }

  /// Get participant count
  int get participantCount => participants.length;

  /// Check if conversation has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Get formatted last message time
  String get formattedLastMessageTime {
    if (lastMessage == null) return '';
    return lastMessage!.formattedTime;
  }

  /// Get other participant (for individual chats)
  ChatUser? getOtherParticipant(int currentUserId) {
    if (type != ConversationType.individual || participants.length != 2) {
      return null;
    }

    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  /// Check if user is online (for individual chats)
  bool isOtherUserOnline(int currentUserId) {
    final otherUser = getOtherParticipant(currentUserId);
    return otherUser?.isOnline ?? false;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    participants,
    lastMessage,
    unreadCount,
    isMuted,
    isPinned,
    createdAt,
    updatedAt,
    createdBy,
    avatar,
    settings,
  ];
}

/// Represents typing indicator for real-time chat
class TypingIndicator extends Equatable {
  final int conversationId;
  final int userId;
  final String userName;
  final DateTime timestamp;

  const TypingIndicator({
    required this.conversationId,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      conversationId: json['conversation_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'user_id': userId,
      'user_name': userName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Check if typing indicator is still active (within 3 seconds)
  bool get isActive {
    return DateTime.now().difference(timestamp).inSeconds < 3;
  }

  @override
  List<Object?> get props => [conversationId, userId, userName, timestamp];
}
