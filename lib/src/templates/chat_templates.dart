import '../models/generator_config.dart';

/// Templates for generating the chat module code.
class ChatTemplates {
  /// Returns the content for the chat message model.
  static String chatModelContent(String packageName) {
    return '''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum MessageType { text, image, video, audio, document }
enum MessageStatus { sending, sent, delivered, read }

@freezed
sealed class ChatMessage with _\$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String senderId,
    required String receiverId,
    required String roomId,
    required String content,
    required MessageType type,
    required MessageStatus status,
    required DateTime timestamp,
    String? mediaUrl,
    String? fileName,
    String? fileSize,
    String? parentMessageId,
    String? parentMessageContent,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _\$ChatMessageFromJson(json);
}

@freezed
sealed class ChatRoom with _\$ChatRoom {
  const factory ChatRoom({
    required String id,
    required String name,
    required String lastMessage,
    required DateTime lastMessageTime,
    required int unreadCount,
    required MessageStatus lastMessageStatus,
    String? imageUrl,
  }) = _ChatRoom;

  factory ChatRoom.fromJson(Map<String, dynamic> json) => _\$ChatRoomFromJson(json);
}
''';
  }

  /// Returns the content for the socket service.
  static String socketServiceContent() {
    return '''
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SocketService {
  late io.Socket socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<Map<String, dynamic>> get typingEvents => _typingController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  void init({String? token}) {
    final baseUrl = dotenv.env['SOCKET_URL'] ?? 'http://localhost:3000';
    socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': token != null ? {'token': token} : null,
    });

    socket.onConnect((_) {
      _connectionController.add(true);
      print('Socket Connected');
    });

    socket.onConnectError((err) => print('Connect Error: \$err'));
    socket.onReconnectAttempt((_) => print('Attempting Reconnect...'));

    socket.on('message', (data) {
      _messageController.add(data);
    });

    socket.on('typing', (data) {
      _typingController.add(data);
    });

    socket.onDisconnect((_) {
      _connectionController.add(false);
      print('Socket Disconnected');
    });
    
    socket.connect();
  }

  void joinRoom(String roomId) {
    socket.emit('join', roomId);
  }

  void leaveRoom(String roomId) {
    socket.emit('leave', roomId);
  }

  void sendTyping(String roomId, bool isTyping) {
    socket.emit('typing', {'roomId': roomId, 'isTyping': isTyping});
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void dispose() {
    socket.dispose();
    _messageController.close();
    _typingController.close();
    _connectionController.close();
  }
}
''';
  }

  /// Returns the content for the chat service.
  static String chatServiceContent(String packageName) {
    return '''
import 'package:dio/dio.dart';
import 'package:$packageName/core/network/api_client.dart';
import '../models/chat_message.dart';

class ChatService {
  final ApiClient _client;

  ChatService(this._client) {}

  Future<List<ChatRoom>> getChatRooms() async {
    final response = await _client.get('/chat/rooms');
    return (response.data as List).map((e) => ChatRoom.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> getMessages(String roomId, {int page = 1}) async {
    final response = await _client.get('/chat/rooms/\$roomId/messages', queryParameters: {'page': page});
    return (response.data as List).map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<String> uploadMedia(String filePath) async {
    final response = await _client.postMultipart('/chat/upload', data: {
      'file': await MultipartFile.fromFile(filePath),
    });
    return response.data['url'];
  }
}
''';
  }

