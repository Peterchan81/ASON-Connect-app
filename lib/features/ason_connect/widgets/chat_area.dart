// 대화 내용을 스크롤 목록으로 보여주는 영역입니다.
// 대화는 화면(위젯) 상태에만 존재하며, 이 위젯은 그 결과만 그립니다.

import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../models/chat_message.dart';

class ChatArea extends StatelessWidget {
  const ChatArea({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final ScrollController scrollController;

  static const String _asonAvatarAsset = 'assets/images/ason_avatar.png';

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return GlassMessageBubble(
          text: message.text,
          isUser: message.sender == ChatSender.user,
          timestamp: message.createdAt,
          glowColor: _glowColorFor(message),
          showCheckIcon: message.messageType == ChatMessageType.syncComplete,
          avatarAssetPath: message.sender == ChatSender.ason
              ? _asonAvatarAsset
              : null,
        );
      },
    );
  }

  Color? _glowColorFor(ChatMessage message) {
    if (message.sender == ChatSender.user) return null;
    switch (message.messageType) {
      case ChatMessageType.error:
        return AsonColors.error;
      case ChatMessageType.syncComplete:
        return AsonColors.success;
      case ChatMessageType.normal:
      case ChatMessageType.question:
      case ChatMessageType.summary:
        return null;
    }
  }
}
