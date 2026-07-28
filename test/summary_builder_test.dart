// SummaryBuilder(Sprint 11에서 ConversationManager로부터 분리)가 DraftCommand로부터
// 확인 카드의 제목/행과 SyncPayload를 올바르게 구성하는지 검증합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/summary_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = SummaryBuilder();

  group('일정 요약/SyncPayload', () {
    DraftCommand scheduleDraft() => DraftCommand(
      originalText: '내일 오후 3시에 김 과장과 미팅',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.schedule,
      date: '내일',
      time: '오후 3시',
      title: '김 과장과 미팅',
      location: '대전 둔산동',
      alarm: '30분 전',
    );

    test('제목은 "일정 요약"이다', () {
      expect(builder.title(scheduleDraft()), '일정 요약');
    });

    test('행은 시간 -> 내용 -> 장소 -> 알림 -> 반복 -> 메모 순서다', () {
      final rows = builder.rows(scheduleDraft());

      expect(rows.map((e) => e.key).toList(), [
        '시간',
        '내용',
        '장소',
        '알림',
        '반복',
        '메모',
      ]);
      expect(rows[0].value, '내일 오후 3시');
      expect(rows[1].value, '김 과장과 미팅');
      expect(rows[2].value, '대전 둔산동');
      expect(rows[3].value, '30분 전');
      // 반복/메모는 채워지지 않았으므로 기본 표시값을 사용한다.
      expect(rows[4].value, '없음');
      expect(rows[5].value, '-');
    });

    test('SyncPayload는 정리된 핵심 값만 담는다', () {
      final payload = builder.payload(scheduleDraft());

      expect(payload.category, '일정');
      expect(payload.content, '김 과장과 미팅');
      expect(payload.time, '내일 오후 3시');
      expect(payload.location, '대전 둔산동');
      expect(payload.alarm, '30분 전');
      expect(payload.repeat, '없음');
      expect(payload.memo, '-');
    });
  });

  group('건강 요약/SyncPayload', () {
    DraftCommand healthDraft() => DraftCommand(
      originalText: '오늘 혈압이 128에 82야.',
      status: DraftCommandStatus.ready,
      category: DraftCommandCategory.health,
      date: '오늘',
      healthItem: '혈압',
      title: '128 / 82 mmHg',
    );

    test('제목은 "건강 요약"이다', () {
      expect(builder.title(healthDraft()), '건강 요약');
    });

    test('SyncPayload의 content는 "항목 : 값" 형태다', () {
      final payload = builder.payload(healthDraft());

      expect(payload.category, '건강');
      expect(payload.content, '혈압 : 128 / 82 mmHg');
      expect(payload.time, '오늘');
    });
  });

  group('메모 요약/SyncPayload', () {
    test('메모는 종류(기본값 일반) -> 내용 순서로 보여준다', () {
      final draft = DraftCommand(
        originalText: '우유하고 계란 사야 해',
        status: DraftCommandStatus.ready,
        category: DraftCommandCategory.memo,
        title: '우유와 계란 구매',
      );

      final rows = builder.rows(draft);
      expect(rows.map((e) => e.key).toList(), ['종류', '내용']);
      expect(rows[0].value, '일반');
      expect(rows[1].value, '우유와 계란 구매');

      final payload = builder.payload(draft);
      expect(payload.category, '메모');
      expect(payload.content, '우유와 계란 구매');
      expect(payload.subType, '일반');
    });

    test('아이디어 메모는 종류가 "아이디어"로 표시된다', () {
      final draft = DraftCommand(
        originalText: '아이디어 메모, ASON 음성 앱 개선',
        status: DraftCommandStatus.ready,
        category: DraftCommandCategory.memo,
        title: 'ASON 음성 앱 개선',
        memoType: '아이디어',
      );

      final rows = builder.rows(draft);
      expect(rows[0].value, '아이디어');
    });
  });

  group('프로젝트 요약/SyncPayload', () {
    test('활동 기본값은 "생성"이고, 진행률이 없으면 행에 나타나지 않는다', () {
      final draft = DraftCommand(
        originalText: '새 프로젝트 시작: ASON 리브랜딩',
        status: DraftCommandStatus.ready,
        category: DraftCommandCategory.project,
        title: 'ASON 리브랜딩',
      );

      final rows = builder.rows(draft);
      expect(rows.map((e) => e.key).toList(), ['활동', '내용']);
      expect(rows[0].value, '생성');
      expect(rows[1].value, 'ASON 리브랜딩');
    });

    test('진행률이 있으면 활동 -> 내용 -> 진행률 순서로 보여준다', () {
      final draft = DraftCommand(
        originalText: 'ASON 리브랜딩 진행률 60%로 수정',
        status: DraftCommandStatus.ready,
        category: DraftCommandCategory.project,
        title: 'ASON 리브랜딩',
        projectAction: '수정',
        progress: '60%',
      );

      final rows = builder.rows(draft);
      expect(rows.map((e) => e.key).toList(), ['활동', '내용', '진행률']);
      expect(rows[0].value, '수정');
      expect(rows[2].value, '60%');

      final payload = builder.payload(draft);
      expect(payload.subType, '수정');
      expect(payload.progress, '60%');
    });
  });
}
