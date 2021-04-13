import 'package:td_client/td_client.dart';
import 'package:tdlib/td_api.dart' as td;
import 'package:jugger/jugger.dart' as j;

class OptionsManager {
  @j.inject
  OptionsManager(this._client);

  final TdClient _client;

  Future<void> setOnline(bool value) {
    return _client.send<td.Ok>(td.SetOption(
        name: 'online', value: td.OptionValueBoolean(value: value)));
  }
}