  /// Returns the content for the main chat page.
  static String chatPageContent(GeneratorConfig config, String packageName) {
    final isBloc = config.stateManagement == StateManagement.bloc ||
        config.stateManagement == StateManagement.cubit;
    final isProvider = config.stateManagement == StateManagement.provider;

    final modelsDir = config.getModelsDirectory();
    final stateDir = config.getStateManagementDirectory();

    return '''
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
${isBloc ? "import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:$packageName/features/chat/$stateDir/chat_bloc.dart';" : ""}
${isProvider ? "import 'package:provider/provider.dart';\nimport 'package:$packageName/features/chat/$stateDir/chat_provider.dart';" : ""}
import 'package:$packageName/features/chat/$modelsDir/chat_message.dart';
import 'package:$packageName/core/theme/app_theme.dart';

class ChatPage extends StatefulWidget {
  final ChatRoom room;
  const ChatPage({super.key, required this.room});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatMessage? _replyMessage;

  ChatThemeExtension get chatTheme => Theme.of(context).extension<ChatThemeExtension>()!;

  @override
  void initState() {
    super.initState();
    ${isBloc ? "context.read<ChatBloc>().add(LoadMessagesEvent(roomId: widget.room.id));" : ""}
    ${isProvider ? "context.read<ChatProvider>().loadMessages(widget.room.id);" : ""}
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
        ${isBloc ? "context.read<ChatBloc>().add(LoadMessagesEvent(roomId: widget.room.id));" : ""}
        ${isProvider ? "context.read<ChatProvider>().loadMessages(widget.room.id);" : ""}
      }
    });

    _controller.addListener(() {
       final isTyping = _controller.text.isNotEmpty;
       ${isBloc ? "context.read<ChatBloc>().add(TypingEvent(roomId: widget.room.id, isTyping: isTyping));" : ""}
       ${isProvider ? "context.read<ChatProvider>().sendTyping(widget.room.id, isTyping);" : ""}
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Row(
          children: [
            Hero(
              tag: 'avatar_\${widget.room.id}',
              child: CircleAvatar(
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                backgroundImage: widget.room.imageUrl != null 
                  ? NetworkImage(widget.room.imageUrl!) 
                  : null,
                child: widget.room.imageUrl == null 
                  ? Text(widget.room.name[0], style: TextStyle(color: theme.primaryColor)) 
                  : null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.room.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _buildStatusSubtitle(),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ${isBloc ? '_blocMessageList()' : (isProvider ? '_providerMessageList()' : '_fallbackMessageList()')},
          ),
          if (_replyMessage != null) _buildReplyPreview(),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildStatusSubtitle() {
    ${isBloc ? '''
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (prev, curr) => curr is ChatLoaded,
      builder: (context, state) {
        final isTyping = state is ChatLoaded && state.isTyping;
        return Text(
          isTyping ? 'Typing...' : 'Online',
          style: TextStyle(
            fontSize: 12, 
            color: isTyping ? chatTheme.typingIndicator : Colors.green,
            fontWeight: isTyping ? FontWeight.bold : FontWeight.normal,
          ),
        );
      },
    );
    ''' : (isProvider ? '''
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return Text(
          provider.otherIsTyping ? 'Typing...' : 'Online',
          style: TextStyle(
            fontSize: 12, 
            color: provider.otherIsTyping ? chatTheme.typingIndicator : Colors.green,
            fontWeight: provider.otherIsTyping ? FontWeight.bold : FontWeight.normal,
          ),
        );
      },
    );
    ''' : "return const Text('Online', style: TextStyle(fontSize: 12, color: Colors.green));")}
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyMessage!.senderId == 'me' ? 'You' : 'Reply to ...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _replyMessage!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _replyMessage = null),
          ),
        ],
      ),
    );
  }

  ${isBloc ? '''
  Widget _blocMessageList() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading) return const Center(child: CircularProgressIndicator());
        if (state is ChatError) return Center(child: Text(state.message));
        if (state is ChatLoaded) {
          return _buildListView(state.messages);
        }
        return const SizedBox.shrink();
      },
    );
  }
  ''' : ""}

  ${isProvider ? '''
  Widget _providerMessageList() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.messages.isEmpty) return const Center(child: CircularProgressIndicator());
        return _buildListView(provider.messages);
      },
    );
  }
  ''' : ""}

  Widget _fallbackMessageList() {
    final messages = List.generate(20, (index) => ChatMessage(
      id: '\$index',
      senderId: index % 2 == 0 ? 'me' : 'other',
      receiverId: index % 2 == 0 ? 'other' : 'me',
      roomId: widget.room.id,
      content: 'Sample message \$index',
      type: MessageType.text,
      status: MessageStatus.read,
      timestamp: DateTime.now().subtract(Duration(minutes: index * 5)),
    ));
    return _buildListView(messages);
  }

  Widget _buildListView(List<ChatMessage> messages) {
    ${isBloc ? "final isTyping = (context.read<ChatBloc>().state as ChatLoaded).isTyping;" : (isProvider ? "final isTyping = context.read<ChatProvider>().otherIsTyping;" : "final isTyping = false;")}
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (isTyping && index == 0) return _buildTypingIndicator();
        final messageIndex = isTyping ? index - 1 : index;
        final message = messages[messageIndex];
        final isMe = message.senderId == 'me';
        final bool showDate = index == messages.length - 1 || 
          !_isSameDay(message.timestamp, messages[index + 1].timestamp);

        return Column(
          children: [
            if (showDate) _buildDateHeader(message.timestamp),
            _wrapWithSwipe(message, isMe),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
     return Padding(
       padding: const EdgeInsets.only(bottom: 16, left: 8),
       child: Row(
         children: [
           Text('Typing', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic)),
           const SizedBox(width: 4),
           SizedBox(
             width: 20,
             child: LinearProgressIndicator(
               backgroundColor: Colors.transparent,
               valueColor: AlwaysStoppedAnimation<Color>(chatTheme.typingIndicator!.withOpacity(0.5)),
             ),
           ),
         ],
       ),
     );
  }

  Widget _wrapWithSwipe(ChatMessage message, bool isMe) {
    return Dismissible(
      key: Key('reply_\${message.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        setState(() => _replyMessage = message);
        return false;
      },
      background: Container(
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.reply, color: Colors.grey),
      ),
      child: _buildMessageBubble(message, isMe),
    );
  }

  Widget _buildRepliedMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: chatTheme.textMe?.withOpacity(0.1) ?? Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: chatTheme.bubbleMe ?? Colors.blue, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reply',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: chatTheme.bubbleMe,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.parentMessageContent ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: chatTheme.textOther?.withOpacity(0.7) ?? Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _getFriendlyDate(date),
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _getFriendlyDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? chatTheme.bubbleMe : chatTheme.bubbleOther,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.parentMessageId != null)
                   _buildRepliedMessage(message),
                if (message.type != MessageType.text) 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildMediaContent(message),
                  ),
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? chatTheme.textMe : chatTheme.textOther,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                if (isMe) ...[
                   const SizedBox(width: 4),
                   _buildStatusIcon(message.status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    const double size = 14;
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(width: size, height: size, child: CircularProgressIndicator(strokeWidth: 1, color: Colors.grey));
      case MessageStatus.sent:
        return const Icon(Icons.check, size: size, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: size, color: Colors.grey);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: size, color: chatTheme.statusRead);
    }
  }


  Widget _buildMediaContent(ChatMessage message) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _getMediaWidget(message),
    );
  }

  Widget _getMediaWidget(ChatMessage message) {
    switch (message.type) {
      case MessageType.image:
        return Image.network(message.mediaUrl!, fit: BoxFit.cover);
      case MessageType.video:
        return Container(
          color: Colors.black.withOpacity(0.1),
          child: const Center(child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white)),
        );
      case MessageType.audio:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.grey[100],
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.play_arrow), SizedBox(width: 8), Text('0:30')],
          ),
        );
      case MessageType.document:
        return Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[100],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, color: Colors.blue),
              const SizedBox(width: 8),
              Text(message.fileName ?? 'Document.pdf', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: theme.primaryColor),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type something...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: theme.primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  ${isBloc ? "context.read<ChatBloc>().add(SendMessageEvent(roomId: widget.room.id, content: _controller.text, type: MessageType.text, parentMessageId: _replyMessage?.id, parentMessageContent: _replyMessage?.content));" : ""}
                  ${isProvider ? "context.read<ChatProvider>().sendMessage(widget.room.id, _controller.text, MessageType.text, parentMessageId: _replyMessage?.id, parentMessageContent: _replyMessage?.content);" : ""}
                  _controller.clear();
                  setState(() => _replyMessage = null);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}
''';
  }

  /// Returns the content for the chat rooms list page.
  static String chatRoomPageContent(String packageName,
      {String modelsDir = 'models'}) {
    return '''
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:$packageName/core/theme/app_theme.dart';
import 'package:$packageName/features/chat/$modelsDir/chat_message.dart';
import 'chat_page.dart';

class ChatRoomsPage extends StatelessWidget {
  const ChatRoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildStorySection(theme),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: 15,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final room = ChatRoom(
                  id: '\$index',
                  name: 'Designer \$index',
                  lastMessage: 'The new assets are ready for review...',
                  lastMessageTime: DateTime.now().subtract(Duration(hours: index)),
                  unreadCount: index % 4 == 0 ? 2 : 0,
                  lastMessageStatus: MessageStatus.read,
                );

                return _buildRoomTile(context, room, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorySection(ThemeData theme) {
    return Container(
      height: 100,
      padding: const EdgeInsets.only(left: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                    ),
                    if (index == 0)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.add_circle, color: theme.primaryColor, size: 20),
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 8),
                Text(index == 0 ? 'Your Story' : 'User \$index', style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomTile(BuildContext context, ChatRoom room, ThemeData theme) {
    final chatTheme = theme.extension<ChatThemeExtension>();
    return ListTile(
      leading: Hero(
        tag: 'avatar_\${room.id}',
        child: CircleAvatar(
          radius: 28,
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: Text(room.name[0], style: TextStyle(color: theme.primaryColor)),
        ),
      ),
      title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Row(
        children: [
          if (room.unreadCount == 0) ...[
             _buildStatusIcon(room.lastMessageStatus, chatTheme),
             const SizedBox(width: 4),
          ],
          Expanded(child: Text(room.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(DateFormat('hh:mm a').format(room.lastMessageTime), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          if (room.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\${room.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatPage(room: room)),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status, ChatThemeExtension? chatTheme) {
    const double size = 14;
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(width: size, height: size, child: CircularProgressIndicator(strokeWidth: 1));
      case MessageStatus.sent:
        return const Icon(Icons.check, size: size, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: size, color: Colors.grey);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: size, color: chatTheme?.statusRead ?? Colors.blue);
    }
  }
}
''';
  }

  /// Returns the content for the chat BLoC.
  static String chatBlocContent(
      String packageName, String snakeName, String pascalName,
      {String modelsDir = 'models', String servicesDir = 'services'}) {
    return '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:$packageName/features/chat/$modelsDir/chat_message.dart';
import 'package:$packageName/features/chat/$servicesDir/socket_service.dart';
import 'package:$packageName/features/chat/$servicesDir/chat_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService chatService;
  final SocketService socketService;
  int _currentPage = 1;
  bool _hasMore = true;

  ChatBloc({required this.chatService, required this.socketService}) : super(ChatInitial()) {
    on<LoadMessagesEvent>((event, emit) async {
      if (!_hasMore && state is ChatLoaded) return;
      
      final isFirstLoad = state is! ChatLoaded;
      if (isFirstLoad) {
        emit(ChatLoading());
        _currentPage = 1;
        _hasMore = true;
      }

      try {
        final messages = await chatService.getMessages(event.roomId, page: _currentPage);
        if (messages.isEmpty) {
          _hasMore = false;
        } else {
          _currentPage++;
          if (isFirstLoad) {
            emit(ChatLoaded(messages: messages, hasMore: _hasMore));
          } else {
            final currentMessages = (state as ChatLoaded).messages;
            emit(ChatLoaded(messages: [...currentMessages, ...messages], hasMore: _hasMore));
          }
        }
      } catch (e) {
        emit(ChatError(message: e.toString()));
      }
    });

    on<SendMessageEvent>((event, emit) {
      socketService.emit('message', {
        'roomId': event.roomId,
        'content': event.content,
        'type': event.type.name,
        'parentMessageId': event.parentMessageId,
        'parentMessageContent': event.parentMessageContent,
      });
      
      if (state is ChatLoaded) {
        final currentMessages = (state as ChatLoaded).messages;
        final myMessage = ChatMessage(
          id: DateTime.now().toIso8601String(),
          senderId: 'me',
          receiverId: 'other', 
          roomId: event.roomId,
          content: event.content,
          type: event.type,
          status: MessageStatus.sending,
          timestamp: DateTime.now(),
          parentMessageId: event.parentMessageId,
          parentMessageContent: event.parentMessageContent,
        );
        emit((state as ChatLoaded).copyWith(messages: [myMessage, ...currentMessages]));
      }
    });

    on<ReceiveMessageEvent>((event, emit) {
      if (state is ChatLoaded) {
        final currentMessages = (state as ChatLoaded).messages;
        emit((state as ChatLoaded).copyWith(messages: [event.message, ...currentMessages]));
      }
    });

    on<TypingEvent>((event, emit) {
      socketService.sendTyping(event.roomId, event.isTyping);
    });

    on<ReceiveTypingEvent>((event, emit) {
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(isTyping: event.isTyping));
      }
    });
  }
}
''';
  }

  /// Returns the content for the chat state.
  static String chatStateContent(String pascalName) {
    return '''
