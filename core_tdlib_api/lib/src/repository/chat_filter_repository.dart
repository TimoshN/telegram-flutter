import 'package:td_api/td_api.dart' as td;

abstract class IChatFilterRepository {
  Stream<List<td.ChatFolderInfo>> get chatFiltersStream;
}
