// ASON Design System의 최종 확인 카드입니다.
// Cyber Card(Glassmorphism + Glow Border + 모서리 HUD 장식) 스타일로,
// 통합 시스템과 동일한 순서의 라벨-값 목록과 액션 버튼(수정/동기화)을 보여줍니다.

import 'package:flutter/material.dart';

import 'ason_colors.dart';
import 'glow_button.dart';
import 'glow_card.dart';
import 'hud_panel.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    this.rows = const [],
    this.summaryLine,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final List<MapEntry<String, String>> rows;
  final String? summaryLine;
  final String primaryLabel;

  /// null이면 버튼이 비활성 상태로 표시됩니다. (예: 수정 질문에 아직 답하지 않은 동안)
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  static const Map<String, IconData> _fieldIcons = {
    '시간': Icons.schedule_rounded,
    '날짜': Icons.event_rounded,
    '내용': Icons.notes_rounded,
    '장소': Icons.place_rounded,
    '알림': Icons.notifications_active_rounded,
    '반복': Icons.repeat_rounded,
    '메모': Icons.sticky_note_2_rounded,
    '항목': Icons.favorite_rounded,
    '종류': Icons.category_rounded,
    '활동': Icons.flag_rounded,
    '진행률': Icons.trending_up_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: AsonColors.primary,
      glowOpacity: 0.26,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: HudCornerOverlay(
        accentColor: AsonColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: AsonColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AsonColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < rows.length; i++) ...[
              _row(rows[i].key, rows[i].value),
              if (i != rows.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
            ],
            if (summaryLine != null && summaryLine!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                summaryLine!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                if (secondaryLabel != null && onSecondary != null) ...[
                  Expanded(
                    child: GlowButton(
                      label: secondaryLabel!,
                      onPressed: onSecondary,
                      variant: GlowButtonVariant.dark,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: GlowButton(label: primaryLabel, onPressed: onPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    final icon = _fieldIcons[label] ?? Icons.label_important_rounded;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: AsonColors.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: TextStyle(
                fontSize: 13,
                color: AsonColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
