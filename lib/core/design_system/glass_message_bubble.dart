// ASON Design System의 채팅 말풍선입니다.
// ASON은 왼쪽(작은 원형 Avatar + Orange Glow), 사용자는 오른쪽(Blue Neon Glow)에 표시됩니다.
// 새 말풍선이 추가되면 Fade + Slide Up으로 부드럽게 나타납니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';
import 'ason_glow.dart';
import 'glow_avatar.dart';

class GlassMessageBubble extends StatefulWidget {
  const GlassMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.glowColor,
    this.showCheckIcon = false,
    this.animate = true,
    this.avatarAssetPath,
    this.senderName = 'ASON',
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Color? glowColor;
  final bool showCheckIcon;
  final bool animate;

  /// ASON 말풍선 왼쪽에 보여줄 캐릭터 이미지 경로입니다. 없으면 기본 아이콘을 사용합니다.
  final String? avatarAssetPath;

  /// ASON 말풍선 상단에 표시할 이름입니다.
  final String senderName;

  @override
  State<GlassMessageBubble> createState() => _GlassMessageBubbleState();
}

class _GlassMessageBubbleState extends State<GlassMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _timeText {
    final dt = widget.timestamp;
    final isAm = dt.hour < 12;
    var hour12 = dt.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${isAm ? '오전' : '오후'} $hour12:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.isUser;
    final glowColor =
        widget.glowColor ?? (isUser ? AsonColors.blueNeon : AsonColors.primary);
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      decoration: BoxDecoration(
        color: (isUser ? AsonColors.userBubble : AsonColors.surfaceNavy)
            .withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: glowColor.withValues(alpha: isUser ? 0.4 : 0.55),
          width: 1.1,
        ),
        boxShadow: AsonGlow.of(
          glowColor,
          blur: 16,
          opacity: isUser ? 0.14 : 0.22,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isUser) ...[
            Text(
              widget.senderName,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AsonColors.primary.withValues(alpha: 0.85),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showCheckIcon) ...[
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOutBack,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: glowColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final timestampRow = Padding(
      padding: EdgeInsets.only(top: 4, left: isUser ? 0 : 42),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUser) ...[
            Icon(
              Icons.done_all_rounded,
              size: 13,
              color: AsonColors.blueNeon.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _timeText,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );

    final content = Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isUser)
          bubble
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(),
              const SizedBox(width: 8),
              Flexible(child: bubble),
            ],
          ),
        timestampRow,
      ],
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final path = widget.avatarAssetPath;
    if (path == null) {
      return const GlowAvatar(
        size: 32,
        icon: Icons.smart_toy_rounded,
        iconSize: 16,
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AsonColors.surfaceNavyLight,
        boxShadow: AsonGlow.of(AsonColors.primary, blur: 10, opacity: 0.35),
        image: DecorationImage(image: AssetImage(path), fit: BoxFit.cover),
      ),
    );
  }
}
