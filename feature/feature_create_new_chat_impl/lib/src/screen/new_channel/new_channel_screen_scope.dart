import 'package:feature_create_new_chat_impl/src/di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:localization_api/localization_api.dart';
import 'package:provider_extensions/provider_extensions.dart';

import 'new_channel_controller.dart';
import 'new_channel_view_model.dart';

class CreateNewChannelScreenScore extends StatefulWidget {
  const CreateNewChannelScreenScore({
    Key? key,
    required this.child,
    required this.create,
  }) : super(key: key);

  final Widget child;
  final CreateComponent<ICreateNewChannelScreenComponent> create;

  @override
  State<CreateNewChannelScreenScore> createState() =>
      _CreateNewChannelScreenScoreState();

  static NewChannelViewModel getNewChannelViewModel(BuildContext context) =>
      _InheritedScope.of(context)._viewModel;

  static IStringsProvider getStringsProvider(BuildContext context) =>
      _InheritedScope.of(context)._stringsProvider;

  static NewChannelController getNewChannelController(BuildContext context) =>
      _InheritedScope.of(context)._newChannelController;
}

class _CreateNewChannelScreenScoreState
    extends State<CreateNewChannelScreenScore> {
  late final ICreateNewChannelScreenComponent _component = widget.create.call();

  late final NewChannelViewModel _viewModel =
      _component.getNewChannelViewModel();

  late final IStringsProvider _stringsProvider =
      _component.getLocalizationManager().stringsProvider;

  late final NewChannelController _newChannelController =
      _component.getNewChannelController();

  @override
  Widget build(BuildContext context) {
    return _InheritedScope(
      holderState: this,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _newChannelController.dispose();
    super.dispose();
  }
}

class _InheritedScope extends InheritedWidget {
  const _InheritedScope({
    Key? key,
    required Widget child,
    required _CreateNewChannelScreenScoreState holderState,
  })  : _state = holderState,
        super(key: key, child: child);

  final _CreateNewChannelScreenScoreState _state;

  static _CreateNewChannelScreenScoreState of(BuildContext context) {
    final _CreateNewChannelScreenScoreState? result = (context
            .getElementForInheritedWidgetOfExactType<_InheritedScope>()
            ?.widget as _InheritedScope?)
        ?._state;
    assert(result != null, 'No CreateNewChannelScreenScore found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(_InheritedScope oldWidget) => false;
}