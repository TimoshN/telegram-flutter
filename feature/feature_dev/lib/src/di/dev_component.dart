import 'package:core_tdlib_api/core_tdlib_api.dart';
import 'package:coreui/coreui.dart' as tg;
import 'package:feature_dev/feature_dev.dart';
import 'package:jugger/jugger.dart' as j;
import 'package:showcase/showcase.dart';
import 'package:theme_manager_api/theme_manager_api.dart';

@j.Component(
  modules: <Type>[DevModule],
)
abstract class IDevComponent {
  IEventsProvider getEventsProvider();

  tg.ConnectionStateWidgetFactory getConnectionStateWidgetFactory();

  ShowcaseFeature getShowcaseFeature();

  IDevFeatureRouter getRouter();

  ShowcaseScreenFactory getShowcaseScreenFactory();

  ITdFunctionExecutor getTdFunctionExecutor();

  IThemeManager getThemeManager();
}

@j.module
abstract class DevModule {
  @j.provides
  static IEventsProvider provideEventsProvider(
    DevDependencies dependencies,
  ) =>
      dependencies.eventsProvider;

  @j.provides
  static IDevFeatureRouter provideDevFeatureRouter(
    DevDependencies dependencies,
  ) =>
      dependencies.router;

  @j.provides
  static ShowcaseScreenFactory provideShowcaseScreenFactory(
    ShowcaseFeature showcaseFeature,
  ) =>
      showcaseFeature.showcaseScreenFactory;

  @j.provides
  static IThemeManager provideThemeManager(
    DevDependencies dependencies,
  ) =>
      dependencies.themeManager;

  @j.provides
  static ITdFunctionExecutor provideTdFunctionExecutor(
    DevDependencies dependencies,
  ) =>
      dependencies.functionExecutor;

  @j.provides
  @j.singleton
  static IConnectionStateProvider provideConnectionStateProvider(
    DevDependencies dependencies,
  ) =>
      dependencies.connectionStateProvider;

  @j.provides
  @j.singleton
  static ShowcaseFeature provideShowcaseFeature(DevDependencies dependencies) =>
      ShowcaseFeature(
        dependencies: ShowcaseDependencies(
          stringsProvider: dependencies.stringsProvider,
        ),
      );

  @j.singleton
  @j.provides
  static tg.ConnectionStateWidgetFactory provideConnectionStateWidgetFactory(
    IConnectionStateProvider connectionStateProvider,
  ) =>
      tg.ConnectionStateWidgetFactory(
        connectionStateProvider: connectionStateProvider,
      );
}

@j.componentBuilder
abstract class IDevComponentBuilder {
  IDevComponentBuilder devDependencies(DevDependencies dependencies);

  IDevComponent build();
}
