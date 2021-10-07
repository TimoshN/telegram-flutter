import 'package:core_tdlib_api/core_tdlib_api.dart';
import 'package:coreui/coreui.dart' as tg;
import 'package:feature_chat_impl/src/resolver/message_component_resolver.dart';
import 'package:feature_chat_impl/src/wall/message_wall_context.dart';
import 'package:feature_chat_impl/src/widget/chat_message/chat_message.dart';
import 'package:feature_chat_impl/src/widget/chat_message/reply_info_factory.dart';
import 'package:feature_chat_impl/src/widget/chat_message/sender_avatar_factory.dart';
import 'package:feature_chat_impl/src/widget/chat_message/sender_title_factory.dart';
import 'package:feature_chat_impl/src/widget/chat_message/short_info_factory.dart';
import 'package:feature_chat_impl/src/widget/factory/messages_tile_factory_factory.dart';
import 'package:feature_file_api/feature_file_api.dart';
import 'package:localization_api/localization_api.dart';
import 'package:tile/tile.dart';

class MessageTileFactoryDependencies {
  const MessageTileFactoryDependencies({
    required this.fileRepository,
    required this.localizationManager,
    required this.messageWallContext,
    required this.messageActionListener,
    required this.fileDownloader,
  });

  final ILocalizationManager localizationManager;
  final IFileRepository fileRepository;
  final IMessageWallContext messageWallContext;
  final IMessageActionListener messageActionListener;
  final IFileDownloader fileDownloader;
}

abstract class IMessageActionListener {
  void onSenderAvatarTap({required int senderId});
}

class MessageTileFactoryComponent {
  MessageTileFactoryComponent({
    required MessageTileFactoryDependencies dependencies,
  }) : _dependencies = dependencies;

  final MessageTileFactoryDependencies _dependencies;

  TileFactory create() {
    final MessagesTileFactoryFactory tileFactoryFactory =
        MessagesTileFactoryFactory();

    final ShortInfoFactory shortInfoFactory = ShortInfoFactory(
      localizationManager: _dependencies.localizationManager,
    );
    final ReplyInfoFactory replyInfoFactory = ReplyInfoFactory();
    final SenderTitleFactory senderTitleFactory = SenderTitleFactory();

    final tg.AvatarWidgetFactory avatarWidgetFactory =
        tg.AvatarWidgetFactory(fileRepository: _dependencies.fileRepository);
    const ChatMessageFactory chatMessageFactory = ChatMessageFactory();

    final SenderAvatarFactory senderAvatarFactory =
        SenderAvatarFactory(avatarWidgetFactory: avatarWidgetFactory);

    final MessageComponentResolver componentResolver = MessageComponentResolver(
      senderAvatarFactory: senderAvatarFactory,
      messageWallContext: _dependencies.messageWallContext,
      senderTitleFactory: senderTitleFactory,
      messageActionListener: _dependencies.messageActionListener,
    );

    return tileFactoryFactory.create(
      imageWidgetFactory: tg.ImageWidgetFactory(
        fileDownloader: _dependencies.fileDownloader,
      ),
      messageComponentResolver: componentResolver,
      senderAvatarFactory: senderAvatarFactory,
      messageWallContext: _dependencies.messageWallContext,
      senderTitleFactory: senderTitleFactory,
      replyInfoFactory: replyInfoFactory,
      shortInfoFactory: shortInfoFactory,
      localizationManager: _dependencies.localizationManager,
      chatMessageFactory: chatMessageFactory,
    );
  }
}
