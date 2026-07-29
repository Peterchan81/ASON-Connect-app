// 한 턴을 처리하는 동안 Handler들이 필요로 하는 모든 것을 담는 불변 컨테이너입니다.
// BrainEngine이 process() 호출마다 하나씩 만들어서 Handler에 전달합니다.
// Flutter Widget/BuildContext에 의존하지 않습니다.

import '../../ason_connect/models/draft_command.dart';
import '../../ason_connect/services/command_parser_service.dart';
import '../../ason_connect/services/conversation_heuristics.dart';
import '../../ason_connect/services/korean_location_service.dart';
import '../models/brain_input.dart';
import '../services/brain_summary_builder.dart';
import '../services/brain_sync_builder.dart';
import '../services/entity_analyzer.dart';
import '../services/intent_analyzer.dart';

class BrainContext {
  const BrainContext({
    required this.input,
    required this.intentAnalyzer,
    required this.entityAnalyzer,
    required this.summaryBuilder,
    required this.syncBuilder,
    required this.heuristics,
    required this.parser,
    required this.locationService,
  });

  final BrainInput input;
  final IntentAnalyzer intentAnalyzer;
  final EntityAnalyzer entityAnalyzer;
  final BrainSummaryBuilder summaryBuilder;
  final BrainSyncBuilder syncBuilder;
  final ConversationHeuristics heuristics;

  /// 필드별 값 채우기/질문 문구/수정 적용 등 DraftCommand 형태에 딱 맞춘 세부 유틸리티가
  /// 필요할 때 사용합니다. (CommandParserService 자체는 기존 코드를 그대로 재사용)
  final CommandParserService parser;
  final KoreanLocationService locationService;

  /// 지금 작성 중이던 내용입니다. 새 주제라면 null입니다.
  DraftCommand? get draft => input.draft;

  /// 앞뒤 공백을 정리한 사용자 원문입니다.
  String get rawText => input.text.trim();

  /// 이번 입력이 음성/문자 중 어디서 왔는지입니다.
  InputSource get inputSource => input.inputSource;
}
