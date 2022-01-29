import 'package:flutter/material.dart';
import 'container_divider.dart';

class Config {
  const Config({
    required this.leftContainerWidth,
    required this.minLeftContainerWidth,
    required this.maxLeftContainerWidth,
    required this.minRightContainerWidth,
    required this.maxCompactWidth,
    required this.isDraggableDivider,
  });

  final double leftContainerWidth;
  final double minLeftContainerWidth;
  final double maxLeftContainerWidth;
  final double minRightContainerWidth;
  final double maxCompactWidth;

  final bool isDraggableDivider;
}

class SplitView extends StatefulWidget {
  const SplitView({
    this.config = const Config(
      minLeftContainerWidth: 290,
      leftContainerWidth: 350,
      maxLeftContainerWidth: 400,
      isDraggableDivider: true,
      minRightContainerWidth: 500,
      maxCompactWidth: 699,
    ),
    Key? key,
  }) : super(key: key);

  final Config config;

  @override
  SplitViewState createState() => SplitViewState();

  static SplitViewState of(BuildContext context) {
    SplitViewState? navigator;
    if (context is StatefulElement && context.state is NavigatorState) {
      navigator = context.state as SplitViewState;
    }
    navigator = navigator ?? context.findAncestorStateOfType<SplitViewState>();
    return navigator!;
  }
}

enum ContainerType { left, right, top }

class _PageNode {
  _PageNode({required this.container, required this.page, int? order})
      : order = order ?? DateTime.now().millisecondsSinceEpoch;

  final ContainerType container;
  final int order;

  final Page<dynamic> page;
}

class SplitViewState extends State<SplitView> {
  late List<_PageNode> _leftPages;
  late List<_PageNode> _rightPages;
  late List<_PageNode> _topPages;

  final GlobalKey<NavigatorState> _topNavigatorKey =
      GlobalKey<NavigatorState>();

  _PageNode? _leftRootPage;
  Widget _rightContainerPlaceholder = Container();

  late List<_PageNode> _compactPages = const <_PageNode>[];
  bool _isCompact = false;

  double _leftContainerWidth = 0;

  @override
  void initState() {
    super.initState();
    _leftContainerWidth = widget.config.leftContainerWidth;

    _leftPages = <_PageNode>[];
    _rightPages = <_PageNode>[];
    _topPages = <_PageNode>[];
  }

  void popUntilRoot(ContainerType container) {
    setState(() {
      switch (container) {
        case ContainerType.left:
          _leftPages.removeWhere(
            (_PageNode element) => element.order != kLeftRootPageIndex,
          );
          break;
        case ContainerType.right:
          _rightPages.removeWhere(
            (_PageNode element) => element.order != kRightRootPageIndex,
          );
          break;
        case ContainerType.top:
          _topPages.clear();
          break;
      }
      _invalidatePages();
    });
  }

  void pushAllReplacement({
    required LocalKey key,
    required WidgetBuilder builder,
    required ContainerType container,
  }) {
    setState(() {
      popUntilRoot(container);
      push(key: key, builder: builder, container: container);
      _invalidatePages();
    });
  }

  void setLeftRootPage(Widget widget) {
    setState(() {
      if (_leftRootPage == null) {
        _leftRootPage = _createLeftRootPage(widget);
        _leftPages.add(_leftRootPage!);
      } else {
        _leftRootPage = _createLeftRootPage(widget);
        final int indexOfRootPage = _leftPages.indexOf(_leftPages.firstWhere(
          (_PageNode element) => element.order == kLeftRootPageIndex,
        ));
        _leftPages[indexOfRootPage] = _leftRootPage!;
      }
      _invalidatePages();
    });
  }

  void push({
    required LocalKey key,
    required WidgetBuilder builder,
    required ContainerType container,
  }) {
    _push(
      _SimplePage(
        key: key,
        animateRouterProvider: () => _shouldAnimate(key, container),
        builder: builder,
        containerType: container,
      ),
      container,
    );
  }

  void setRightContainerPlaceholder(Widget widget) {
    setState(() {
      _rightContainerPlaceholder = widget;
    });
  }

