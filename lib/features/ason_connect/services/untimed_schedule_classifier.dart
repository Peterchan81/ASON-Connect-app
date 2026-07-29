// "병원 가야 해"/"세차 맡기기"처럼 시각(3시 등)이나 상대 날짜 표현이 없어도,
// 한 번 처리하면 끝나는 용무성 행동은 일정으로 봅니다. ClassificationScorer가
// 일정 점수를 계산할 때 이 클래스의 점수를 더해서 씁니다.
//
// 아래 세 가지 경우에는 이미 다른 카테고리가 더 확신할 수 있는 신호이므로
// 점수를 주지 않습니다.
// - 반복 표현("매일"/"매주" 등): 나의 하루 목표가 우선
// - 과거형 감정 표현("좋았다"/"힘들었다" 등): 다이어리가 우선
// - 희망·구상·정보 탐색 표현("~하고 싶다"/"아이디어"/"언젠가"/"알아보기" 등):
//   아직 실행할 "일"이 아니라 메모(또는 아이디어)에 가까움
class UntimedScheduleClassifier {
  const UntimedScheduleClassifier();

  // 반복(나의 하루 목표)이 최우선 신호이므로, 여기서도 반복 표현이 있으면
  // 점수를 주지 않습니다. ClassificationScorer의 반복 패턴과 같은 표현입니다.
  static final RegExp _repeatCuePattern = RegExp(
    r'매일\s*아침|매일\s*저녁|매일\s*밤|매주\s*[가-힣]+요일|'
    r'매일|매주|매달|꾸준히|습관|계속|하루에',
  );

  // 다이어리(과거형 감정)가 있으면 점수를 주지 않습니다. ClassificationScorer의
  // 감정 패턴과 같은 표현입니다.
  static final RegExp _emotionPastPattern = RegExp(
    r'좋았|나빴|힘들었|즐거웠|행복했|슬펐|속상했|피곤했|괜찮았|재밌었|재미있었',
  );

  // 희망·구상·정보 탐색 표현입니다. 이런 표현이 있으면 아직 실행할 "일"이
  // 아니라 메모(또는 아이디어)로 남겨둡니다.
  static final RegExp _hopeOrIdeaPattern = RegExp(
    r'고\s*싶|아이디어|생각|언젠가|알아보기|고민|계획',
  );

  // 문장 어디에 있어도 되는, 목적지에 가거나 서류를 처리하는 대표적인 용무
  // 표현입니다("병원 가야 해", "은행에 서류 제출", "주민센터 방문" 등).
  static final RegExp _errandWordPattern = RegExp(
    r'가야\s*(해|한다|겠|해요|합니다)|방문|제출|예약|신청|확인하러\s*가',
  );

  // 발신·수령·위탁처럼 한 번 처리하면 끝나는 용무 동사로 문장이 끝나는
  // 경우입니다("세차 맡기기", "어머니께 전화하기", "택배 보내기",
  // "자동차 검사받기" 등).
  static final RegExp _errandEndingPattern = RegExp(
    r'(맡기기|찾아오기|구매하기|전화하기|신청하기|제출하기|예약하기|보내기|받기)\s*[.!?]*$',
  );

  // "내일"/"모레"처럼 구체적인 날을 콕 집어 말한 경우입니다. 이 신호만으로는
  // 부족하고, 문장 끝이 한 번 처리하면 끝나는 동사로 마무리될 때만 함께
  // 봅니다("내일 사용할 자료 출력하기" 등).
  static final RegExp _dayReferencePattern = RegExp(r'내일|모레|오늘|이따가');

  // 문장 끝이 "~하기"류의 할 일 동사로 끝나는지만 넓게 봅니다(메모의
  // bareActionTaskPattern과 같은 범위). _dayReferencePattern과 함께일 때만
  // 사용하므로, 반복/희망 신호가 없는 "오늘/내일 하는 일"만 걸러집니다.
  static final RegExp _actionEndingPattern = RegExp(
    r'(하기|보내기|만들기|전달하기|정리하기|확인하기|준비하기|처리하기|두기)\s*[.!?]*$',
  );

  /// 일정 점수에 더할 보너스를 계산합니다. 반복/과거감정/희망 신호가 있으면
  /// 항상 0입니다.
  double scoreBonus(String text) {
    if (_repeatCuePattern.hasMatch(text)) return 0;
    if (_emotionPastPattern.hasMatch(text)) return 0;
    if (_hopeOrIdeaPattern.hasMatch(text)) return 0;

    if (_errandWordPattern.hasMatch(text)) return 3;
    if (_errandEndingPattern.hasMatch(text)) return 3;
    if (_dayReferencePattern.hasMatch(text) &&
        _actionEndingPattern.hasMatch(text)) {
      return 3;
    }
    return 0;
  }
}
