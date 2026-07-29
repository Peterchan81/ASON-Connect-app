// 문장의 키워드와 형태(시간/장소/수치/구매 표현)를 보고 카테고리(일정/메모/건강/
// 프로젝트/할 일)를 점수로 판단합니다. 실제 필드를 뽑아내는 일(ScheduleFieldExtractor,
// HealthFieldExtractor)과는 분리된, "무엇으로 분류할지"만 담당하는 첫 단계입니다.

import 'korean_location_service.dart';
import '../models/draft_command.dart';

/// classify()의 결과입니다. 가장 유력한 카테고리와 그다음으로 유력한 카테고리,
/// 그리고 각각의 점수를 담고 있어서 "애매한 경우"를 판단할 수 있게 해줍니다.
class ClassificationResult {
  const ClassificationResult({
    required this.best,
    required this.bestScore,
    this.second,
    this.secondScore = 0,
  });

  final DraftCommandCategory best;
  final double bestScore;
  final DraftCommandCategory? second;
  final double secondScore;

  /// 아무 신호도 찾지 못한, ASON 기능과 관계없어 보이는 일반 대화입니다.
  bool get isUnclassified => bestScore < 1;

  /// 1·2위 점수가 비슷하고 둘 다 확신하기엔 낮아서, 사용자에게 되물어야 하는 경우입니다.
  bool get isAmbiguous =>
      !isUnclassified &&
      second != null &&
      bestScore < 3 &&
      (bestScore - secondScore) <= 1;
}

class ClassificationScorer {
  ClassificationScorer({KoreanLocationService? locationService})
    : _locationService = locationService ?? KoreanLocationService();

  final KoreanLocationService _locationService;

  // 분류에 사용하는 키워드입니다. 문장 형태(시간/장소/수치 패턴)와 함께 점수로 반영합니다.
  static const Map<DraftCommandCategory, List<String>> _keywords = {
    DraftCommandCategory.schedule: [
      '일정',
      '약속',
      '미팅',
      '회의',
      '만나',
      '출장',
      '모임',
      '방문',
      '예약',
    ],
    DraftCommandCategory.memo: ['메모', '기억', '적어', '기록', '사야', '구매', '아이디어'],
    DraftCommandCategory.health: [
      '몸무게',
      '체중',
      '혈압',
      '혈당',
      '운동',
      '컨디션',
      '두통',
      '아파',
      '아프',
      '복용',
      '영양제',
      '비타민',
    ],
    DraftCommandCategory.project: ['프로젝트', '개발', '아이디어', '기획', '수정'],
    DraftCommandCategory.todo: ['해야', '할 일', '할일', '준비', '처리'],
    DraftCommandCategory.dailyGoal: [
      '스트레칭',
      '걷기',
      '요가',
      '명상',
      '독서',
      '다이어트',
      '물 마시기',
      '습관',
      '운동',
      '공부',
    ],
    DraftCommandCategory.diary: [
      '기분',
      '일기',
      '오늘 하루',
      '즐거웠',
      '행복했',
      '속상했',
      '힘들었',
    ],
  };

  // 나의 하루 목표의 핵심 신호인 "반복" 표현입니다. (매일/매주 등)
  static final RegExp _repeatCuePattern = RegExp(
    r'매일\s*아침|매일\s*저녁|매일\s*밤|매주\s*[가-힣]+요일|매일|매주|매달',
  );

  // 다이어리의 핵심 신호인, 하루를 돌아보는 과거형 감정 표현입니다.
  static final RegExp _emotionPastPattern = RegExp(
    r'좋았|나빴|힘들었|즐거웠|행복했|슬펐|속상했|피곤했|괜찮았|재밌었|재미있었',
  );

  // "정리해 두기"/"견적서 보내기"처럼, 날짜·시간·반복 없이 한 번만 처리하면
  // 되는 일을 나타내는 문장 끝 표현입니다. 이런 문장은 기본적으로 메모로
  // 봅니다. (반복 표현이 있으면 나의 하루 목표가 우선이므로 제외합니다)
  static final RegExp _bareActionTaskPattern = RegExp(
    r'(하기|보내기|만들기|전달하기|정리하기|확인하기|준비하기|처리하기|두기)\s*[.!?]*$',
  );

