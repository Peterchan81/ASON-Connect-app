// 문장을 분석하는 서비스의 진입점(Facade)입니다.
// 실제 분석은 아래 협력자에게 위임하고, 이 클래스는 그 결과를 DraftCommand 흐름에
// 맞는 형태(항목 key, 필드 채우기)로 정리해서 돌려줍니다.
//
// - ClassificationScorer : 문장이 어떤 카테고리(일정/메모/건강/프로젝트/할 일)인지 판단
// - ScheduleFieldExtractor : 일정의 날짜/시간/내용 추출 (장소는 KoreanLocationService)
// - HealthFieldExtractor : 건강의 항목/값 추출
// - FieldCorrectionParser : "수정" 대화에서 어떤 항목을 어떤 값으로 바꿀지 해석
//
// ASON Connect는 입력 폼이 아니므로, 부족한 항목을 순서대로 되묻는 로직(항목
// 우선순위/질문 문구 매핑)은 두지 않습니다. 수정 대화에서 항목 이름을 보여줄 때만
// fieldKeyToLabel을 사용합니다.
//
// 실제 AI(OpenAI, Gemini 등)는 연결하지 않은, 규칙 기반의 분석 로직입니다.

import 'classification_scorer.dart';
import 'content_normalizer.dart';
import 'date_expression_parser.dart';
import 'field_correction_parser.dart';
import 'health_field_extractor.dart';
import 'korean_location_service.dart';
import 'schedule_field_extractor.dart';
import '../models/draft_command.dart';

export 'classification_scorer.dart' show ClassificationResult;
export 'field_correction_parser.dart' show FieldCorrection;
export 'health_field_extractor.dart' show HealthExtraction;
export 'schedule_field_extractor.dart' show ScheduleExtraction;

class CommandParserService {
  CommandParserService({
    KoreanLocationService? locationService,
    DateTime Function()? nowProvider,
  }) : _scorer = ClassificationScorer(
         locationService: locationService,
         dateExpressionParser: DateExpressionParser(nowProvider: nowProvider),
       ),
       _scheduleExtractor = ScheduleFieldExtractor(
         locationService: locationService,
         dateExpressionParser: DateExpressionParser(nowProvider: nowProvider),
       ),
       _healthExtractor = const HealthFieldExtractor(),
       _correctionParser = const FieldCorrectionParser();

  final ClassificationScorer _scorer;
  final ScheduleFieldExtractor _scheduleExtractor;
  final HealthFieldExtractor _healthExtractor;
  final FieldCorrectionParser _correctionParser;

  // 항목 key -> 화면에 보여줄 한글 라벨입니다. (일정/건강 공통, 수정 대화에서 사용)
  static const Map<String, String> fieldKeyToLabel = {
    'date': '날짜',
    'time': '시간',
    'location': '장소',
    'title': '내용',
    'healthItem': '항목',
    'alarm': '알림',
    'repeat': '반복',
    'memo': '메모',
    'memoType': '종류',
    'projectAction': '활동',
    'progress': '진행률',
  };

  /// draft에서 해당 항목의 현재 값을 꺼내줍니다.
  String? scheduleFieldValue(DraftCommand draft, String field) {
    switch (field) {
      case 'date':
        return draft.date;
      case 'time':
        return draft.time;
      case 'location':
        return draft.location;
      case 'title':
        return draft.title;
      case 'alarm':
        return draft.alarm;
      case 'healthItem':
        return draft.healthItem;
      case 'repeat':
        return draft.repeatOption;
      case 'memo':
        return draft.memo;
      case 'memoType':
        return draft.memoType;
      case 'projectAction':
        return draft.projectAction;
      case 'progress':
        return draft.progress;
    }
    return null;
  }

  /// 문장을 읽고 가장 유력한 카테고리(와 다음으로 유력한 카테고리)를 점수와 함께 돌려줍니다.
  ClassificationResult classify(String text) => _scorer.classify(text);

  /// 일정 문장에서 날짜/시간/장소/내용을 최대한 뽑아냅니다.
  ScheduleExtraction extractScheduleFields(String text) =>
      _scheduleExtractor.extract(text);

  /// 건강 문장에서 항목(체중/혈압/혈당/운동)과 값을 하나 뽑아냅니다.
  HealthExtraction extractHealthFields(String text) =>
      _healthExtractor.extract(text);

  /// 메모/프로젝트/할 일처럼 문장 전체가 곧 '내용'이 되는 경우, 가볍게 다듬어 돌려줍니다.
  String cleanFreeformContent(String text) =>
      ContentNormalizer.cleanFreeform(text);

  /// 메모/할 일 문장을 짧고 자연스러운 표현으로 가볍게 다듬습니다.
  String normalizeMemoContent(String text) =>
      ContentNormalizer.normalizeMemo(text);

  /// "시간을 오후 4시로 바꿔줘"처럼, 수정 대화에서 사용자가 말한 내용을 해석합니다.
  FieldCorrection? parseFieldCorrection(
    String text,
    List<String> availableFields,
  ) => _correctionParser.parse(text, availableFields);

  /// draft의 특정 항목(수정 대화 결과 포함)에 값을 채운 새로운 draft를 만듭니다.
  DraftCommand applyFieldCorrection(
    DraftCommand draft,
    FieldCorrection correction,
  ) => _correctionParser.apply(draft, correction);
}
