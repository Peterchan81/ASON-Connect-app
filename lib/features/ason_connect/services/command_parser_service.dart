// 문장을 분석하는 서비스의 진입점(Facade)입니다.
// 실제 분석은 아래 네 협력자에게 위임하고, 이 클래스는 그 결과를 DraftCommand
// 흐름에 맞는 형태(항목 key, 질문 문구, 필드 채우기)로 정리해서 돌려줍니다.
//
// - ClassificationScorer : 문장이 어떤 카테고리(일정/메모/건강/프로젝트/할 일)인지 판단
// - ScheduleFieldExtractor : 일정의 날짜/시간/내용 추출 (장소는 KoreanLocationService)
// - HealthFieldExtractor : 건강의 항목/값 추출
// - FieldCorrectionParser : "수정" 대화에서 어떤 항목을 어떤 값으로 바꿀지 해석
//
// 실제 AI(OpenAI, Gemini 등)는 연결하지 않은, 규칙 기반의 분석 로직입니다.

import 'classification_scorer.dart';
import 'content_normalizer.dart';
import 'field_correction_parser.dart';
import 'health_field_extractor.dart';
import 'korean_location_service.dart';
import 'korean_particles.dart';
import 'schedule_field_extractor.dart';
import '../models/draft_command.dart';

export 'classification_scorer.dart' show ClassificationResult;
export 'field_correction_parser.dart' show FieldCorrection;
export 'health_field_extractor.dart' show HealthExtraction;
export 'schedule_field_extractor.dart' show ScheduleExtraction;

class CommandParserService {
  CommandParserService({KoreanLocationService? locationService})
    : _scorer = ClassificationScorer(locationService: locationService),
      _scheduleExtractor = ScheduleFieldExtractor(
        locationService: locationService,
      ),
      _healthExtractor = const HealthFieldExtractor(),
      _correctionParser = const FieldCorrectionParser();

  final ClassificationScorer _scorer;
  final ScheduleFieldExtractor _scheduleExtractor;
  final HealthFieldExtractor _healthExtractor;
  final FieldCorrectionParser _correctionParser;

  // 일정에서 "묶어서 질문"할 항목과 우선순위입니다.
  // 날짜는 시간에 자연스럽게 포함되어 표시되므로 따로 묻지 않고,
  // 장소는 문장에 표현이 있을 때만(불확실하면 되묻는 방식으로) 채워지므로
  // 이 목록에는 넣지 않습니다. (필수: 시간, 내용 / 알림은 한 번만 제안)
  static const List<String> scheduleFieldOrder = ['time', 'title', 'alarm'];

  // 항목별 질문 문구입니다.
  static const Map<String, String> scheduleFieldQuestions = {
    'date': '날짜를 알려주세요.',
    'time': '몇 시 일정인가요?',
    'location': '장소를 알려주세요.',
    'title': '일정 내용은 무엇인가요?',
    'alarm': '알림을 설정하시겠습니까?\n예: 30분 전 알림',
  };

  // 항목 key -> 화면에 보여줄 한글 라벨입니다. (일정/건강 공통)
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

  // 묶음 질문(①②③)에 표시할 때만 쓰는 라벨입니다. 일반 라벨과 다르게 표현할 항목만 넣습니다.
  static const Map<String, String> scheduleBatchLabel = {'alarm': '알림 여부'};

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

  /// draft의 특정 항목에 값을 채운 새로운 draft를 만듭니다.
  DraftCommand assignScheduleField(
    DraftCommand draft,
    String field,
    String value,
  ) {
    switch (field) {
      case 'date':
        return draft.copyWith(date: value);
      case 'time':
        return draft.copyWith(time: value);
      case 'location':
        return draft.copyWith(location: value, clearPendingLocation: true);
      case 'title':
        return draft.copyWith(title: value);
      case 'alarm':
        return draft.copyWith(alarm: value);
    }
    return draft;
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

  /// 일정에서 아직 채워지지 않은 모든 항목입니다. (순서대로)
  /// ASON은 이 목록을 한 번에 묶어서 질문합니다.
  List<String> allMissingScheduleFields(DraftCommand draft) {
    return scheduleFieldOrder.where((field) {
      final value = scheduleFieldValue(draft, field);
      return value == null || value.trim().isEmpty;
    }).toList();
  }

  /// 일정에서 다음으로 물어봐야 하는 항목입니다. 모두 채워졌으면 null입니다.
  String? nextMissingScheduleField(DraftCommand draft) {
    final missing = allMissingScheduleFields(draft);
    return missing.isEmpty ? null : missing.first;
  }

  /// 항목에 대한 질문 문구입니다. 장소가 불확실하면 되묻는 문장으로 대신합니다.
  String questionForScheduleField(String field, DraftCommand draft) {
    if (field == 'location' && draft.pendingLocationGuess != null) {
      final original = draft.pendingLocationOriginal!;
      final guess = draft.pendingLocationGuess!;
      return '$original${KoreanParticles.iRago(original)} 하신 장소가 '
          '$guess${KoreanParticles.iGa(guess)} 맞나요?';
    }
    return scheduleFieldQuestions[field] ?? '내용을 알려주세요.';
  }

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
