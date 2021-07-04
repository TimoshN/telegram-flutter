import 'package:coreui/coreui.dart' as tg;
import 'package:feature_settings_impl/feature_settings_impl.dart';
import 'package:feature_settings_search_api/feature_settings_search_api.dart';
import 'package:flutter/material.dart';
import 'package:jext/jext.dart';
import 'package:jugger/jugger.dart' as j;
import 'package:localization_api/localization_api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage>
    with
        TickerProviderStateMixin,
        StateInjectorMixin<SettingsPage, SettingsPageState> {
  // TODO maybe conflict
  final GlobalObjectKey<tg.TgSwitchedAppBarState> appbarKey =
      const GlobalObjectKey<tg.TgSwitchedAppBarState>('SettingsAppbar');

  @j.inject
  late ILocalizationManager localizationManager;

  @j.inject
  late ISettingsScreenRouter router;

  @j.inject
  late tg.ConnectionStateWidgetFactory connectionStateWidgetFactory;

  @j.inject
  late ISettingsSearchWidgetFactory settingsSearchWidgetFactory;

  _ScreenState _screenState = _ScreenState.Default;

  bool _searchActive = false;
  bool _showClearButtonQuery = false;

  late FocusNode myFocusNode;
  late Animation<Size?> _navigationIconColorTween;
  late AnimationController _animationController;
  final TextEditingController _searchQueryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchQueryController.addListener(() {
      setState(() {
        final bool _prevValue = _showClearButtonQuery;
        _showClearButtonQuery = _searchQueryController.text.isNotEmpty;
        if (_showClearButtonQuery != _prevValue) {
          if (_showClearButtonQuery) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        }
      });
    });

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    // TODO refactor Size
    _navigationIconColorTween =
        SizeTween(begin: const Size(0, 0), end: const Size(1, 1))
            .animate(_animationController);
    myFocusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_screenState != _ScreenState.Default) {
          setState(() {
            _screenState = _ScreenState.Default;
            _searchActive = false;
            _searchQueryController.text = '';
            appbarKey.currentState?.setActive(false);
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: _buildAppbar(context),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              child: child,
              opacity: animation,
            );
          },
          child: _searchActive
              ? _buildSearchWidget(context)
              : SingleChildScrollView(child: _buildDefaultWidget(context)),
        ),
      ),
    );
  }

  Widget _buildSearchWidget(BuildContext context) =>
      settingsSearchWidgetFactory.create();

  Widget _buildDefaultWidget(BuildContext context) {
    final Color accentColor = Theme.of(context).accentColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        tg.TextCell(
          titleColor: accentColor,
          leading: Icon(
            Icons.add_a_photo_outlined,
            color: accentColor,
          ),
          title: _getString('SetProfilePhoto'),
        ),
        const tg.SectionDivider(),
        tg.Section(
          text: _getString('Account'),
        ),
        tg.TextCell(
          title: '123',
          subtitle: _getString('TapToChangePhone'),
        ),
        const tg.Divider(),
        tg.TextCell(
          title: 'None',
          subtitle: _getString('Username'),
        ),
        const tg.Divider(),
        tg.TextCell(
          title: _getString('UserBio'),
          subtitle: _getString('UserBioDetail'),
        ),
        const tg.SectionDivider(),
        tg.Section(
          text: _getString('Settings'),
        ),
        tg.TextCell(
          onTap: router.toNotificationsSettings,
          leading: const Icon(Icons.notifications_none),
          title: _getString('NotificationsAndSounds'),
        ),
        const tg.Divider(),
        tg.TextCell(
          onTap: router.toPrivacySettings,
          leading: const Icon(Icons.lock_open),
          title: _getString('PrivacySettings'),
        ),
        const tg.Divider(),
        tg.TextCell(
          onTap: router.toDataSettings,
          leading: const Icon(Icons.data_usage),
          title: _getString('DataSettings'),
        ),
        const tg.Divider(),
        tg.TextCell(
          onTap: router.toChatSettings,
          leading: const Icon(Icons.chat_bubble_outline),
          title: _getString('ChatSettings'),
        ),
        const tg.SectionDivider(),
        tg.Section(
          text: _getString('SettingsHelp'),
        ),
        tg.TextCell(
          leading: const Icon(Icons.chat),
          title: _getString('AskAQuestion'),
        ),
        const tg.Divider(),
        tg.TextCell(
          leading: const Icon(Icons.help_outline),
          title: _getString('TelegramFAQ'),
        ),
        const tg.Divider(),
        tg.TextCell(
          leading: const Icon(Icons.shield),
          title: _getString('PrivacyPolicy'),
        ),
        const tg.Annotation(
          align: TextAlign.center,
          text: 'Todo: add app version information',
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return tg.TgSwitchedAppBar(
      key: appbarKey,
      iconColorProvider: (bool isActive) {
        return Colors.white;
      },
      backgroundColorProvider: (bool isActive) {
        return Theme.of(context).primaryColor;
      },
      navigationIconTap: () {
        setState(() {
          if (_screenState == _ScreenState.Search) {
            _screenState = _ScreenState.Default;
            _searchActive = false;
            _searchQueryController.text = '';
            appbarKey.currentState?.setActive(false);
          } else if (_screenState == _ScreenState.Default) {
            Navigator.of(context).pop();
          }
        });
      },
      actionWidgetsBuilder: (BuildContext context, bool isActive) {
        if (isActive) {
          switch (_screenState) {
            case _ScreenState.Search:
              {
                return <Widget>[
                  AnimatedBuilder(
                    animation: _navigationIconColorTween,
                    builder: (BuildContext context, Widget? child) {
                      return Transform.scale(
                        scale: _navigationIconColorTween.value!.height,
                        child: child,
                      );
                    },
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchQueryController.text = '';
                      },
                    ),
                  ),
                ];
              }
            default:
              {
                return <Widget>[];
              }
          }
        } else {
          return <Widget>[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _screenState = _ScreenState.Search;
                  _searchActive = !_searchActive;
                  myFocusNode.requestFocus();
                  myFocusNode.unfocus();
                  appbarKey.currentState?.setActive(true);
                });
              },
            ),
          ];
        }
      },
      titleBuilder: (BuildContext context, bool isActive) {
        if (isActive) {
          switch (_screenState) {
            case _ScreenState.Search:
              {
                return TextField(
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  focusNode: myFocusNode,
                  controller: _searchQueryController,
                  decoration: const InputDecoration.collapsed(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.white)),
                );
              }
            default:
              {
                return Container();
              }
          }
        } else {
          return _buildTitleWidget(context);
        }
      },
      leadingIconProvider: (bool isActive) => Icons.arrow_back,
    );
  }

  Widget _buildTitleWidget(BuildContext context) {
    return Align(
      child:
          connectionStateWidgetFactory.create(context, (BuildContext context) {
        // TODO extract text to stings
        return const Text('Telegram');
      }),
      alignment: Alignment.centerLeft,
    );
  }

  String _getString(String key) => localizationManager.getString(key);
}

enum _ScreenState { Default, Search }