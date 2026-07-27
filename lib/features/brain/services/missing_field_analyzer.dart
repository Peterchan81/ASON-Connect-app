// 지금 draft에 아직 채워지지 않은 필드가 무엇인지 판단하는 인터페이스입니다.

import '../../ason_connect/models/draft_command.dart';
import '../../ason_connect/services/command_parser_service.dart';

abstract class MissingFieldAnalyzer {
  /// 아직 채워지지 않은 모든 항목입니다. (순서대로)
  List<String> missingFields(DraftCommand draft);
}

/// 기존 CommandParserService의 일정 필드 판단 로직을 그대로 재사용하는 구현입니다.
class RuleBasedMissingFieldAnalyzer implements MissingFieldAnalyzer {
  const RuleBasedMissingFieldAnalyzer(this._parser);

  final CommandParserService _parser;

  @override
  List<String> missingFields(DraftCommand draft) =>
      _parser.allMissingScheduleFields(draft);
}