  void _push(MyPage<dynamic> page, ContainerType containerType) {
    setState(() {
      switch (containerType) {
        case ContainerType.left:
          _leftPages.add(_PageNode(container: containerType, page: page));
          break;
        case ContainerType.right:
          _rightPages.add(_PageNode(container: containerType, page: page));
          break;
        case ContainerType.top:
          _topPages.add(_PageNode(container: containerType, page: page));
          break;
      }
      _invalidatePages();
    });
  }

  _PageNode _createLeftRootPage(Widget widget) {
    final UniqueKey key = UniqueKey();
    return _PageNode(
      order: kLeftRootPageIndex,
      container: ContainerType.left,
      page: _SimplePage(
        builder: (_) => widget,
        animateRouterProvider: () => _shouldAnimate(key, ContainerType.left),
        containerType: ContainerType.left,
        key: key,
      ),
    );
  }

  void _onWidthChanged(double width) {
    if (width <= widget.config.maxCompactWidth) {
      if (!_isCompact) {
        _isCompact = true;
        _invalidatePages();
      }
    } else {
      if (_isCompact) {
        _isCompact = false;
        _invalidatePages();
      }
    }
  }

  void _invalidatePages() {
    if (_isCompact) {
      _compactPages = (_leftPages + _rightPages + _topPages)
        // todo fix order if first pushed top
        ..sort((_PageNode a, _PageNode b) => a.order.compareTo(b.order));
    } else {
      _compactPages = const <_PageNode>[];
    }
  }