part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}
class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool hasMore;
  final bool isTyping;
  
  const ChatLoaded({required this.messages, this.hasMore = true, this.isTyping = false});

  ChatLoaded copyWith({List<ChatMessage>? messages, bool? hasMore, bool? isTyping}) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [messages, hasMore, isTyping];
}
class ChatError extends ChatState {
  final String message;
  const ChatError({required this.message});
  @override
  List<Object?> get props => [message];
}
''';
  }

  /// Returns the content for the chat events.
  static String chatEventContent(String pascalName) {
    return '''
part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadMessagesEvent extends ChatEvent {
  final String roomId;
  const LoadMessagesEvent({required this.roomId});
  @override
  List<Object?> get props => [roomId];
}

class SendMessageEvent extends ChatEvent {
  final String roomId;
  final String content;
  final MessageType type;
  final String? parentMessageId;
  final String? parentMessageContent;

  const SendMessageEvent({
    required this.roomId,
    required this.content,
    required this.type,
    this.parentMessageId,
    this.parentMessageContent,
  });

  @override
  List<Object?> get props => [roomId, content, type, parentMessageId, parentMessageContent];
}

class ReceiveMessageEvent extends ChatEvent {
  final ChatMessage message;
  const ReceiveMessageEvent({required this.message});
  @override
  List<Object?> get props => [message];
}

