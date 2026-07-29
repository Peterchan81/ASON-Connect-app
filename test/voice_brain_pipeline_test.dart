// 음성 입력 -> BrainEngine -> 실제 기능 실행까지 전체 파이프라인이 하나로 이어져
// 동작하는지 검증합니다. AsonConnectScreen이 실제로 사용하는 것과 같은 조합
// (VoiceService + ConversationManager, MockSpeechProvider로 마이크만 대체)으로
// 위젯 없이 로직만 검증합니다.

import 'package:ason_voice_app/core/voice/voice.dart';
import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/ason_connect/services/conversation_manager.dart';
import 'package:ason_voice_app/features/brain/models/brain_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('음성으로 말한 문장이 VoiceService -> ConversationManager -> BrainEngine을 거쳐'
      ' 곧바로 일정 결과 카드로 만들어진다 (되묻지 않고, 비어 있는 항목은 수정으로 채운다)', () async {
    final voice = VoiceService(
      provider: MockSpeechProvider(
        scriptedText: '내일 오후 3시 대전성모병원 예약',
        respondAfter: const Duration(milliseconds: 10),
      ),
    );
    final manager = ConversationManager();

    await voice.toggle(
      onResult: (text, isFinal) {
        if (!isFinal) return;
        manager.handleUserText(text, inputSource: InputSource.voice);
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    voice.dispose();

    expect(voice.state, VoiceState.success);

    final draft = manager.currentDraft;
    expect(draft?.category, DraftCommandCategory.schedule);
    expect(draft?.date, '내일');
    expect(draft?.time, '오후 3시');
    expect(draft?.location, '대전성모병원');
    expect(draft?.status, DraftCommandStatus.ready);
    expect(manager.messages.last.text, '일정을 저장했습니다.');
  });

  test('음성 인식 결과는 되묻지 않고 곧바로 Summary/Sync가 준비된다', () async {
    final manager = ConversationManager();

    manager.handleUserText('내일 오후 3시에 팀 회의', inputSource: InputSource.voice);

    expect(manager.currentDraft?.status, DraftCommandStatus.ready);
    expect(manager.isSummaryAvailable, isTrue);
    expect(manager.syncPreview, isNotNull);
    expect(manager.syncPreview?.content, '팀 회의');
  });

  test('음성 입력으로 건강/메모/프로젝트도 같은 파이프라인으로 곧바로 처리된다', () {
    final health = ConversationManager();
    health.handleUserText('오늘 아침에 혈압약 먹었어', inputSource: InputSource.voice);
    expect(health.currentDraft?.category, DraftCommandCategory.health);
    expect(health.currentDraft?.status, DraftCommandStatus.ready);

    final memo = ConversationManager();
    memo.handleUserText('우유하고 계란 사야 해', inputSource: InputSource.voice);
    expect(memo.currentDraft?.category, DraftCommandCategory.memo);
    expect(memo.currentDraft?.status, DraftCommandStatus.ready);

    final project = ConversationManager();
    project.handleUserText(
      '새 프로젝트 시작: ASON 리브랜딩',
      inputSource: InputSource.voice,
    );
    expect(project.currentDraft?.category, DraftCommandCategory.project);
    expect(project.currentDraft?.status, DraftCommandStatus.ready);
  });
}