  // 일정의 시간 표현과 건강의 운동 표현은 분류 점수 계산과 필드 추출(ScheduleFieldExtractor,
  // HealthFieldExtractor) 양쪽에서 함께 쓰이므로, 이 클래스에서 공개 상수로 관리합니다.
  static final RegExp timePattern = RegExp(
    r'(오전|오후)?\s*\d{1,2}시(\s*\d{1,2}분)?',
  );
  static final RegExp exercisePattern = RegExp(
    r'(\d+\s*(분|시간))\s*(간\s*)?(걸었|걷|운동|뛰었|뛰|탔)',
  );

  // "혈압약 먹었어"/"영양제 먹었다"/"비타민 복용"처럼, 약 이름(또는 영양제/비타민) 뒤에
  // 복용을 나타내는 동사가 붙는 표현입니다. 그룹1이 약 이름(또는 영양제/비타민) 자체입니다.
  static final RegExp medicationPattern = RegExp(
    r'(?:^|\s)(\S*?(?:약|영양제|비타민))\s*(?:을|를)?\s*'
    r'(?:먹었|먹음|먹었어|먹었다|복용했|복용|드셨|드셨어요|드셨습니다)',
  );

  static final RegExp _weightPattern = RegExp(
    r'(몸무게|체중)[^0-9]{0,5}\d+(\.\d+)?\s*(kg|킬로그램|킬로)?',
  );
  static final RegExp _bloodPressurePattern = RegExp(
    r'(\d{2,3})\s*(에|/|-)\s*(\d{2,3})',
  );
  static final RegExp _glucosePattern = RegExp(r'혈당[^0-9]{0,5}\d+');
  static final RegExp _purchasePrepPattern = RegExp(
    r'(사야|구매|준비해|기억해|적어|기록해|해야)',
  );

  /// 문장을 읽고 가장 유력한 카테고리(와 다음으로 유력한 카테고리)를 점수와 함께 돌려줍니다.
  ClassificationResult classify(String text) {
    final scores = <DraftCommandCategory, double>{
      for (final category in DraftCommandCategory.values)
        category: _scoreFor(category, text),
    };

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final best = sorted[0];
    final second = sorted[1];

    return ClassificationResult(
      best: best.key,
      bestScore: best.value,
      second: second.value > 0 ? second.key : null,
      secondScore: second.value,
    );
  }

  double _scoreFor(DraftCommandCategory category, String text) {
    double score = 0;

    var keywordHits = 0;
    for (final keyword in _keywords[category] ?? const <String>[]) {
      if (text.contains(keyword)) keywordHits++;
    }
    score += keywordHits > 2 ? 2 : keywordHits.toDouble();

    switch (category) {
      case DraftCommandCategory.schedule:
        if (timePattern.hasMatch(text)) score += 2;
        if (_locationService.extractLocation(text).isConfident) score += 2;
        break;
      case DraftCommandCategory.health:
        if (_weightPattern.hasMatch(text) ||
            (_bloodPressurePattern.hasMatch(text) && text.contains('혈압')) ||
            _glucosePattern.hasMatch(text) ||
            exercisePattern.hasMatch(text) ||
            medicationPattern.hasMatch(text)) {
          score += 3;
        }
        break;
      case DraftCommandCategory.memo:
        if (_purchasePrepPattern.hasMatch(text)) score += 2;
        if (!_repeatCuePattern.hasMatch(text) &&
            _bareActionTaskPattern.hasMatch(text)) {
          score += 2;
        }
        break;
      case DraftCommandCategory.todo:
        if (_purchasePrepPattern.hasMatch(text)) score += 2;
        break;
      case DraftCommandCategory.project:
        break;
      case DraftCommandCategory.dailyGoal:
        // "매일 아침 운동하기"처럼 반복 표현이 함께 있으면 건강 기록이 아니라
        // 습관/목표로 확신합니다. (반복 표현이 없으면 건강 기록일 수도 있으므로
        // 보너스를 주지 않습니다)
        if (_repeatCuePattern.hasMatch(text)) score += 3;
        break;
      case DraftCommandCategory.diary:
        if (_emotionPastPattern.hasMatch(text)) score += 3;
        break;
    }

    return score;
  }
}
