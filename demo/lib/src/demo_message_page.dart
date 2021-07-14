import 'package:core_utils/core_utils.dart';
import 'package:coreui/coreui.dart' as tg;
import 'package:demo/src/message_data.dart';
import 'package:fake/fake.dart' as fake;
import 'package:feature_chat_impl/feature_chat_impl.dart' as chat_impl;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:localization_impl/localization_impl.dart';
import 'package:tdlib/td_api.dart' as td;

import 'message_bundle.dart';

class DemoMessagePage extends StatefulWidget {
  const DemoMessagePage({
    Key? key,
    required this.bundle,
  }) : super(key: key);

  final MessageBundle bundle;

  @override
  _DemoMessagePageState createState() => _DemoMessagePageState();
}

class _DemoMessagePageState extends State<DemoMessagePage> {
  late tg.TileFactory _tileFactory;

  late chat_impl.MessageTileMapper _messageTileMapper;

  bool _isReady = false;
  bool _isShowAll = true;
  late MessageData _currentMessage;

  @override
  void initState() {
    super.initState();
    _currentMessage = widget.bundle.messages.first;
    _init().then((_) {
      setState(() {
        _isReady = true;
      });
      return null;
    });
  }

  Future<void> _init() async {
    final fake.FakeFileRepository fakeFileRepository =
        fake.FakeFileRepository();
    final chat_impl.ChatMessageFactory chatMessageFactory =
        chat_impl.ChatMessageFactory(
      avatarWidgetFactory:
          tg.AvatarWidgetFactory(fileRepository: fakeFileRepository),
    );
    final chat_impl.ShortInfoFactory shortInfoFactory =
        chat_impl.ShortInfoFactory();
    final chat_impl.FormattedTextResolver formattedTextResolver =
        chat_impl.FormattedTextResolver();
    _tileFactory = chat_impl.MessagesTileFactoryFactory().create(
        chatMessageFactory: chatMessageFactory,
        shortInfoFactory: shortInfoFactory);

    final LocalizationManager localizationManager = LocalizationManager();
    await localizationManager.init('en', 'en');

    final DateParser dateParser = DateParser();

    _messageTileMapper = chat_impl.MessageTileMapper(
        dateParser: dateParser,
        localizationManager: localizationManager,
        formattedTextResolver: formattedTextResolver);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_currentMessage.name),
        ),
        backgroundColor: Colors.yellow,
        body: Column(
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('show all'),
                Switch(
                    value: _isShowAll,
                    onChanged: (bool newValue) {
                      setState(() {
                        _isShowAll = newValue;
                      });
                    }),
              ],
            ),
            if (!_isShowAll) _buildMessageDropdownButton(),
            if (_isShowAll)
              _buildAllMessages()
            else
              _buildSingleMessage(_currentMessage.messageFactory())
          ],
        ),
      );

  Widget _buildAllMessages() => Expanded(
        child: ListView.separated(
            itemBuilder: (BuildContext context, int index) {
              final MessageData messageData = widget.bundle.messages[index];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(messageData.name),
                  _buildSingleMessage(messageData.messageFactory())
                ],
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(
                  height: 8,
                ),
            itemCount: widget.bundle.messages.length),
      );

  Widget _buildSingleMessage(Future<td.Message> future) =>
      FutureBuilder<td.Message>(
        future: future,
        builder: (BuildContext context, AsyncSnapshot<td.Message> snapshot) {
          if (_isReady && snapshot.hasData) {
            return _wrapToRequiredWidgets(child: _buildMessage(snapshot.data!));
          }
          return const SizedBox();
        },
      );

  Widget _buildMessage(td.Message message) => Builder(
        builder: (BuildContext context) => _tileFactory.create(
            context, _messageTileMapper.mapToTileModel(message)),
      );

  chat_impl.ChatTheme _wrapToRequiredWidgets({required Widget child}) =>
      chat_impl.ChatTheme(
        data: chat_impl.ChatThemeData.light(context: context),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) =>
              chat_impl.ChatContext(
            data: chat_impl.ChatContextData.desktop(
                maxWidth: constraints.maxWidth),
            child: child,
          ),
        ),
      );

  DropdownButton<MessageData> _buildMessageDropdownButton() =>
      DropdownButton<MessageData>(
        value: _currentMessage,
        items: widget.bundle.messages
            .map<DropdownMenuItem<MessageData>>((MessageData value) {
          return DropdownMenuItem<MessageData>(
            value: value,
            child: Text(
              value.name,
            ),
          );
        }).toList(),
        onChanged: (MessageData? message) {
          setState(() {
            _currentMessage = message!;
          });
        },
      );
}