  bool hasKey(LocalKey key, ContainerType container) {
    switch (container) {
      case ContainerType.left:
        return _leftPages.hasKey(key);
      case ContainerType.right:
        return _rightPages.hasKey(key);
      case ContainerType.top:
        return _topPages.hasKey(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _onWidthChanged(constraints.maxWidth);
          Widget finalWidget;
          if (constraints.maxWidth > widget.config.maxCompactWidth) {
            finalWidget = Stack(
              children: <Widget>[
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return Row(
                      children: <Widget>[
                        ClipRect(
                          child: Container(
                            child: _NavigatorContainer(
                              onPopPage: _onPopPage,
                              pages: _leftPages
                                  .map((_PageNode e) => e.page)
                                  .toList(),
                            ),
                            constraints: BoxConstraints.expand(
                              width: _leftContainerWidth,
                            ),
                          ),
                        ),
                        if (_leftPages.isNotEmpty || _rightPages.isNotEmpty)
                          _DraggableDivider(
                            isDraggableDivider:
                                widget.config.isDraggableDivider,
                            onPointerMove: (PointerMoveEvent event) {
                              setState(() {
                                _leftContainerWidth = event.position.dx.clamp(
                                  widget.config.minLeftContainerWidth,
                                  widget.config.maxLeftContainerWidth,
                                );
                              });
                            },
                          ),
                        _RightNavigatorContainer(
                          onPopPage: _onPopPage,
                          pages:
                              _rightPages.map((_PageNode e) => e.page).toList(),
                          placeholder: _rightContainerPlaceholder,
                        ),
                      ],
                    );
                  },
                ),
                AnimatedTopNavigationContainer(
                  onPopPage: _onPopPage,
                  isNotSinglePage:
                      _leftPages.isNotEmpty || _rightPages.isNotEmpty,
                  onBarrierTap: () {
                    popUntilRoot(ContainerType.top);
                  },
                  pages: _topPages.map((_PageNode e) => e.page).toList(),
                ),
              ],
            );
          } else {
            finalWidget = _NavigatorContainer(
              onPopPage: _onPopPage,
              pages: _compactPages.map((_PageNode e) => e.page).toList(),
              navigatorKey: _topNavigatorKey,
            );
          }
          return finalWidget;
        },
      ),
      onWillPop: () async {
        if (_isCompact) {
          return !(await _topNavigatorKey.currentState!.maybePop());
        }

        if (_topPages.isNotEmpty) {
          if (_leftPages.isEmpty && _rightPages.isEmpty) {
            return true;
          } else {
            setState(() {
              _topPages.removeLast();
            });
          }
          return false;
        } else if (_rightPages.isNotEmpty) {
          setState(() {
            _rightPages.removeLast();
          });
          return false;
        } else if (_leftPages.isNotEmpty) {
          // first node is root page
          if (_leftPages.length == 1) {
            return true;
          } else {
            setState(() {
              _leftPages.removeLast();
            });
          }
          return false;
        }
        return true;
      },
    );
  }

  Widget wrapWithoutTopPadding(Widget child) {
    final MediaQueryData baseMediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: baseMediaQuery.copyWith(
        padding: baseMediaQuery.padding.copyWith(top: 0),
      ),
      child: child,
    );
  }

  bool _shouldAnimate(LocalKey key, ContainerType container) {
    bool shouldAnimate(List<_PageNode> pages) {
      final int indexWhere =
          pages.indexWhere((_PageNode element) => element.page.key == key);
      return indexWhere > 0;
    }

    if (_isCompact) {
      return shouldAnimate(_compactPages);
    }
    switch (container) {
      case ContainerType.left:
        return shouldAnimate(_leftPages);
      case ContainerType.right:
        return shouldAnimate(_rightPages);
      case ContainerType.top:
        return shouldAnimate(_topPages);
    }
  }

  bool _onPopPage(Route<dynamic> route, Object? result) {
    if (!route.didPop(result)) {
      return false;
    }
    if (route.settings is MyPage) {
      setState(() {
        final MyPage<dynamic> myPage = route.settings as MyPage<dynamic>;
        _removeTopFromContainer(myPage.container);
        _invalidatePages();
      });
    }

    return true;
  }

  void pop() {
    setState(() {
      if (_isCompact) {
        final _PageNode removed = _compactPages.removeLast();
        _removeTopFromContainer(removed.container);
        _invalidatePages();
      } else {
        if (_topPages.isNotEmpty) {
          _removeTopFromContainer(ContainerType.top);
        } else if (_rightPages.isNotEmpty) {
          _removeTopFromContainer(ContainerType.right);
        } else if (_leftPages.isNotEmpty) {
          _removeTopFromContainer(ContainerType.left);
        }
      }
    });
  }

  void _removeTopFromContainer(ContainerType container) {
    switch (container) {
      case ContainerType.left:
        final _PageNode lastWhere = _leftPages.lastWhere(
          (_PageNode element) => element.container == ContainerType.left,
        );
        _leftPages.remove(lastWhere);
        break;
      case ContainerType.right:
        final _PageNode lastWhere = _rightPages.lastWhere(
          (_PageNode element) => element.container == ContainerType.right,
        );
        _rightPages.remove(lastWhere);
        break;
      case ContainerType.top:
        final _PageNode lastWhere = _topPages.lastWhere(
          (_PageNode element) => element.container == ContainerType.top,
        );
        _topPages.remove(lastWhere);
        break;
    }
  }

  static const int kLeftRootPageIndex = 0;
  static const int kRightRootPageIndex = -1;
}

abstract class MyPage<T> extends Page<T> {
  const MyPage({
    required LocalKey key,
    required this.container,
  }) : super(key: key);

  final ContainerType container;
}

class _SimplePage extends MyPage<dynamic> {
  const _SimplePage({
    required this.builder,
    required this.animateRouterProvider,
    required ContainerType containerType,
    required LocalKey key,
  }) : super(key: key, container: containerType);

  final WidgetBuilder builder;
  final bool Function() animateRouterProvider;

  @override
  Route<dynamic> createRoute(BuildContext context) {
    return _DefaultRoute<dynamic>(
      settings: this,
      routerDurationProvider: () {
        if (!animateRouterProvider()) {
          return Duration.zero;
        }
        return null;
      },
      builder: builder.call,
    );
  }
}

class _DefaultRoute<T> extends MaterialPageRoute<T> {
  _DefaultRoute({
    required RouteSettings? settings,
    required WidgetBuilder builder,
    required this.routerDurationProvider,
  }) : super(builder: builder, settings: settings);

  final Duration? Function() routerDurationProvider;

  @override
  Duration get transitionDuration {
    return routerDurationProvider() ?? super.transitionDuration;
  }

  @override
  Duration get reverseTransitionDuration {
    return routerDurationProvider() ?? super.reverseTransitionDuration;
  }
}

