import 'dart:async';
import 'package:core/core.dart';
import 'package:presentation/src/mapper/mapper.dart';
import 'package:tdlib/td_api.dart' as td;
import 'package:jugger/jugger.dart' as j;
import 'package:tdlib/td_client.dart';
import 'package:collection/collection.dart';
import 'package:presentation/src/model/model.dart';
import 'chat_data.dart';
import 'chat_list.dart';
import 'chat_list_config.dart';
import 'ordered_chat.dart';

class _Action {
  _Action({required this.action, required this.completer});

  final Future<bool> Function() action;
  final Completer<bool> completer;
}

class ChatListUpdateHandler {
  @j.inject
  ChatListUpdateHandler(
      {required IChatRepository chatRepository,
      required ChatListConfig chatListConfig,
      required IChatsHolder chatsHolder,
      required ChatTileModelMapper chatTileModelMapper})
      : _chatTileModelMapper = chatTileModelMapper,
        _chatListConfig = chatListConfig,
        _chatsHolder = chatsHolder,
        _chatRepository = chatRepository {
    _streamController.stream.asyncMap((_Action event) async {
      final bool result = await event.action.call().then((bool value) {
        return value;
      });
      return event.completer.complete(result);
    }).listen(null);
  }

  final ChatTileModelMapper _chatTileModelMapper;
  final IChatsHolder _chatsHolder;
  final IChatRepository _chatRepository;
  final ChatListConfig _chatListConfig;

  final StreamController<_Action> _streamController =
      StreamController<_Action>();

  Set<OrderedChat> get _orderedChats => _chatsHolder.orderedChats;

  Map<int, ChatData> get _chats => _chatsHolder.chatsData;

  Future<bool> handleNewChat({required td.Chat chat}) =>
      _enqueue(() => _handleNewChat(chat: chat));

  Future<bool> handleNewPositions(
          int chatId, List<td.ChatPosition> positions) =>
      _enqueue(() => _handleNewPositions(chatId, positions));

  Future<bool> handleNewPosition(int chatId, td.ChatPosition position) =>
      _enqueue(() => _handleNewPosition(chatId, position));

  Future<bool> handleLastMessage(int chatId, td.Message? message) =>
      _enqueue(() => _handleLastMessage(chatId, message));

  Future<bool> handleUpdateChatReadInbox(td.UpdateChatReadInbox update) =>
      _enqueue(() => _handleUpdateChatReadInbox(update));

  Future<bool> handleUpdateChatNotificationSettings(
          td.UpdateChatNotificationSettings update) =>
      _enqueue(() => _handleUpdateChatNotificationSettings(update));

  void dispose() {
    _streamController.close();
  }

  Future<bool> _enqueue(Future<bool> Function() action) {
    final Completer<bool> completer = Completer<bool>();
    _streamController
        .add(_Action(action: () async => action.call(), completer: completer));
    return completer.future;
  }

  Future<ChatData> _toChatData(td.Chat chat) async =>
      ChatData(chat: chat, model: await _chatTileModelMapper.mapToModel(chat));

  ChatData? _getChatData(int chatId) => _chats[chatId];

  Future<bool> _handleNewChat({required td.Chat chat}) async {
    if (chat.positions.isEmpty) {
      return false;
    }
    assert(chat.positions.length == 1);

    final int order = chat.getPosition().order;
    _orderedChats.add(OrderedChat(chatId: chat.id, order: order));

    final ChatData data = await _toChatData(chat);
    assert(data.chat.positions.length == 1);
    _chats[chat.id] = data;

    return true;
  }

  Future<bool> _handleNewPositions(
      int chatId, List<td.ChatPosition> positions) async {
    final td.ChatPosition? position = positions.firstWhereOrNull(
        (td.ChatPosition position) =>
            position.list.getConstructor() ==
            _chatListConfig.chatList.getConstructor());

    if (position != null) {
      return _handleNewPosition(chatId, position);
    }
    return false;
  }

  Future<bool> _handleNewPosition(int chatId, td.ChatPosition position) async {
    if (position.list != _chatListConfig.chatList) {
      return false;
    }

    if (!_chats.containsKey(chatId)) {
      final bool handleNewChatResult =
          await _handleNewChat(chat: await _chatRepository.getChat(chatId));
      assert(handleNewChatResult);
    }

    final ChatData chatData = _chats[chatId]!;
    assert(chatData.chat.positions.length == 1);
    final bool removedPrevChat = _orderedChats.remove(OrderedChat(
        chatId: chatData.chat.id, order: chatData.chat.getPosition().order));
    assert(removedPrevChat);

    if (position.order == 0) {
      final ChatData? removeChat = _chats.remove(chatId);
      assert(removeChat != null);
    } else {
      final OrderedChat newOrderedChat =
          OrderedChat(chatId: chatData.chat.id, order: position.order);
      chatData.chat =
          chatData.chat.copy(positions: <td.ChatPosition>[position]);
      chatData.model = chatData.model.copy(isPinned: position.isPinned);
      final bool add = _orderedChats.add(newOrderedChat);
      assert(add);
    }

    return true;
  }

  Future<bool> _handleLastMessage(int chatId, td.Message? message) async {
    if (!_chats.containsKey(chatId)) {
      return false;
    }
    final ChatData chatData = _chats[chatId]!;
    chatData.chat = chatData.chat.copy(lastMessage: message);
    // ignore: flutter_style_todos
    //TODO(Ivan): map only changed part
    chatData.model = await _chatTileModelMapper.mapToModel(chatData.chat);
    return true;
  }

  Future<bool> _handleUpdateChatReadInbox(td.UpdateChatReadInbox update) async {
    final ChatData? chatData = _getChatData(update.chatId);

    if (chatData == null) {
      return false;
    }

    chatData.chat = chatData.chat.copy(
        unreadCount: update.unreadCount,
        lastReadInboxMessageId: update.lastReadInboxMessageId);

    chatData.model = await _chatTileModelMapper.mapToModel(chatData.chat);
    return true;
  }

  Future<bool> _handleUpdateChatNotificationSettings(
      td.UpdateChatNotificationSettings update) async {
    final ChatData? chatData = _getChatData(update.chatId);

    if (chatData == null) {
      return false;
    }

    chatData.chat =
        chatData.chat.copy(notificationSettings: update.notificationSettings);

    chatData.model = await _chatTileModelMapper.mapToModel(chatData.chat);
    return true;
  }
}

extension _ChatExtensions on td.Chat {
  td.ChatPosition getPosition() {
    assert(positions.length == 1);
    return positions[0];
  }
}