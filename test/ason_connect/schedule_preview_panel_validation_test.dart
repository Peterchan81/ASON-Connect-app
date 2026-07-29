// 카드 UI 자체가 실제로 내용 없는 결과에 대해 동기화 버튼을 비활성화하고
// 안내 문구를 보여주는지(질문이 아니라 정적 문구) 위젯 레벨에서 확인합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/widgets/schedule_preview_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('내용이 없는 카드는 동기화 버튼이 비활성화되고 안내 문구가 표시된다', (tester) async {
    final draft = DraftCommand(
      originalText: '미팅 있어',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.schedule,
    );

    var syncTapped = false;
    await tester.pumpWidget(
      _wrap(
        SchedulePreviewPanel(
          draft: draft,
          isPreviewOnly: false,
          pendingQuestion: null,
          syncError: null,
          onEdit: () {},
          onSync: () => syncTapped = true,
        ),
      ),
    );

    expect(find.text('내용을 입력하거나 수정해 주세요.'), findsOneWidget);
    // "일정 내용은 무엇인가요?" 같은 질문형 문구는 나타나지 않는다.
    expect(find.textContaining('무엇인가요'), findsNothing);

    // GlowButton은 InkWell 기반이라 탭을 시도해도 onPressed가 null이면 아무 일도
    // 일어나지 않아야 합니다.
    await tester.tap(find.text('ASON에 동기화'), warnIfMissed: false);
    await tester.pump();
    expect(syncTapped, isFalse);
    // 수정 버튼은 여전히 활성화 상태를 유지합니다.
    expect(find.text('수정'), findsOneWidget);
  });

  testWidgets('내용이 있는 카드는 동기화 버튼이 정상 동작한다', (tester) async {
    final draft = DraftCommand(
      originalText: '내일 오후 3시 광고미팅',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.schedule,
      title: '광고미팅',
    );

    var syncTapped = false;
    await tester.pumpWidget(
      _wrap(
        SchedulePreviewPanel(
          draft: draft,
          isPreviewOnly: false,
          pendingQuestion: null,
          syncError: null,
          onEdit: () {},
          onSync: () => syncTapped = true,
        ),
      ),
    );

    expect(find.text('내용을 입력하거나 수정해 주세요.'), findsNothing);
    await tester.tap(find.text('ASON에 동기화'));
    await tester.pump();
    expect(syncTapped, isTrue);
  });
}
