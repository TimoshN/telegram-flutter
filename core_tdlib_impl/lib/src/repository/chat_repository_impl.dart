import 'package:core_tdlib_api/core_tdlib_api.dart';
import 'package:jugger/jugger.dart' as j;
import 'package:rxdart/rxdart.dart';
import 'package:td_client/td_client.dart';
import 'package:tdlib/td_api.dart' as td;
import 'package:tdlib/td_client.dart';

class ChatRepositoryImpl extends IChatRepository {
  @j.inject
  ChatRepositoryImpl(this._client) {
    /*
    Stream<td.Chats>.fromFuture(_client.send<td.Chats>(td.GetChats(
      offsetChatId: 0,
      offsetOrder: 9223372036854775807,
      chatList: const td.ChatListMain(),
      limit: 10,
    ))).listen((event) {
      print('');
    });
    _client.events
        .where((td.TdObject event) =>
            event is td.UpdateNewChat || event is td.UpdateChatLastMessage)
        .listen((td.TdObject event) {
      if (event is td.UpdateNewChat) {
        _chats[event.chat.id] = event.chat;
        _chatsSubject.add(_chats.values.toList());
      } else if (event is td.UpdateChatLastMessage) {
        _chats[event.chatId] =
            _chats[event.chatId]!.copy(lastMessage: event.lastMessage);
        _chatsSubject.add(_chats.values.toList());
      }
    });
    _client.events
        .where((td.TdObject event) => event is td.UpdateFile)
        .map((td.TdObject event) => event as td.UpdateFile)
        .listen((td.UpdateFile event) {
      final td.Chat? associatedChat =
          _chats.values.firstWhereOrNull((td.Chat chat) {
        final td.ChatPhotoInfo? photoInfo = chat.photo;
        return photoInfo != null &&
            (photoInfo.small.id == event.file.id ||
                photoInfo.big.id == event.file.id);
      });

      if (associatedChat != null) {
        _chats[associatedChat.id] = associatedChat.copy(
            photo: associatedChat.photo?.copy(
                big: associatedChat.photo?.big.id == event.file.id
                    ? event.file
                    : associatedChat.photo?.big,
                small: associatedChat.photo?.small.id == event.file.id
                    ? event.file
                    : associatedChat.photo?.small));
        _chatsSubject.add(_chats.values.toList());
      }
    });
     */
  }

  final TdClient _client;

  final Map<int, td.Chat> _chats = <int, td.Chat>{};

  final BehaviorSubject<List<td.Chat>> _chatsSubject =
      BehaviorSubject<List<td.Chat>>();

  @override
  Stream<List<td.Chat>> get chats => _chatsSubject;

  @override
  Future<td.Chat> getChat(int id) =>
      _client.send<td.Chat>(td.GetChat(chatId: id));

  @override
  Future<List<td.Chat>> getChats(
      {required int offsetChatId,
      required int offsetOrder,
      required int limit,
      required td.ChatList chatList}) async {
    final List<td.Chat> chats = <td.Chat>[];

    final td.Chats result = await _client.send<td.Chats>(td.GetChats(
      offsetChatId: offsetChatId,
      offsetOrder: offsetOrder,
      chatList: chatList,
      limit: limit,
    ));

    chats.addAll(await Stream<td.Chat>.fromFutures(result.chatIds
            .map((int e) => _client.send<td.Chat>(td.GetChat(chatId: e))))
        .toList());

    if (chats.length < limit && chats.isNotEmpty) {
      final td.Chat lastChat = chats.last;
      chats.addAll(await getChats(
          chatList: chatList,
          limit: limit - chats.length,
          offsetChatId: lastChat.id,
          offsetOrder: lastChat.positions[0].order));
    }

    return chats.take(limit).toList();
  }

  @override
  Future<td.Supergroup> getSupergroup(int id) =>
      _client.send<td.Supergroup>(td.GetSupergroup(supergroupId: id));
}