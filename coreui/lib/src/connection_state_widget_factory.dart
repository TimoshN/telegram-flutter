import 'package:core_tdlib_api/core_tdlib_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:tdlib/td_api.dart' as td;
import 'package:jugger/jugger.dart' as j;

typedef ConnectionReadyWidgetFactory = Widget Function(BuildContext context);

class ConnectionStateWidgetFactory {
  @j.inject
  ConnectionStateWidgetFactory(
      {required IConnectionStateUpdatesProvider connectionStateUpdatesProvider})
      : _connectionStateUpdatesProvider = connectionStateUpdatesProvider;

  final IConnectionStateUpdatesProvider _connectionStateUpdatesProvider;

  Widget create(
      BuildContext context, ConnectionReadyWidgetFactory readyWidgetFactory) {
    return StreamBuilder<td.ConnectionState>(
      stream: _connectionStateUpdatesProvider.connectionStateUpdates
          .map((td.UpdateConnectionState event) => event.state),
      builder:
          (BuildContext context, AsyncSnapshot<td.ConnectionState> snapshot) {
        final td.ConnectionState? state = snapshot.data;

        if (state != null) {
          if (state.getConstructor() == td.ConnectionStateReady.CONSTRUCTOR) {
            return readyWidgetFactory.call(context);
          } else {
            return Text(_getStateText(state) ?? '');
          }
        }
        return readyWidgetFactory.call(context);
      },
    );
  }

  String? _getStateText(td.ConnectionState state) {
    switch (state.getConstructor()) {
      case td.ConnectionStateUpdating.CONSTRUCTOR:
        {
          return 'Updating';
        }
      case td.ConnectionStateConnecting.CONSTRUCTOR:
        {
          return 'Connecting...';
        }
      case td.ConnectionStateConnectingToProxy.CONSTRUCTOR:
        {
          return 'Connecting to proxy';
        }
      case td.ConnectionStateWaitingForNetwork.CONSTRUCTOR:
        {
          return 'Waiting for network...';
        }
    }

    return null;
  }
}