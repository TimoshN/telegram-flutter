import 'package:core_tdlib_api/core_tdlib_api.dart';
import 'package:td_api/td_api.dart' as td;

class FakeChatFilterRepository implements IChatFilterRepository {
  const FakeChatFilterRepository({
    this.chatFilters = const Stream<List<td.ChatFolderInfo>>.empty(),
  });

  final Stream<List<td.ChatFolderInfo>> chatFilters;

  @override
  Stream<List<td.ChatFolderInfo>> get chatFiltersStream => chatFilters;
}
