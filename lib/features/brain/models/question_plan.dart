// QuestionPlanner가 "이번 턴에 실제로 무엇을 물어볼지" 계획한 결과입니다.

class QuestionPlan {
  const QuestionPlan({required this.fields, required this.questionText});

  /// 이번 턴에 실제로 묻는 필드 key 목록입니다. (예: ['time', 'title', 'alarm'])
  final List<String> fields;

  /// 화면에 보여줄 질문 문구입니다.
  final String questionText;

  bool get isEmpty => fields.isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuestionPlan) return false;
    if (other.questionText != questionText) return false;
    if (other.fields.length != fields.length) return false;
    for (var i = 0; i < fields.length; i++) {
      if (other.fields[i] != fields[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(fields), questionText);

  @override
  String toString() =>
      'QuestionPlan(fields: $fields, questionText: $questionText)';
}
