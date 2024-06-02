import 'dart:async';

import 'package:core_tdlib_api/core_tdlib_api.dart';
import 'package:rxdart/rxdart.dart';
import 'package:td_api/td_api.dart' as td;

class ChatFilterDataSource {
  ChatFilterDataSource({
    required IChatFiltersUpdatesProvider chatFiltersUpdatesProvider,
  }) : _chatFiltersUpdatesProvider = chatFiltersUpdatesProvider {
    _init();
  }

  final IChatFiltersUpdatesProvider _chatFiltersUpdatesProvider;

  final BehaviorSubject<List<td.ChatFolderInfo>> _chatFiltersSubject =
      BehaviorSubject<List<td.ChatFolderInfo>>.seeded(<td.ChatFolderInfo>[]);

  StreamSubscription<List<td.ChatFolderInfo>>? _chatFiltersUpdatesSubscription;

  Stream<List<td.ChatFolderInfo>> get chatFiltersStream => _chatFiltersSubject;

  void _init() {
    _chatFiltersUpdatesSubscription = _chatFiltersUpdatesProvider
        .chatFiltersUpdates
        .map((td.UpdateChatFolders event) => event.chatFolders)
        // todo do not emit if filters not changed,
        // todo in case if pin chat in custom folder, td lib emit update event,
        // todo but filters is same
        .listen(_chatFiltersSubject.add);
  }

  void dispose() {
    _chatFiltersSubject.close();
    _chatFiltersUpdatesSubscription?.cancel();
  }
}
