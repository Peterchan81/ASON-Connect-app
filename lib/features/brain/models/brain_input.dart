// BrainEngine.process()에 전달하는 입력입니다.
// 화면(위젯)이나 대화 이력 자체가 아니라, 이번 턴을 판단하는 데 필요한 값만 담습니다.
//
// 현재 대화 단계/카테고리는 [draft]의 status/category에 이미 담겨 있으므로 별도
// 필드로 중복 전달하지 않고, BrainEngine이 draft로부터 파생해서 사용합니다.

import '../../ason_connect/models/draft_command.dart';

/// 이번 입력이 어디서 왔는지입니다. 지금은 어떤 값이든 판단 로직에 영향을 주지 않으며,
/// 향후 음성/문자별로 다른 신뢰도를 적용하고 싶을 때 사용할 수 있도록 미리 마련해 둔
/// 자리입니다.
enum InputSource { voice, keyboard, unknown }

class BrainInput {
  BrainInput({
    required this.text,
    this.draft,
    this.inputSource = InputSource.unknown,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  /// 사용자가 음성 또는 문자로 전달한 원문 문장입니다.
  final String text;

  /// 지금 작성 중이던 내용입니다. 새 주제라면 null입니다.
  final DraftCommand? draft;

  final InputSource inputSource;

  /// 이번 판단이 일어난 시각입니다. (테스트에서 고정된 시각을 주입할 수 있도록 분리)
  final DateTime now;

  BrainInput copyWith({
    String? text,
    DraftCommand? draft,
    InputSource? inputSource,
    DateTime? now,
  }) {
    return BrainInput(
      text: text ?? this.text,
      draft: draft ?? this.draft,
      inputSource: inputSource ?? this.inputSource,
      now: now ?? this.now,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrainInput &&
          other.text == text &&
          other.draft == draft &&
          other.inputSource == inputSource &&
          other.now == now);

  @override
  int get hashCode => Object.hash(text, draft, inputSource, now);

  @override
  String toString() =>
      'BrainInput(text: $text, draft: $draft, inputSource: $inputSource)';
}
