// 문장을 분석하는 서비스입니다.
// 1) 문장의 형태(시간/장소/수치/행동 표현)를 함께 살펴 카테고리를 판단하고,
// 2) 일정의 경우 날짜/시간/장소/내용을 최대한 추출하고,
// 3) 건강의 경우 항목(체중/혈압/혈당/운동/증상)과 값을 하나 추출하고,
// 4) "수정" 대화에서 사용자가 어떤 항목을 어떤 값으로 바꾸려는지 해석합니다.
//
// 실제 AI(OpenAI, Gemini 등)는 연결하지 않은, 규칙 기반의 분석 로직입니다.

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

/// 일정 문장에서 뽑아낸 값들입니다.
class ScheduleExtraction {
  const ScheduleExtraction({
    this.date,
    this.time,
    this.location,
    this.title,
    this.pendingLocationGuess,
    this.pendingLocationOriginal,
  });

  final String? date;
  final String? time;
  final String? location;
  final String? title;

  /// 장소가 확실하지 않을 때, ASON이 되물을 추정 지역명입니다.
  final String? pendingLocationGuess;

  /// 장소가 확실하지 않을 때, 사용자가 실제로 말한 표현입니다.
  final String? pendingLocationOriginal;
}

/// 건강 문장에서 뽑아낸 항목과 값입니다.
class HealthExtraction {
  const HealthExtraction({this.date, required this.item, required this.value});

  final String? date;
  final String item;
  final String value;
}

/// "시간을 오후 4시로 바꿔줘"처럼, 수정 대화에서 파악한 변경 내용입니다.
class FieldCorrection {
  const FieldCorrection({required this.field, required this.newValue});

  /// 'date' | 'time' | 'location' | 'title' | 'healthItem' | 'alarm' | 'repeat' | 'memo'
  final String field;
  final String newValue;
}

