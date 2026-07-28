// ConfirmationHandler가 애매한 분류(status == clarifyingCategory)에 대한 사용자의
// 확인/취소 응답을 올바르게 처리하는지 검증합니다.

import 'package:ason_voice_app/features/ason_connect/models/draft_command.dart';
import 'package:ason_voice_app/features/brain/brain_engine.dart';
import 'package:ason_voice_app/features/brain/models/brain_input.dart';
import 'package:ason_voice_app/features/brain/models/brain_turn_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = BrainEngine();

  test('확인: 후보 중 하나를 이름으로 답하면 그 카테고리로 draft가 시작된다', () {
    final ambiguous = engine.process(BrainInput(text: '아이디어 메모, ASON 음성 앱 개선'));
    expect(ambiguous.draft?.status, DraftCommandStatus.clarifyingCategory);
    expect(ambiguous.draft?.candidateCategories, isNotEmpty);

    final confirmed = engine.process(
      BrainInput(text: '메모', draft: ambiguous.draft),
    );

    expect(confirmed.draft?.category, DraftCommandCategory.memo);
    expect(confirmed.draft?.status, DraftCommandStatus.ready);
  });

  test('후보 이름과 무관한 답변은 첫 번째 후보로 처리된다 (실제 취소 경로는 없음)', () {
    final ambiguous = engine.process(BrainInput(text: '아이디어 메모, ASON 음성 앱 개선'));
    final candidates = ambiguous.draft!.candidateCategories;
    expect(candidates.length, 2);

    // "그만할래"는 두 후보 라벨(메모/프로젝트) 중 어느 것도 포함하지 않지만,
    // 기존 로직은 이름이 일치하지 않으면 첫 번째 후보로 처리합니다.
    // (candidateCategories가 실제로 비어 있는 경우는 대화 흐름상 발생하지 않아서,
    // 진짜 "취소"로 draft가 초기화되는 경로는 아래 방어적 테스트로 확인합니다)
    final result = engine.process(
      BrainInput(text: '그만할래', draft: ambiguous.draft),
    );

    expect(result.draft?.category, candidates.first);
  });

  test('취소(방어적 상황): candidateCategories가 비어 있으면 draft를 초기화한다', () {
    final defensiveDraft = DraftCommand(
      originalText: '테스트',
      status: DraftCommandStatus.clarifyingCategory,
      candidateCategories: const [],
    );

    final result = engine.process(
      BrainInput(text: '아무 말', draft: defensiveDraft),
    );

    expect(result.draft, isNull);
    expect(result.isUncertain, isTrue);
    expect(result.turnType, BrainTurnType.fallback);
    expect(result.messages, isNotEmpty);
  });
}