extension _Extensions on List<_PageNode> {
  bool hasKey(LocalKey key) =>
      any((_PageNode element) => element.page.key == key);
}

class _NavigatorContainer extends StatelessWidget {
  const _NavigatorContainer({
    Key? key,
    this.navigatorKey,
    required this.pages,
    required this.onPopPage,
  }) : super(key: key);

  final List<Page<dynamic>> pages;
  final PopPageCallback onPopPage;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return const SizedBox();
    }

    return Navigator(
      key: navigatorKey,
      pages: pages,
      onPopPage: onPopPage,
    );
  }
}

class _RightNavigatorContainer extends StatelessWidget {
  const _RightNavigatorContainer({
    Key? key,
    required this.pages,
    required this.onPopPage,
    required this.placeholder,
  }) : super(key: key);

  //.map((_PageNode e) => e.page).toList()
  final List<Page<dynamic>> pages;
  final PopPageCallback onPopPage;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return Expanded(child: placeholder);
    }
    final UniqueKey key = UniqueKey();
    return Expanded(
      child: ClipRect(
        child: _NavigatorContainer(
          onPopPage: onPopPage,
          pages: <Page<dynamic>>[
            // add stub page for trigger navigation button
            _SimplePage(
              key: key,
              animateRouterProvider: () => true,
              builder: (_) => Container(),
              containerType: ContainerType.top,
            ),
            ...pages,
          ],
        ),
      ),
    );
  }
}

class _DraggableDivider extends StatelessWidget {
  const _DraggableDivider({
    Key? key,
    required this.isDraggableDivider,
    required this.onPointerMove,
  }) : super(key: key);

  final bool isDraggableDivider;
  final PointerMoveEventListener onPointerMove;

  @override
  Widget build(BuildContext context) {
    final Container divider = Container(
      color: Colors.transparent,
      constraints:
          const BoxConstraints.expand(width: 3, height: double.infinity),
      child: const ContainerDivider(),
    );
    if (isDraggableDivider) {
      return MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Listener(
          onPointerMove: onPointerMove,
          child: divider,
        ),
      );
    }
    return divider;
  }
}

class TopNavigationContainer extends StatelessWidget {
  const TopNavigationContainer({
    Key? key,
    required this.isNotSinglePage,
    required this.onPopPage,
    required this.pages,
    required this.onBarrierTap,
  }) : super(key: key);

  final bool isNotSinglePage;
  final PopPageCallback onPopPage;
  final List<Page<dynamic>> pages;
  final GestureTapCallback onBarrierTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      key: key,
      child: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              if (isNotSinglePage) {
                onBarrierTap.call();
              }
            },
            child: Container(
              height: double.infinity,
              width: double.infinity,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          Align(
            child: Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 40,
              child: ClipRect(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 600, maxWidth: 500),
                  child: _NavigatorContainer(
                    onPopPage: onPopPage,
                    pages: <Page<dynamic>>[
                      // add stub page for trigger navigation button
                      if (isNotSinglePage)
                        _SimplePage(
                          key: UniqueKey(),
                          animateRouterProvider: () => false,
                          builder: (_) => const SizedBox.shrink(),
                          containerType: ContainerType.top,
                        ),
                      ...pages,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedTopNavigationContainer extends StatelessWidget {
  const AnimatedTopNavigationContainer({
    Key? key,
    required this.isNotSinglePage,
    required this.onPopPage,
    required this.pages,
    required this.onBarrierTap,
  }) : super(key: key);

  final bool isNotSinglePage;
  final PopPageCallback onPopPage;
  final List<Page<dynamic>> pages;
  final GestureTapCallback onBarrierTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: pages.isEmpty
          ? const SizedBox()
          : RemoveToPadding(
              child: TopNavigationContainer(
                isNotSinglePage: isNotSinglePage,
                onPopPage: onPopPage,
                pages: pages,
                onBarrierTap: onBarrierTap,
              ),
            ),
    );
  }
}

class RemoveToPadding extends StatelessWidget {
  const RemoveToPadding({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData baseMediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: baseMediaQuery.copyWith(
        padding: baseMediaQuery.padding.copyWith(top: 0),
      ),
      child: child,
    );
  }
}
