import 'package:td_api/td_api.dart' as td;

abstract class IChatFiltersUpdatesProvider {
  Stream<td.UpdateChatFolders> get chatFiltersUpdates;
}
