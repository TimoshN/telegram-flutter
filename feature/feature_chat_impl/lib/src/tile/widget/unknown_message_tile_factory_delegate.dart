import 'package:coreui/coreui.dart';
import 'package:feature_chat_impl/src/tile/model/unknown_message_tile_model.dart';
import 'package:feature_chat_impl/src/widget/chat_message/chat_message_factory.dart';
import 'package:feature_chat_impl/src/widget/theme/chat_theme.dart';
import 'package:flutter/material.dart';

class UnknownMessageTileFactoryDelegate
    implements ITileFactoryDelegate<UnknownMessageTileModel> {
  UnknownMessageTileFactoryDelegate(
      {required ChatMessageFactory chatMessageFactory})
      : _chatMessageFactory = chatMessageFactory;

  final ChatMessageFactory _chatMessageFactory;

  @override
  Widget create(BuildContext context, UnknownMessageTileModel model) {
    return _chatMessageFactory.create(
        id: model.id,
        context: context,
        isOutgoing: model.isOutgoing,
        body: Text(
          model.type,
          style: ChatTheme.of(context)
              .bubbleTextStyle
              .copyWith(color: Colors.redAccent),
        ));
  }
}