class TypingEvent extends ChatEvent {
  final String roomId;
  final bool isTyping;
  const TypingEvent({required this.roomId, required this.isTyping});
  @override
  List<Object?> get props => [roomId, isTyping];
}

class ReceiveTypingEvent extends ChatEvent {
  final bool isTyping;
  const ReceiveTypingEvent({required this.isTyping});
  @override
  List<Object?> get props => [isTyping];
}
''';
  }

  /// Returns the content for the chat repository interface.
  static String chatRepoInterfaceContent(String packageName) {
    return '''
import '../../data/models/chat_message.dart';

abstract class IChatRepository {
  Future<List<ChatRoom>> getChatRooms();
  Future<List<ChatMessage>> getMessages(String roomId, int page);
}
''';
  }

  /// Returns the content for the chat repository implementation.
  static String chatRepoImplContent(String packageName) {
    return '''
import '../models/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../services/chat_service.dart';

class ChatRepositoryImpl implements IChatRepository {
  final ChatService chatService;
  ChatRepositoryImpl(this.chatService) {}

  @override
  Future<List<ChatRoom>> getChatRooms() => chatService.getChatRooms();

  @override
  Future<List<ChatMessage>> getMessages(String roomId, int page) => 
    chatService.getMessages(roomId, page: page);
}
''';
  }

  /// Returns the content for a chat use case.
  static String chatUseCaseContent(String packageName, String useCaseName) {
    return '''
