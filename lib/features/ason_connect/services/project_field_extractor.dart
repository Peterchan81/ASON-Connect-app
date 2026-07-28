// 프로젝트 문장에서 "무엇을 하려는 것인지(생성/수정/삭제)"와 진행률을 뽑아냅니다.
// 실제 프로젝트 목록은 이 앱이 아니라 ASON Core가 Single Source of Truth로
// 가지고 있으므로, 여기서는 "이번 요청이 어떤 활동인지"만 정리해서 함께 보냅니다.

class ProjectFieldExtractor {
  const ProjectFieldExtractor._();

  static final RegExp _deletePattern = RegExp(r'(삭제|제거|지워|없애)');
  static final RegExp _updatePattern = RegExp(r'(수정|변경|업데이트|바꿔|바꿨)');
  static final RegExp _progressPattern = RegExp(r'(\d{1,3})\s*(?:%|퍼센트|프로)');

  // "새 프로젝트 시작: 다크모드 지원"처럼, 문장 맨 앞에 붙는 안내성 표현입니다.
  // 실제 프로젝트 이름/내용만 남기고 정리합니다.
  static final RegExp _leadingPrefixPattern = RegExp(
    r'^(새\s*)?프로젝트\s*(생성|시작|만들기|추가)?\s*[:,]?\s*',
  );

  /// 문장 맨 앞의 "새 프로젝트 시작:" 같은 안내성 표현을 정리합니다.
  static String cleanTitle(String text) {
    final cleaned = text.replaceFirst(_leadingPrefixPattern, '').trim();
    return cleaned.isEmpty ? text.trim() : cleaned;
  }

  /// 이번 문장이 프로젝트 생성/수정/삭제 중 무엇에 관한 것인지 판단합니다.
  /// 삭제/수정 표현이 없으면 기본값은 "생성"입니다.
  static String detectAction(String text) {
    if (_deletePattern.hasMatch(text)) return '삭제';
    if (_updatePattern.hasMatch(text) || _progressPattern.hasMatch(text)) {
      return '수정';
    }
    return '생성';
  }

  /// 문장에 포함된 진행률(예: "60%", "60퍼센트")을 "60%" 형태로 뽑아냅니다.
  /// 없으면 null입니다.
  static String? extractProgress(String text) {
    final match = _progressPattern.firstMatch(text);
    if (match == null) return null;
    return '${match.group(1)}%';
  }
}
