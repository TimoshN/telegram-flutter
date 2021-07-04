import 'package:core_tdlib_api/core_tdlib_api.dart';
import 'package:core_tdlib_impl/core_tdlib_impl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tdlib/td_api.dart' as td;
import 'package:jugger/jugger.dart' as j;

class ConnectionStateProviderImpl implements IConnectionStateProvider {
  @j.inject
  ConnectionStateProviderImpl(UpdatesProvider updatesProvider)
      : _updatesProvider = updatesProvider {
    // TODO: need dispose?
    _updatesProvider.connectionStateUpdates
        .listen((td.UpdateConnectionState event) {
      _currentState = event.state;
    });
  }

  td.ConnectionState _currentState =
      const td.ConnectionStateWaitingForNetwork();

  final UpdatesProvider _updatesProvider;

  @override
  Stream<td.ConnectionState> get connectionStateAsStream =>
      _updatesProvider.connectionStateUpdates
          .map((td.UpdateConnectionState event) => event.state)
          .startWith(_currentState);
}