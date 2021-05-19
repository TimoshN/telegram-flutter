import 'package:core_tdlib_api/src/provider/updates/connection_state_updates_provider.dart';
import 'package:feature_chats_list_api/feature_chats_list_api.dart';
import 'package:feature_global_search_api/feature_global_search_api.dart';
import 'package:feature_main_screen_impl/feature_main_screen_impl.dart';
import 'package:jugger/jugger.dart' as j;

class MainScreenFeatureDependencies implements IMainScreenFeatureDependencies {
  @j.inject
  MainScreenFeatureDependencies(
      {required IChatsListFeatureApi chatsListFeatureApi,
      required IGlobalSearchFeatureApi globalSearchFeatureApi,
      required IConnectionStateUpdatesProvider connectionStateUpdatesProvider})
      : _chatsListFeatureApi = chatsListFeatureApi,
        _globalSearchFeatureApi = globalSearchFeatureApi,
        _connectionStateUpdatesProvider = connectionStateUpdatesProvider;

  final IChatsListFeatureApi _chatsListFeatureApi;
  final IGlobalSearchFeatureApi _globalSearchFeatureApi;
  final IConnectionStateUpdatesProvider _connectionStateUpdatesProvider;

  @override
  IChatsListFeatureApi get chatsListFeatureApi => _chatsListFeatureApi;

  @override
  IGlobalSearchFeatureApi get globalSearchFeatureApi => _globalSearchFeatureApi;

  @override
  IConnectionStateUpdatesProvider get connectionStateUpdatesProvider =>
      _connectionStateUpdatesProvider;
}