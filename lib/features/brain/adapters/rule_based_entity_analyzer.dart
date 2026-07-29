// EntityAnalyzer의 규칙 기반 구현입니다. 기존에 이미 검증된 CommandParserService의
// 카테고리별 추출 로직(ScheduleFieldExtractor/HealthFieldExtractor/ContentNormalizer/
// FieldCorrectionParser)을 그대로 재사용하고, 결과만 EntityResult 모양으로 옮겨 담습니다.

import '../../ason_connect/models/draft_command.dart';
import '../../ason_connect/services/command_parser_service.dart';
import '../../ason_connect/services/daily_goal_field_extractor.dart';
import '../../ason_connect/services/memo_classifier.dart';
import '../../ason_connect/services/project_field_extractor.dart';
import '../models/entity_result.dart';
import '../services/entity_analyzer.dart';

class RuleBasedEntityAnalyzer implements EntityAnalyzer {
  const RuleBasedEntityAnalyzer(this._parser);

  final CommandParserService _parser;

  @override
  EntityResult extract(DraftCommandCategory category, String text) {
    switch (category) {
      case DraftCommandCategory.schedule:
        final extracted = _parser.extractScheduleFields(text);
        return EntityResult(
          date: extracted.date,
          time: extracted.time,
          location: extracted.location,
          title: extracted.title,
          pendingLocationGuess: extracted.pendingLocationGuess,
          pendingLocationOriginal: extracted.pendingLocationOriginal,
          alarm: extracted.alarm,
          repeatOption: extracted.repeatOption,
        );
      case DraftCommandCategory.health:
        final extracted = _parser.extractHealthFields(text);
        return EntityResult(
          date: extracted.date,
          healthItem: extracted.item,
          title: extracted.value,
        );
      case DraftCommandCategory.memo:
        final isFiller = MemoClassifier.isGenericFiller(text);
        return EntityResult(
          title: isFiller ? null : _parser.normalizeMemoContent(text),
          memoType: MemoClassifier.classify(text),
        );
      case DraftCommandCategory.todo:
        return EntityResult(title: _parser.normalizeMemoContent(text));
      case DraftCommandCategory.project:
        return EntityResult(
          title: ProjectFieldExtractor.cleanTitle(
            _parser.cleanFreeformContent(text),
          ),
          projectAction: ProjectFieldExtractor.detectAction(text),
          progress: ProjectFieldExtractor.extractProgress(text),
        );
      case DraftCommandCategory.dailyGoal:
        final repeat = DailyGoalFieldExtractor.extractRepeat(text);
        final title = DailyGoalFieldExtractor.extractTitle(text, repeat: repeat);
        return EntityResult(
          title: title.isEmpty ? null : title,
          repeatOption: repeat,
        );
      case DraftCommandCategory.diary:
        final cleaned = _parser.cleanFreeformContent(text);
        return EntityResult(title: cleaned.isEmpty ? null : cleaned);
    }
  }

  @override
  FieldCorrection? parseCorrection(String text, List<String> availableFields) =>
      _parser.parseFieldCorrection(text, availableFields);
}
