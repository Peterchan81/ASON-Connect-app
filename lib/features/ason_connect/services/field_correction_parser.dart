// "수정" 대화에서 사용자가 어떤 항목을 어떤 값으로 바꾸려는지 해석합니다.
// 날짜·시간·장소·내용·항목·알림·반복·메모 모두 "라벨 + 새 값" 형태의 같은 문장
// 구조로 말해지므로, 필드별로 나누지 않고 하나의 라벨 기반 파서로 처리합니다.
// (알림/반복은 "없어짐/없앰" 의사표현만 추가로 "없음"으로 정규화합니다)

import '../models/draft_command.dart';

/// "시간을 오후 4시로 바꿔줘"처럼, 수정 대화에서 파악한 변경 내용입니다.
class FieldCorrection {
  const FieldCorrection({required this.field, required this.newValue});

  /// 'date' | 'time' | 'location' | 'title' | 'healthItem' | 'alarm' | 'repeat' | 'memo'
  final String field;
  final String newValue;
}

class FieldCorrectionParser {
  const FieldCorrectionParser();

  // 한글 라벨 -> 항목 key입니다.
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

  /// "시간을 오후 4시로 바꿔줘"처럼, 수정 대화에서 사용자가 말한 내용을 해석합니다.
  /// [availableFields]는 지금 카테고리에서 수정할 수 있는 항목 key 목록입니다.
  FieldCorrection? parse(String text, List<String> availableFields) {
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
  DraftCommand apply(DraftCommand draft, FieldCorrection correction) {
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
}
