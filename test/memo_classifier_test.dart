// MemoClassifier가 메모 문장을 "일반"/"아이디어"로 올바르게 나누는지 검증합니다.

import 'package:ason_voice_app/features/ason_connect/services/memo_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('아이디어를 나타내는 표현이 있으면 "아이디어"다', () {
    expect(MemoClassifier.classify('아이디어 메모, ASON 음성 앱 개선'), '아이디어');
    expect(MemoClassifier.classify('새벽에 좋은 구상이 떠올랐다'), '아이디어');
    expect(MemoClassifier.classify('갑자기 영감이 떠올랐어'), '아이디어');
  });

  test('아이디어 표현이 없으면 "일반"이다', () {
    expect(MemoClassifier.classify('우유하고 계란 사야 해'), '일반');
    expect(MemoClassifier.classify('내일 세탁물 찾아오기'), '일반');
  });
}