import '../../data/models/chat_message.dart';
import '../repositories/chat_repository.dart';

class ${useCaseName}UseCase {
  final IChatRepository repository;
  ${useCaseName}UseCase(this.repository) {}

  Future<List<ChatMessage>> call(String roomId, int page) => 
    repository.getMessages(roomId, page);
}
''';
  }

  /// Returns the content for the chat message entity.
  static String chatEntityContent() {
    return '''
import '../../data/models/chat_message.dart';

class ChatMessageEntity {
  final String id;
  final String senderId;
  final String receiverId;
  final String roomId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? parentMessageId;
  final String? parentMessageContent;

  ChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.roomId,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.parentMessageId,
    this.parentMessageContent,
  }) {}
}
''';
  }

  /// Returns the content for the chat ViewModel/Provider.
  static String chatViewModelProviderContent(String packageName,
      {String modelsDir = 'models', String servicesDir = 'services'}) {
    return '''
import 'package:flutter/material.dart';
import 'package:$packageName/features/chat/$modelsDir/chat_message.dart';
import 'package:$packageName/features/chat/$servicesDir/chat_service.dart';
import 'package:$packageName/features/chat/$servicesDir/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService chatService;
  final SocketService socketService;

  ChatProvider({required this.chatService, required this.socketService}) {}

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentPage = 1;
  bool _hasMore = true;

  Future<void> loadMessages(String roomId) async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    notifyListeners();

    try {
      final newMessages = await chatService.getMessages(roomId, page: _currentPage);
      if (newMessages.isEmpty) {
        _hasMore = false;
      } else {
        _messages.addAll(newMessages);
        _currentPage++;
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void sendMessage(String roomId, String content, MessageType type, {String? parentMessageId, String? parentMessageContent}) {
    socketService.emit('message', {
      'roomId': roomId,
      'content': content,
      'type': type.name,
      'parentMessageId': parentMessageId,
      'parentMessageContent': parentMessageContent,
    });
    
    // Optimistic Update
    final myMessage = ChatMessage(
      id: DateTime.now().toIso8601String(),
      senderId: 'me',
      receiverId: 'other',
      roomId: roomId,
      content: content,
      type: type,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      parentMessageId: parentMessageId,
      parentMessageContent: parentMessageContent,
    );
    _messages.insert(0, myMessage);
    notifyListeners();
  }

  bool _otherIsTyping = false;
  bool get otherIsTyping => _otherIsTyping;

  void sendTyping(String roomId, bool isTyping) {
    socketService.sendTyping(roomId, isTyping);
  }

  void receiveTyping(bool isTyping) {
    _otherIsTyping = isTyping;
    notifyListeners();
  }

  void receiveMessage(ChatMessage message) {
    _messages.insert(0, message);
    notifyListeners();
  }
}
''';
  }
}
