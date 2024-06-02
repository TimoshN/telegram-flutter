import 'package:core_tdlib_api/core_tdlib_api.dart';
import 'package:core_utils/core_utils.dart';
import 'package:feature_chat_impl/src/tile/model/base_conversation_message_tile_model.dart';
import 'package:feature_message_preview_resolver/feature_message_preview_resolver.dart';
import 'package:td_api/td_api.dart' as td;

class MessageReplyInfoMapper {
  MessageReplyInfoMapper({
    required IChatMessageRepository messageRepository,
    required IUserRepository userRepository,
    required IMessagePreviewResolver messagePreviewResolver,
    required IChatRepository chatRepository,
  })  : _messageRepository = messageRepository,
        _chatRepository = chatRepository,
        _messagePreviewResolver = messagePreviewResolver,
        _userRepository = userRepository;

  final IChatMessageRepository _messageRepository;
  final IUserRepository _userRepository;
  final IChatRepository _chatRepository;
  final IMessagePreviewResolver _messagePreviewResolver;

  Future<ReplyInfo?> mapToReplyInfo(td.Message message) async {
    if (message.replyTo == null) {
      return null;
    }

    int chatId = 0;
    int messageId = 0;

    if (message.replyTo is td.MessageReplyToMessage) {
      chatId = (message.replyTo as td.MessageReplyToMessage).chatId;
      messageId = (message.replyTo as td.MessageReplyToMessage).messageId;
    } else if (message.replyTo is td.MessageReplyToStory) {
      return null;
    }

    if (chatId == 0 || messageId == 0) {
      return null;
    }

    final td.Message? replyMessage = await _messageRepository.getMessage(
      chatId: chatId,
      messageId: messageId,
    );

    if (replyMessage == null) {
      return null;
    }

    final MessagePreviewData preview =
        await _messagePreviewResolver.resolve(replyMessage);

    return ReplyInfo(
      replyToMessageId: messageId,
      title: preview.firstText.orEmpty(),
      subtitle: preview.secondText.orEmpty(),
    );
  }

  Future<String> getSenderNameToDisplay(td.MessageSender sender) async {
    switch (sender.getConstructor()) {
      case td.MessageSenderUser.constructor:
        {
          final td.User user = await _userRepository
              .getUser((sender as td.MessageSenderUser).userId);
          return '${user.firstName} ${user.lastName}';
        }
      case td.MessageSenderChat.constructor:
        {
          final td.Chat chat = await _chatRepository
              .getChat((sender as td.MessageSenderChat).chatId);
          return chat.title;
        }
    }
    return '';
  }
}
