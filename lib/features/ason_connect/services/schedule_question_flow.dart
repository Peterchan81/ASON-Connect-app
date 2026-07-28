// 일정 대화 중 "부족한 정보가 무엇인지 판단"하고 "그것을 어떤 문구로 물어볼지"를
// 담당합니다. 실제 문장에서 필드를 추출/저장하는 일(CommandParserService)이나 대화
// 상태 전이(ConversationManager)와는 분리된, 질문 흐름 전용 로직입니다.

import '../models/draft_command.dart';
import 'command_parser_service.dart';

class ScheduleQuestionFlow {
  // 실제 사람과 대화하듯 한 번에 하나씩만 묻습니다.
  const ScheduleQuestionFlow({required this._parser, this._maxBatchSize = 1});

  final CommandParserService _parser;

  // 한 번에 묶어서 물어볼 수 있는 항목의 최대 개수입니다.
  final int _maxBatchSize;

  static const List<String> _numbering = ['①', '②', '③', '④', '⑤'];

  /// 이번 턴에 실제로 물어볼 항목입니다. 부족한 항목이 많아도 최대 [_maxBatchSize]개까지만
  /// 먼저 묻고, 나머지는 답변을 받은 뒤 다음 턴에 이어서 묻습니다.
  List<String> nextBatch(DraftCommand draft) {
    final missing = _parser.allMissingScheduleFields(draft);
    return missing.length > _maxBatchSize
        ? missing.sublist(0, _maxBatchSize)
        : missing;
  }

  /// [batch]에 대한 질문 문구입니다. 항목이 하나면 단일 질문을, 여러 개면 번호를 매긴
  /// 묶음 질문을 만듭니다.
  String questionFor(List<String> batch, DraftCommand draft) {
    if (batch.length == 1) {
      final field = batch.first;
      final question = _parser.questionForScheduleField(field, draft);
      // 다른 항목이 이미 다 채워진 상태에서 알림만 남았다면, 자연스러운 확인 인사를 덧붙입니다.
      return field == 'alarm' ? '일정을 확인했습니다.\n$question' : question;
    }
    return _buildBatchQuestion(batch);
  }

  /// 부족한 항목 여러 개를 한 번에 묻는 문구를 만듭니다.
  /// 예: "① 시간 ② 알림 여부" — 답변은 줄바꿈 또는 쉼표로 구분해 한 번에 받을 수 있습니다.
  String _buildBatchQuestion(List<String> fields) {
    final buffer = StringBuffer('일정을 등록하기 위해\n다음 내용을 알려주세요.\n\n');

    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final label =
          CommandParserService.scheduleBatchLabel[field] ??
          CommandParserService.fieldKeyToLabel[field] ??
          field;
      final mark = _numbering[i % _numbering.length];
      buffer.writeln('$mark $label');
    }

    buffer.write('\n한 번에 답변하셔도 됩니다.');
    return buffer.toString();
  }
}
