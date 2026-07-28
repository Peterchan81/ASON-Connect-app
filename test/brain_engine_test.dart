// BrainEngine이 ConversationManager를 대신해 실제로 판단(분류/추출/누락 필드/질문
// 계획/Summary·Sync 준비 여부)을 올바르게 수행하는지 검증합니다. Sprint 12A에서
// ConversationManager 내부에 섞여 있던 판단 흐름을 이 계층으로 옮기면서, 화면(위젯)
// 없이도 판단 로직만 독립적으로 검증할 수 있도록 추가했습니다.

import 'package:ason_voice_app/features/ason_connect/models/chat_message.dart';
import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/brain/brain_engine.dart';
import 'package:ason_voice_app/features/brain/models/brain_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Intent 분석', () {
    test('일정 문장은 schedule로 분류된다', () {
      final result = BrainEngine().process(BrainInput(text: '내일 오후 3시에 팀 회의'));

      expect(result.intent?.category, DraftCommandCategory.schedule);
      expect(result.intent?.isUnclassified, isFalse);
      expect(result.draft?.category, DraftCommandCategory.schedule);
    });

    test('건강 문장은 health로 분류된다', () {
      final result = BrainEngine().process(BrainInput(text: '오늘 몸무게 72.5kg'));

      expect(result.intent?.category, DraftCommandCategory.health);
      expect(result.draft?.category, DraftCommandCategory.health);
    });

    test('메모 문장은 memo로 분류된다', () {
      final result = BrainEngine().process(BrainInput(text: '우유하고 계란 사야 해'));

      expect(result.intent?.category, DraftCommandCategory.memo);
      expect(result.draft?.category, DraftCommandCategory.memo);
    });

    test('미분류 입력은 draft 없이 일반 응답만 돌려준다', () {
      final result = BrainEngine().process(
        BrainInput(text: '안녕하세요 오늘 날씨가 좋네요'),
      );

      expect(result.intent?.isUnclassified, isTrue);
      expect(result.isUncertain, isTrue);
      expect(result.draft, isNull);
      expect(result.messages, isNotEmpty);
    });

    test('신뢰도가 낮아 애매한 입력은 후보 카테고리를 되묻는다', () {
      final result = BrainEngine().process(
        BrainInput(text: '아이디어 메모, ASON 음성 앱 개선'),
      );

      expect(result.isUncertain, isTrue);
      expect(result.draft?.status, DraftCommandStatus.clarifyingCategory);
      expect(result.draft?.candidateCategories.length, 2);
      expect(result.draft?.candidateCategories.toSet(), {
        DraftCommandCategory.memo,
        DraftCommandCategory.project,
      });
      expect(result.messages.single.type, ChatMessageType.question);
    });
  });

  group('Entity 추출', () {
    test('일정 문장에서 날짜/시간/내용을 뽑아낸다', () {
      final result = BrainEngine().process(BrainInput(text: '내일 오후 3시에 팀 회의'));

      expect(result.entities?.date, '내일');
      expect(result.entities?.time, '오후 3시');
      expect(result.entities?.title, '팀 회의');
      expect(result.draft?.date, '내일');
      expect(result.draft?.time, '오후 3시');
      expect(result.draft?.title, '팀 회의');
    });
  });

  group('부족한 필드 계산과 질문 생성', () {
    test('알림만 남으면 알림 하나만 되묻는다', () {
      final result = BrainEngine().process(BrainInput(text: '내일 오후 3시에 팀 회의'));

      expect(result.draft?.status, DraftCommandStatus.collecting);
      expect(result.missingFields, ['alarm']);
      expect(result.messages.single.type, ChatMessageType.question);
      expect(
        result.messages.single.text,
        '일정을 확인했습니다.\n알림을 설정하시겠습니까?\n예: 30분 전 알림',
      );
    });
  });

  group('Summary/Sync 준비 상태', () {
    test('건강 입력은 곧바로 Summary/Sync 준비 상태가 된다', () {
      final result = BrainEngine().process(BrainInput(text: '오늘 몸무게 72.5kg'));

      expect(result.draft?.status, DraftCommandStatus.ready);
      expect(result.summaryReady, isTrue);
    });

    test('건강 입력은 Sync도 함께 준비된다', () {
      final result = BrainEngine().process(BrainInput(text: '오늘 몸무게 72.5kg'));

      expect(result.syncReady, isTrue);
    });

    test('일정 수집이 끝나지 않으면 Summary/Sync 모두 준비되지 않는다', () {
      final result = BrainEngine().process(BrainInput(text: '내일 오후 3시에 팀 회의'));

      expect(result.summaryReady, isFalse);
      expect(result.syncReady, isFalse);
    });
  });

  group('기존 DraftCommand 수정 입력', () {
    test('editing 상태의 draft에 수정 문장을 주면 해당 필드만 바뀌고 다시 ready가 된다', () {
      final engine = BrainEngine();

      final started = engine.process(
        BrainInput(text: '내일 오후 3시에 둔산동에서 김 과장과 미팅'),
      );
      final afterAlarm = engine.process(
        BrainInput(text: '없음', draft: started.draft),
      );
      expect(afterAlarm.draft?.status, DraftCommandStatus.ready);

      final editingDraft = afterAlarm.draft!.copyWith(
        status: DraftCommandStatus.editing,
      );
      final corrected = engine.process(
        BrainInput(text: '시간을 오후 4시로 바꿔줘', draft: editingDraft),
      );

      expect(corrected.draft?.status, DraftCommandStatus.ready);
      expect(corrected.draft?.time, '오후 4시');
      expect(corrected.messages.length, 2);
      expect(corrected.messages.first.text, '시간을 오후 4시로 변경했습니다.');
      expect(corrected.messages.last.type, ChatMessageType.summary);
    });
  });

  group('빈 입력 처리', () {
    test('공백만 있는 입력은 draft를 바꾸지 않고 메시지도 만들지 않는다', () {
      final result = BrainEngine().process(BrainInput(text: '   '));

      expect(result.messages, isEmpty);
      expect(result.draft, isNull);
    });
  });
}