class CommandParserService {
  CommandParserService({KoreanLocationService? locationService})
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
    ],
    DraftCommandCategory.memo: ['메모', '기억', '적어', '기록', '사야', '구매'],
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
    ],
    DraftCommandCategory.project: ['프로젝트', '개발', '아이디어', '기획', '수정'],
    DraftCommandCategory.todo: ['해야', '할 일', '할일', '준비', '처리'],
  };

  static final RegExp _timePattern = RegExp(
    r'(오전|오후)?\s*\d{1,2}시(\s*\d{1,2}분)?',
  );
  static final RegExp _weightPattern = RegExp(
    r'(몸무게|체중)[^0-9]{0,5}\d+(\.\d+)?\s*(kg|킬로그램|킬로)?',
  );
  static final RegExp _bloodPressurePattern = RegExp(
    r'(\d{2,3})\s*(에|/|-)\s*(\d{2,3})',
  );
  static final RegExp _glucosePattern = RegExp(r'혈당[^0-9]{0,5}\d+');
  static final RegExp _exercisePattern = RegExp(
    r'(\d+\s*(분|시간))\s*(간\s*)?(걸었|걷|운동|뛰었|뛰|탔)',
  );
  static final RegExp _purchasePrepPattern = RegExp(
    r'(사야|구매|준비해|기억해|적어|기록해|해야)',
  );

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
  };

  // 묶음 질문(①②③)에 표시할 때만 쓰는 라벨입니다. 일반 라벨과 다르게 표현할 항목만 넣습니다.
  static const Map<String, String> scheduleBatchLabel = {'alarm': '알림 여부'};

  // 한글 라벨 -> 항목 key입니다. (수정 대화에서 사용)
  static const Map<String, String> _labelToFieldKey = {
    '날짜': 'date',
    '시간': 'time',
    '장소': 'location',
    '항목': 'healthItem',
    '내용': 'title',
    '알림': 'alarm',
    '반복': 'repeat',
    '메모': 'memo',
  };

  // "없어/없음/필요없다"처럼, 알림·반복을 끄고 싶다는 의사를 나타내는 표현입니다.
  static final RegExp _negationPattern = RegExp(
    r'^(없어|없음|없다|필요\s*없|괜찮아|괜찮습니다|괜찮아요|아니)',
  );

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
        if (_timePattern.hasMatch(text)) score += 2;
        if (_locationService.extractLocation(text).isConfident) score += 2;
        break;
      case DraftCommandCategory.health:
        if (_weightPattern.hasMatch(text) ||
            (_bloodPressurePattern.hasMatch(text) && text.contains('혈압')) ||
            _glucosePattern.hasMatch(text) ||
            _exercisePattern.hasMatch(text)) {
          score += 3;
        }
        break;
      case DraftCommandCategory.memo:
      case DraftCommandCategory.todo:
        if (_purchasePrepPattern.hasMatch(text)) score += 2;
        break;
      case DraftCommandCategory.project:
        break;
    }

    return score;
  }

  /// 일정 문장에서 날짜/시간/장소/내용을 최대한 뽑아냅니다.
  ScheduleExtraction extractScheduleFields(String text) {
    String remaining = text;
    String? date;
    String? time;

    const dateWords = ['오늘', '내일', '모레', '어제'];
    for (final word in dateWords) {
      if (remaining.contains(word)) {
        date = word;
        remaining = remaining.replaceFirst(word, ' ');
        break;
      }
    }
    if (date == null) {
      final dateMatch = RegExp(r'\d{1,2}월\s*\d{1,2}일').firstMatch(remaining);
      if (dateMatch != null) {
        date = dateMatch.group(0)!;
        remaining = remaining.replaceFirst(dateMatch.group(0)!, ' ');
      }
    }

    final timeMatch = _timePattern.firstMatch(remaining);
    if (timeMatch != null) {
      time = timeMatch.group(0)!.trim();
      remaining = remaining.replaceFirst(timeMatch.group(0)!, ' ');
      // "3시에 둔산동에서"처럼 시간 바로 뒤에 남는 "에" 조사도 함께 정리합니다.
      // ("에서"의 일부까지 지워버리지 않도록 뒤에 "서"가 오면 건드리지 않습니다)
      remaining = remaining.replaceFirst(RegExp(r'^\s*에(?!서)'), ' ');
    }

    final locationResult = _locationService.extractLocation(remaining);
    String? location;
    String? pendingGuess;
    String? pendingOriginal;

    if (locationResult.isConfident) {
      location = locationResult.text;
      remaining = _removeLocationFromRemaining(remaining, location!);
      remaining = remaining.replaceFirst(RegExp(r'^\s*(에서|으로|로)'), ' ');
    } else if (locationResult.isUncertain) {
      pendingGuess = locationResult.uncertainGuess;
      pendingOriginal = locationResult.uncertainOriginal;
    }

    final title = remaining
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^[,.\s]+|[,.\s]+$'), '');

    // "일정 있어"처럼 분류 키워드와 존재 표현만 남은 경우는 실질적인 내용이 아니므로
    // 비어 있는 것으로 보고, 이후 "일정 내용은 무엇인가요?"라고 따로 물어봅니다.
    final isGenericFiller = _genericScheduleFiller.hasMatch(title);

    return ScheduleExtraction(
      date: date,
      time: time,
      location: location,
      title: (title.isEmpty || isGenericFiller) ? null : title,
      pendingLocationGuess: pendingGuess,
      pendingLocationOriginal: pendingOriginal,
    );
  }

  static final RegExp _genericScheduleFiller = RegExp(
    r'^(일정|약속|미팅|회의|모임|출장|방문)?\s*(있어|있다|있음|이야|야)?[.!?]*$',
  );

  String _removeLocationFromRemaining(String remaining, String location) {
    if (remaining.contains(location)) {
      return remaining.replaceFirst(location, ' ');
    }
    // 광역 지역명이 자동으로 붙어 원문과 정확히 일치하지 않으면, 마지막 단어 기준으로 제거합니다.
    final lastPart = location.split(' ').last;
    if (remaining.contains(lastPart)) {
      return remaining.replaceFirst(lastPart, ' ');
    }
    return remaining;
  }

  /// 건강 문장에서 항목(체중/혈압/혈당/운동)과 값을 하나 뽑아냅니다.
  /// 수치를 찾지 못하면 '증상' 항목으로 문장 자체를 정리해서 돌려줍니다.
  HealthExtraction extractHealthFields(String text) {
    String? date;
    const dateWords = ['오늘', '내일', '모레', '어제'];
    for (final word in dateWords) {
      if (text.contains(word)) {
        date = word;
        break;
      }
    }

    final weightMatch = RegExp(
      r'(?:몸무게|체중)[^0-9]{0,5}(\d+(?:\.\d+)?)\s*(?:kg|킬로그램|킬로)?',
    ).firstMatch(text);
    if (weightMatch != null) {
      return HealthExtraction(
        date: date,
        item: '체중',
        value: '${weightMatch.group(1)}kg',
      );
    }

    final bpMatch = RegExp(
      r'혈압[^0-9]{0,5}(\d{2,3})\s*(?:에|/|-)\s*(\d{2,3})',
    ).firstMatch(text);
    if (bpMatch != null) {
      return HealthExtraction(
        date: date,
        item: '혈압',
        value: '${bpMatch.group(1)} / ${bpMatch.group(2)} mmHg',
      );
    }

    final glucoseMatch = RegExp(r'혈당[^0-9]{0,5}(\d+)').firstMatch(text);
    if (glucoseMatch != null) {
      return HealthExtraction(
        date: date,
        item: '혈당',
        value: glucoseMatch.group(1)!,
      );
    }

    final exerciseMatch = _exercisePattern.firstMatch(text);
    if (exerciseMatch != null) {
      return HealthExtraction(
        date: date,
        item: '운동',
        value: text.substring(exerciseMatch.start, exerciseMatch.end).trim(),
      );
    }

    // 수치가 없는 컨디션/증상 표현은 '증상'으로 정리합니다. 의료 진단은 하지 않습니다.
    return HealthExtraction(
      date: date,
      item: '증상',
      value: cleanFreeformContent(text),
    );
  }

  /// 메모/프로젝트/할 일처럼 문장 전체가 곧 '내용'이 되는 경우, 가볍게 다듬어 돌려줍니다.
  /// 과도하게 문장을 재구성하지 않고, 앞뒤 공백과 문장 부호 정도만 정리합니다.
  String cleanFreeformContent(String text) {
    return text.trim().replaceAll(RegExp(r'[.!?]+$'), '');
  }

  /// 메모/할 일 문장을 짧고 자연스러운 표현으로 가볍게 다듬습니다.
  /// 예: "우유하고 계란 사야 해" -> "우유와 계란 구매"
  String normalizeMemoContent(String text) {
    var result = cleanFreeformContent(text);
    result = result.replaceAll('하고', '와');
    result = result.replaceAll(RegExp(r'사야\s*(해|겠다|함|해요|됨)?'), '구매');
    return result.trim();
  }

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
      return '$original${_iRago(original)} 하신 장소가 $guess${_iGa(guess)} 맞나요?';
    }
    return scheduleFieldQuestions[field] ?? '내용을 알려주세요.';
  }

  /// "시간을 오후 4시로 바꿔줘"처럼, 수정 대화에서 사용자가 말한 내용을 해석합니다.
  /// [availableFields]는 지금 카테고리에서 수정할 수 있는 항목 key 목록입니다.
  FieldCorrection? parseFieldCorrection(
    String text,
    List<String> availableFields,
  ) {
    const labelOrder = ['날짜', '시간', '장소', '항목', '내용', '알림', '메모', '반복'];

    for (final label in labelOrder) {
      final field = _labelToFieldKey[label];
      if (field == null || !availableFields.contains(field)) continue;
      if (!text.contains(label)) continue;

      final afterLabel = text.substring(text.indexOf(label) + label.length);
      var value = afterLabel.replaceFirst(RegExp(r'^(을|를|은|는|에)?\s*'), '');
      value = value
          .replaceAll(
            RegExp(
              r'(으로|로)?\s*(바꿔줘|바꿔주세요|바꿔|변경해줘|변경해주세요|변경|수정해줘|수정해주세요|수정)[.!?]*$',
            ),
            '',
          )
          .trim();

      if (value.isNotEmpty) {
        return FieldCorrection(field: field, newValue: value);
      }
    }
    return null;
  }

  /// draft의 특정 항목(수정 대화 결과 포함)에 값을 채운 새로운 draft를 만듭니다.
  DraftCommand applyFieldCorrection(
    DraftCommand draft,
    FieldCorrection correction,
  ) {
    switch (correction.field) {
      case 'date':
        return draft.copyWith(date: correction.newValue);
      case 'time':
        return draft.copyWith(time: correction.newValue);
      case 'location':
        return draft.copyWith(
          location: correction.newValue,
          clearPendingLocation: true,
        );
      case 'title':
        return draft.copyWith(title: correction.newValue);
      case 'healthItem':
        return draft.copyWith(healthItem: correction.newValue);
      case 'alarm':
        return draft.copyWith(alarm: _normalizeIfNegated(correction.newValue));
      case 'repeat':
        return draft.copyWith(
          repeatOption: _normalizeIfNegated(correction.newValue),
        );
      case 'memo':
        return draft.copyWith(memo: correction.newValue);
    }
    return draft;
  }

  /// "없어/괜찮아"처럼 끄고 싶다는 의사표현이면 "없음"으로, 아니면 원래 값 그대로 돌려줍니다.
  String _normalizeIfNegated(String value) {
    return _negationPattern.hasMatch(value) ? '없음' : value;
  }

  // 한글 조사(이/가, 이라고/라고)를 받침 유무에 맞게 골라줍니다.
  bool _hasBatchim(String word) {
    if (word.isEmpty) return false;
    final code = word.codeUnitAt(word.length - 1);
    if (code < 0xAC00 || code > 0xD7A3) return false;
    return (code - 0xAC00) % 28 != 0;
  }

  String _iGa(String word) => _hasBatchim(word) ? '이' : '가';

  String _iRago(String word) => _hasBatchim(word) ? '이라고' : '라고';
}
